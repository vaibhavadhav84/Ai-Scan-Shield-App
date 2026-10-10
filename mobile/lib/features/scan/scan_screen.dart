import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../core/api.dart';
import '../../core/providers.dart';
import '../../shared/widgets.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key, this.initialChannel = 'sms'});
  final String initialChannel;
  @override
  ConsumerState<ScanScreen> createState() => _ScanState();
}

class _ScanState extends ConsumerState<ScanScreen> with WidgetsBindingObserver {
  static const channels = ['sms', 'email', 'url', 'voice', 'call'];
  late String channel = channels.contains(widget.initialChannel)
      ? widget.initialChannel
      : 'sms';
  final drafts = {for (final name in channels) name: TextEditingController()};
  TextEditingController get content => drafts[channel]!;
  final sender = TextEditingController();
  final reply = TextEditingController();
  final subject = TextEditingController();
  final phone = TextEditingController();
  final recorder = AudioRecorder();
  final player = AudioPlayer();
  bool busy = false, recording = false, recordingBusy = false;
  bool uploading = false;
  String? audioPath, error;
  double progress = 0;
  Timer? timer;
  final elapsed = Stopwatch();
  bool useReputation = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(apiProvider).changed.addListener(_receiveShare);
    _receiveShare();
  }

  @override
  void didUpdateWidget(covariant ScanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialChannel != widget.initialChannel &&
        channels.contains(widget.initialChannel) &&
        !busy && !recording && !recordingBusy) {
      channel = widget.initialChannel;
      error = null;
    }
  }

  void _receiveShare() {
    if (busy || recording || recordingBusy) return;
    final value = ref.read(apiProvider).consumeSharedText();
    if (value != null && mounted) {
      setState(() {
        channel = 'sms';
        content.text = value;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (recording && state != AppLifecycleState.resumed) toggleRecord();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(apiProvider).changed.removeListener(_receiveShare);
    timer?.cancel();
    recorder.dispose();
    player.dispose();
    final localPath = audioPath;
    if (localPath != null) {
      File(localPath).delete().catchError((_) => File(localPath));
    }
    for (final controller in [...drafts.values, sender, reply, subject, phone]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> submit({bool audio = false, bool emailFile = false}) async {
    if (busy || recording || recordingBusy) return;
    final api = ref.read(apiProvider);
    setState(() {
      busy = true;
      error = null;
      progress = 0;
      uploading = false;
    });
    try {
      Json result;
      if (audio || emailFile) {
        final agreed = await confirm(
          context,
          'Submit ${audio ? 'audio' : 'email'}?',
          'This file will be uploaded to your configured backend. '
              'Audio is transcribed there and deleted after processing. '
              'Email attachments are inspected by filename only.',
        );
        if (!agreed) return;
        MultipartFile file;
        if (audio && audioPath != null) {
          if (await File(audioPath!).length() > 10 * 1024 * 1024) {
            throw StateError('File too large');
          }
          file = await MultipartFile.fromFile(
            audioPath!,
            filename: 'recording.wav',
          );
        } else {
          final picked = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: [audio ? 'wav' : 'eml'],
            withData: kIsWeb,
          );
          if (picked == null) return;
          final selected = picked.files.single;
          final max = audio ? 10 * 1024 * 1024 : 512 * 1024;
          if (selected.size > max) {
            throw StateError('File too large');
          }
          file = selected.path != null && !kIsWeb
              ? await MultipartFile.fromFile(
                  selected.path!,
                  filename: selected.name,
                )
              : MultipartFile.fromBytes(
                  selected.bytes!,
                  filename: selected.name,
                );
        }
        if (mounted) setState(() => uploading = true);
        result = Map<String, dynamic>.from(
          await api.request(
            'POST',
            audio ? '/scans/voice' : '/scans/email-file',
            data: FormData.fromMap({'file': file}),
            onProgress: (sent, total) {
              if (mounted && total > 0) setState(() => progress = sent / total);
            },
          ),
        );
      } else {
        if (content.text.trim().isEmpty || content.text.length > 20000) {
          setState(() => error = 'Enter content of 1â€“20,000 characters.');
          return;
        }
        if (channel == 'url') {
          final uri = Uri.tryParse(content.text.trim());
          if (uri == null ||
              !['https', 'http'].contains(uri.scheme) ||
              uri.host.isEmpty) {
            setState(() => error = 'Enter a complete http:// or https:// URL.');
            return;
          }
        }
        result = await api.scan({
          'channel': channel,
          'content': content.text,
          'allow_external_reputation': channel == 'url' && useReputation,
          if (channel == 'email') ...{
            'subject': subject.text,
            if (sender.text.trim().isNotEmpty) 'sender': sender.text.trim(),
            if (reply.text.trim().isNotEmpty) 'reply_to': reply.text.trim(),
          },
          if (channel == 'call') 'phone_number': phone.text,
        });
      }
      if (mounted) context.push('/result/${result['id']}', extra: result);
    } catch (e) {
      if (mounted) setState(() => error = errorMessage(e));
    } finally {
      if (mounted) {
        setState(() => busy = false);
        _receiveShare();
      }
    }
  }

  Future<void> toggleRecord() async {
    if (busy || recordingBusy) return;
    setState(() {
      recordingBusy = true;
      error = null;
    });
    try {
      if (recording) {
        timer?.cancel();
        elapsed.stop();
        final result = await recorder.stop();
        if (mounted) {
          setState(() {
            recording = false;
            audioPath = result;
          });
        }
      } else {
        await player.stop();
        final agreed = await confirm(
          context,
          'Use your microphone?',
          'Record only with consent. Recording stays on this device until you submit it. '
              'It stops after three minutes. This does not record phone calls.',
        );
        if (!agreed) return;
        if (!await recorder.hasPermission()) {
          if (mounted) {
            setState(
              () => error =
                  'Microphone permission denied. Paste a transcript or update device settings.',
            );
          }
          return;
        }
        final folder = await getTemporaryDirectory();
        final old = audioPath;
        if (old != null && await File(old).exists()) await File(old).delete();
        final file =
            '${folder.path}/scan-shield-${DateTime.now().millisecondsSinceEpoch}.wav';
        await recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: file,
        );
        elapsed.reset();
        elapsed.start();
        if (mounted) {
          setState(() {
            recording = true;
            audioPath = file;
          });
        }
        timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          if (elapsed.elapsed >= const Duration(minutes: 3)) {
            toggleRecord();
          } else {
            setState(() {});
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = errorMessage(e));
    } finally {
      if (mounted) setState(() => recordingBusy = false);
    }
  }

  bool get controlsLocked => busy || recording || recordingBusy;

  Future<void> paste() async {
    final target = content;
    try {
      final value = await Clipboard.getData(Clipboard.kTextPlain);
      if (!mounted || controlsLocked || value?.text == null) return;
      setState(() {
        target.text = value!.text!;
        error = null;
      });
    } catch (e) {
      if (mounted) setState(() => error = errorMessage(e));
    }
  }

  Future<void> deleteRecording() async {
    if (controlsLocked || audioPath == null) return;
    setState(() => recordingBusy = true);
    try {
      await player.stop();
      final file = File(audioPath!);
      if (await file.exists()) await file.delete();
      if (mounted) {
        setState(() {
          audioPath = null;
          elapsed.reset();
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = errorMessage(e));
    } finally {
      if (mounted) setState(() => recordingBusy = false);
    }
  }

  String get recordingTime {
    final seconds = elapsed.elapsed.inSeconds;
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  Widget emailMetadata() => SurfaceCard(
    padding: EdgeInsets.zero,
    child: ExpansionTile(
      leading: const Icon(Icons.alternate_email),
      title: const Text('Email details'),
      subtitle: const Text('Optional sender, reply-to and subject'),
      childrenPadding: const EdgeInsets.all(ShieldSpace.lg),
      children: [
        TextField(
          enabled: !controlsLocked,
          controller: sender,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Sender address (optional)'),
        ),
        const SizedBox(height: ShieldSpace.lg),
        TextField(
          enabled: !controlsLocked,
          controller: reply,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Reply-to address (optional)'),
        ),
        const SizedBox(height: ShieldSpace.lg),
        TextField(
          enabled: !controlsLocked,
          controller: subject,
          maxLength: 300,
          decoration: const InputDecoration(labelText: 'Subject (optional)'),
        ),
      ],
    ),
  );

  Widget voiceControls() => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading('Voice recording'),
        const SizedBox(height: ShieldSpace.md),
        Text(
          recording ? 'Recording · $recordingTime / 03:00' :
          audioPath != null ? 'Recording ready · $recordingTime' :
          'Record with consent or choose a WAV file.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: ShieldSpace.lg),
        AdaptiveActions(children: [
          OutlinedButton.icon(
            onPressed: busy || recordingBusy ? null : toggleRecord,
            icon: Icon(recording ? Icons.stop_circle_outlined : Icons.mic_none),
            label: Text(recording ? 'Stop recording' : audioPath != null ? 'Record again' : 'Record with consent'),
          ),
          if (audioPath != null && !recording) ...[
            OutlinedButton.icon(
              onPressed: controlsLocked ? null : () async {
                try {
                  await player.play(DeviceFileSource(audioPath!));
                } catch (e) {
                  if (mounted) setState(() => error = errorMessage(e));
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play'),
            ),
            TextButton(
              onPressed: controlsLocked ? null : () async {
                try {
                  await player.stop();
                } catch (e) {
                  if (mounted) setState(() => error = errorMessage(e));
                }
              },
              child: const Text('Stop playback'),
            ),
            TextButton.icon(
              onPressed: controlsLocked ? null : deleteRecording,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete recording'),
            ),
          ],
        ]),
        const SizedBox(height: ShieldSpace.md),
        FilledButton.tonalIcon(
          onPressed: controlsLocked ? null : () => submit(audio: true),
          icon: const Icon(Icons.file_upload_outlined),
          label: Text(audioPath == null ? 'Choose & scan WAV' : 'Submit recording'),
        ),
        const SizedBox(height: ShieldSpace.lg),
        const Text('PCM WAV · up to 10 MB · up to 3 minutes. A configured speech model on your backend is required. Audio is uploaded only when you submit it.'),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => PageBody(
    storageKey: 'scan-page',
    children: [
      const PageHeading(
        eyebrow: 'NEW SCAN',
        title: 'Check before you act',
        subtitle: 'Choose what you received. We’ll explain the signals to help you decide what to do next.',
      ),
      Wrap(
        spacing: ShieldSpace.sm,
        runSpacing: ShieldSpace.sm,
        children: [
          for (final name in channels)
            ChoiceChip(
              avatar: Icon(channelIcon(name), size: 18),
              label: Text(channelLabel(name)),
              selected: channel == name,
              onSelected: controlsLocked ? null : (_) => setState(() {
                channel = name;
                error = null;
              }),
            ),
        ],
      ),
      if (channel == 'voice') voiceControls(),
      if (channel == 'call') ...[
        const Notice('Only your description is analyzed. Caller identity and phone reputation are not verified.', icon: Icons.phone_outlined),
        TextField(
          enabled: !controlsLocked,
          controller: phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone number (optional)', helperText: 'Context only; this does not verify the caller.'),
        ),
      ],
      SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeading(switch (channel) {
              'email' => 'Email message',
              'url' => 'Website link',
              'voice' => 'Or analyze a transcript',
              'call' => 'What did the caller say?',
              _ => 'Text message',
            }),
            const SizedBox(height: ShieldSpace.sm),
            AdaptiveActions(children: [
              TextButton.icon(onPressed: controlsLocked ? null : paste, icon: const Icon(Icons.content_paste), label: const Text('Paste')),
              TextButton.icon(onPressed: controlsLocked ? null : () => setState(() { content.clear(); error = null; }), icon: const Icon(Icons.clear), label: const Text('Clear')),
            ]),
            const SizedBox(height: ShieldSpace.sm),
            TextField(
              key: ValueKey('scan-input-$channel'),
              enabled: !controlsLocked,
              controller: content,
              minLines: channel == 'url' ? 2 : 5,
              maxLines: channel == 'url' ? 4 : 10,
              maxLength: channel == 'url' ? 4096 : 20000,
              keyboardType: channel == 'url' ? TextInputType.url : TextInputType.multiline,
              autocorrect: false,
              decoration: InputDecoration(
                alignLabelWithHint: true,
                labelText: switch (channel) {
                  'url' => 'Complete URL',
                  'email' => 'Email body',
                  'voice' => 'Transcript',
                  'call' => 'Call description / transcript',
                  _ => 'Message content',
                },
                hintText: switch (channel) {
                  'url' => 'https://example.com/path',
                  'voice' => 'Paste the words you want checked…',
                  'call' => 'Describe the request and any pressure or threats…',
                  _ => 'Paste or type the message you want checked…',
                },
              ),
            ),
            if (channel == 'url') ValueListenableBuilder<TextEditingValue>(
              valueListenable: content,
              builder: (context, value, _) {
                final uri = Uri.tryParse(value.text.trim());
                final host = uri != null && ['https', 'http'].contains(uri.scheme) && uri.host.isNotEmpty ? uri.host : null;
                if (host == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: ShieldSpace.sm),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Domain to check', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: ShieldSpace.xs),
                    SelectableText(host),
                    const SizedBox(height: ShieldSpace.xs),
                    const Text('Preview only. This link has not been opened.'),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
      if (channel == 'email') ...[
        emailMetadata(),
        OutlinedButton.icon(
          onPressed: controlsLocked ? null : () => submit(emailFile: true),
          icon: const Icon(Icons.upload_file_outlined),
          label: const Text('Import plain-text .eml instead'),
        ),
        const Text('Email files: up to 512 KB. Attachments are inspected by filename only; they are never opened.'),
      ],
      if (channel == 'url') ...[
        SurfaceCard(
          padding: EdgeInsets.zero,
          child: CheckboxListTile(
            contentPadding: const EdgeInsets.all(ShieldSpace.lg),
            value: useReputation,
            onChanged: controlsLocked ? null : (v) => setState(() => useReputation = v!),
            title: const Text('Include external reputation check'),
            subtitle: const Text('Optional. If configured, send this URL to Google Safe Browsing. Its results can miss threats or flag safe links.'),
          ),
        ),
        const Notice('Links are parsed without visiting them. HTTPS alone does not guarantee safety. Local URL checks work without external lookup consent.', icon: Icons.link),
      ],
      if (error != null) Notice('$error\nYour input is still here. Review it and try again.', kind: NoticeKind.error, icon: Icons.error_outline),
      if (busy) ProcessingPanel(uploadProgress: uploading && progress < 1 ? progress : null),
      BusyButton(
        label: switch (channel) {
          'voice' => 'Analyze transcript',
          'url' => 'Check link',
          'call' => 'Analyze call details',
          _ => 'Analyze message',
        },
        busy: busy,
        onPressed: controlsLocked ? null : () => submit(),
        icon: Icons.shield_outlined,
      ),
      const Notice('Raw content is processed by your backend and is not saved in history. Results can be wrong. Verify sensitive requests independently.', icon: Icons.privacy_tip_outlined),
    ],
  );
}
