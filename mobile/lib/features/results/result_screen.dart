import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api.dart';
import '../../core/providers.dart';
import '../../shared/widgets.dart';

Future<void> shareJson(Json data) async {
  final bytes = Uint8List.fromList(
    utf8.encode(const JsonEncoder.withIndent('  ').convert(data)),
  );
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          bytes,
          mimeType: 'application/json',
          name: 'scan-shield-export.json',
        ),
      ],
      fileNameOverrides: ['scan-shield-export.json'],
    ),
  );
}

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key, required this.id, this.result});
  final String id;
  final Json? result;
  @override
  ConsumerState<ResultScreen> createState() => _ResultState();
}

class _ResultState extends ConsumerState<ResultScreen> {
  bool deleting = false,
      exporting = false,
      dialogOpen = false,
      reported = false;

  @override
  Widget build(BuildContext context) {
    final api = ref.read(apiProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Scan result')),
      body: ApiPanel(
        key: ValueKey(widget.id),
        load: () async => widget.result ?? await api.get('/scans/${widget.id}'),
        builder: (scan) {
          final recommendations = List<String>.from(
            scan['recommendations'] as List,
          );
          final indicators = scan['indicators'] as List;
          final reputation = Map<String, dynamic>.from(
            scan['reputation'] as Map,
          );
          return PageBody(
            children: [
              PageHeading(
                title: '${channelLabel(scan['channel'])} analysis',
                eyebrow: 'SCAN RESULT',
                subtitle: timestamp(scan['created_at']),
              ),
              RiskScore(
                score: (scan['score'] as num).toInt(),
                level: scan['risk_level'],
                summary: scan['summary'],
              ),
              if (recommendations.isNotEmpty) ...[
                const SectionHeading('Your next step'),
                Notice(recommendations.first, icon: Icons.shield_outlined),
              ],
              SectionHeading(
                'Why this result?',
                subtitle: '${indicators.length} indicators identified',
              ),
              if (indicators.isEmpty)
                const Notice(
                  'No substantial indicators found. An unfamiliar scam can still be missed.',
                ),
              for (final item in indicators)
                EvidenceTile(Map<String, dynamic>.from(item as Map)),
              Text(
                scan['score_explanation'],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (recommendations.length > 1) ...[
                const SectionHeading('Other precautions'),
                for (final action in recommendations.skip(1))
                  Notice(action, icon: Icons.check_circle_outline),
              ],
              const SectionHeading('What was checked'),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contextual rules',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text('Rules: ${scan['rule_version']}'),
                    const SizedBox(height: 12),
                    Text(
                      'Model signal',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      scan['model_signal'] != null
                          ? 'Included · ${scan['model_version']}'
                          : scan['model_version'] == null
                          ? 'Unavailable · rule baseline only'
                          : 'Not used for this scan',
                    ),
                    if (scan['channel'] == 'url') ...[
                      const SizedBox(height: 12),
                      Text(
                        'External reputation',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(_providerDescription(reputation)),
                    ],
                  ],
                ),
              ),
              if (reputation['listed'] == true) ...[
                const Notice(
                  'The provider reported a possible threat at scan time. This historical result does not establish the current status of the website.',
                  kind: NoticeKind.warning,
                ),
                TextButton.icon(
                  onPressed: () => _openAdvisory(context),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Advisory provided by Google'),
                ),
              ],
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: ExpansionTile(
                  title: const Text('Analysis limitations'),
                  subtitle: const Text(
                    'Understand the boundaries of this result',
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final limit in scan['limitations'])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(limit),
                      ),
                  ],
                ),
              ),
              if (scan['transcript'] != null)
                SurfaceCard(
                  padding: EdgeInsets.zero,
                  child: ExpansionTile(
                    title: const Text('Review transcript'),
                    subtitle: const Text('Available in this session only'),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SelectableText(scan['transcript']),
                      const SizedBox(height: 12),
                      const Text(
                        'This transcript is excluded from saved history and result exports.',
                      ),
                    ],
                  ),
                ),
              const SectionHeading('Help improve detection'),
              AdaptiveActions(
                children: [
                  OutlinedButton.icon(
                    onPressed: dialogOpen || deleting
                        ? null
                        : () => _submitDialog(api, report: false),
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('Give feedback'),
                  ),
                  OutlinedButton.icon(
                    onPressed: dialogOpen || deleting || reported
                        ? null
                        : () => _submitDialog(api, report: true),
                    icon: const Icon(Icons.flag_outlined),
                    label: Text(
                      reported ? 'Report submitted' : 'Report this scan',
                    ),
                  ),
                ],
              ),
              const Text(
                'Reports are for internal review. They do not contact a government or cybercrime agency.',
              ),
              const SectionHeading('Manage this result'),
              AdaptiveActions(
                children: [
                  BusyButton(
                    label: 'Export result',
                    icon: Icons.ios_share,
                    busy: exporting,
                    onPressed: deleting
                        ? null
                        : () async {
                            if (exporting) return;
                            setState(() => exporting = true);
                            try {
                              await shareJson({...scan}..remove('transcript'));
                            } catch (e) {
                              if (context.mounted) {
                                showMessage(context, errorMessage(e));
                              }
                            } finally {
                              if (mounted) setState(() => exporting = false);
                            }
                          },
                  ),
                  TextButton.icon(
                    onPressed: deleting || exporting || dialogOpen
                        ? null
                        : () => _delete(api),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(deleting ? 'Deleting…' : 'Delete scan'),
                  ),
                ],
              ),
              ExpansionTile(
                title: const Text('Scan reference'),
                childrenPadding: const EdgeInsets.all(16),
                children: [SelectableText('Scan ID: ${scan['id']}')],
              ),
            ],
          );
        },
      ),
    );
  }

  String _providerDescription(Json provider) => switch (provider['status']) {
    'available' =>
      provider['listed'] == true
          ? 'Completed · possible threat match'
          : 'Completed · no known-threat match; safety is not guaranteed',
    'not_consented' => 'Not checked · permission was not given',
    'unconfigured' => 'Unavailable · provider is not configured',
    'unavailable' => 'Unavailable · provider did not complete this check',
    'internal_destination_skipped' =>
      'Not checked · internal or private destination',
    _ => 'Not checked · reputation was not requested',
  };

  Future<void> _openAdvisory(BuildContext context) async {
    if (!await confirm(
      context,
      'Open Google advisory?',
      'This opens a fixed Google Safe Browsing information page in your browser. The scanned URL will not be opened or sent.',
      confirmLabel: 'Open advisory',
    )) {
      return;
    }
    try {
      final opened = await launchUrl(
        Uri.parse('https://developers.google.com/safe-browsing/v4/advisory'),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        showMessage(context, 'The advisory could not be opened.');
      }
    } catch (_) {
      if (context.mounted) {
        showMessage(context, 'The advisory could not be opened.');
      }
    }
  }

  Future<void> _delete(Api api) async {
    if (deleting) return;
    setState(() => deleting = true);
    try {
      if (!await confirm(
        context,
        'Delete scan?',
        'This also removes linked alerts, feedback and reports. This cannot be undone.',
        confirmLabel: 'Delete scan',
        destructive: true,
      )) {
        return;
      }
      await api.deleteScan(widget.id);
      if (mounted) context.go('/history');
    } catch (e) {
      if (mounted) showMessage(context, errorMessage(e));
    } finally {
      if (mounted) setState(() => deleting = false);
    }
  }

  Future<void> _submitDialog(Api api, {required bool report}) async {
    if (dialogOpen || (report && reported)) return;
    setState(() => dialogOpen = true);
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _ReviewDialog(api: api, scanId: widget.id, report: report),
    );
    if (!mounted) return;
    setState(() {
      dialogOpen = false;
      if (report && saved == true) reported = true;
    });
    if (saved == true) {
      showMessage(
        context,
        report
            ? 'Report submitted for internal review.'
            : 'Feedback saved. Thank you.',
      );
    }
  }
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({
    required this.api,
    required this.scanId,
    required this.report,
  });
  final Api api;
  final String scanId;
  final bool report;
  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final comment = TextEditingController();
  late String choice = widget.report ? 'other' : 'uncertain';
  bool busy = false;
  String? error;
  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final choices = widget.report
        ? {
            'credentials': 'Credential theft',
            'payment': 'Payment request',
            'impersonation': 'Impersonation',
            'investment': 'Investment offer',
            'other': 'Other concern',
          }
        : {
            'correct': 'Correct detection',
            'false_positive': 'Flagged something safe',
            'missed_scam': 'Missed a scam',
            'uncertain': 'I am not sure',
          };
    return PopScope(
      canPop: !busy,
      child: AlertDialog(
        title: Text(
          widget.report ? 'Report this scan' : 'How accurate was this result?',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.report
                    ? 'This submits a report for internal review only.'
                    : 'Your feedback helps reviewers understand this result.',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: choice,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: widget.report
                      ? 'Reason for reporting'
                      : 'Your assessment',
                ),
                items: choices.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: busy
                    ? null
                    : (value) => setState(() => choice = value!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: comment,
                enabled: !busy,
                maxLength: 1000,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const Text(
                'Comments are stored for review. Do not include passwords or private financial details.',
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Notice(error!, kind: NoticeKind.error),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          BusyButton(
            label: widget.report ? 'Submit report' : 'Save feedback',
            busy: busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.api.request(
        widget.report ? 'POST' : 'PUT',
        widget.report ? '/reports' : '/scans/${widget.scanId}/feedback',
        data: widget.report
            ? {
                'scan_id': widget.scanId,
                'category': choice,
                'comment': comment.text,
              }
            : {'verdict': choice, 'comment': comment.text},
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = errorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
