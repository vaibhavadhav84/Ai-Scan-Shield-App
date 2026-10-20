import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/api.dart';
import 'design.dart';
export 'design.dart';

Color riskColor(String level) =>
    RiskTone.forLevel(level, Brightness.light).foreground;
String timestamp(dynamic seconds) => DateTime.fromMillisecondsSinceEpoch(
  ((seconds as num) * 1000).round(),
).toLocal().toString().substring(0, 16);

class Brand extends StatelessWidget {
  const Brand({super.key, this.large = false});
  final bool large;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Scan Shield',
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset('assets/branding/icon.svg', width: large ? 48 : 30),
        const SizedBox(width: ShieldSpace.md),
        Flexible(
          child: Text(
            'Scan Shield',
            style:
                (large
                        ? Theme.of(context).textTheme.headlineMedium
                        : Theme.of(context).textTheme.titleLarge)
                    ?.copyWith(letterSpacing: -.7),
          ),
        ),
      ],
    ),
  );
}

class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.children,
    this.controller,
    this.storageKey,
    this.maxWidth,
  });
  final List<Widget> children;
  final ScrollController? controller;
  final String? storageKey;
  final double? maxWidth;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        key: storageKey == null ? null : PageStorageKey(storageKey),
        controller: controller,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          constraints.maxWidth < 360 ? 16 : 20,
          8,
          constraints.maxWidth < 360 ? 16 : 20,
          32,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth ?? 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    const SizedBox(height: ShieldSpace.xl),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.trailing,
  });
  final String title;
  final String? subtitle, eyebrow;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (eyebrow != null) ...[
        Text(
          eyebrow!.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.5,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
      ],
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 8),
        Text(
          subtitle!,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ],
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.action, this.subtitle});
  final String title;
  final Widget? action;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          ?action,
        ],
      ),
      if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle!)],
    ],
  );
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.padding, this.color});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  @override
  Widget build(BuildContext context) => Card(
    color: color,
    child: Padding(
      padding: padding ?? const EdgeInsets.all(ShieldSpace.xl),
      child: child,
    ),
  );
}

enum NoticeKind { info, warning, error, success }

class Notice extends StatelessWidget {
  const Notice(
    this.text, {
    super.key,
    this.icon = Icons.info_outline,
    this.kind = NoticeKind.info,
  });
  final String text;
  final IconData icon;
  final NoticeKind kind;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tone = RiskTone.of(context, switch (kind) {
      NoticeKind.error => 'High Risk',
      NoticeKind.warning => 'Suspicious',
      _ => 'Safe',
    });
    final fg = kind == NoticeKind.info
        ? colors.onPrimaryContainer
        : tone.foreground;
    return Semantics(
      liveRegion: kind == NoticeKind.error || kind == NoticeKind.success,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kind == NoticeKind.info
              ? colors.primaryContainer
              : tone.container,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 21, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title, body;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(body),
        if (onAction != null && actionLabel != null) ...[
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    ),
  );
}

class BusyButton extends StatelessWidget {
  const BusyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: busy ? null : onPressed,
    icon: busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              semanticsLabel: 'Request in progress',
            ),
          )
        : icon == null
        ? const SizedBox.shrink()
        : Icon(icon, size: 20),
    label: Text(label, textAlign: TextAlign.center),
  );
}

class AdaptiveActions extends StatelessWidget {
  const AdaptiveActions({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );
}

class RiskBadge extends StatelessWidget {
  const RiskBadge(this.level, {super.key});
  final String level;
  @override
  Widget build(BuildContext context) {
    final tone = RiskTone.of(context, level);
    return Semantics(
      label: 'Risk level: $level',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: tone.container,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tone.icon, color: tone.foreground, size: 19),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                level,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: tone.foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RiskScore extends StatelessWidget {
  const RiskScore({
    super.key,
    required this.score,
    required this.level,
    required this.summary,
  });
  final int score;
  final String level, summary;
  @override
  Widget build(BuildContext context) {
    final tone = RiskTone.of(context, level);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              RiskBadge(level),
              Semantics(
                label:
                    'Risk score $score out of 100. Indicator score, not a probability.',
                excludeSemantics: true,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$score',
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(color: tone.foreground),
                      ),
                      TextSpan(
                        text: ' / 100',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ExcludeSemantics(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: score.clamp(0, 100) / 100),
              duration: motionDuration(context),
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 7,
                color: tone.foreground,
                backgroundColor: tone.container,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(summary, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text(
            'An indicator score, not the probability of fraud.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class ChannelTile extends StatelessWidget {
  const ChannelTile({
    super.key,
    required this.channel,
    required this.description,
    required this.onTap,
  });
  final String channel, description;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  channelIcon(channel),
                  color: Theme.of(context).colorScheme.primary,
                  size: 26,
                ),
                const Spacer(),
                const Icon(Icons.arrow_outward_rounded, size: 18),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              channelLabel(channel),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ),
  );
}

class ScanTile extends StatelessWidget {
  const ScanTile(this.scan, {super.key, required this.onTap});
  final Json scan;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final tone = RiskTone.of(context, scan['risk_level']);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(channelIcon(scan['channel'])),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channelLabel(scan['channel']),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timestamp(scan['created_at']),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(tone.icon, size: 17, color: tone.foreground),
                        Text(
                          '${scan['risk_level']} · ${scan['score']}/100',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: tone.foreground),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class EvidenceTile extends StatelessWidget {
  const EvidenceTile(this.item, {super.key});
  final Json item;
  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      key: PageStorageKey('evidence-${item['code'] ?? item['title']}'),
      title: Text(
        item['title'] as String,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subtitle: Text('${item['points']} rule points'),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            item['evidence'] as String,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    ),
  );
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.danger = false,
    this.enabled = true,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger, enabled;
  @override
  Widget build(BuildContext context) => ListTile(
    enabled: enabled,
    leading: Icon(
      icon,
      color: danger
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.primary,
    ),
    title: Text(
      title,
      style: danger
          ? TextStyle(color: Theme.of(context).colorScheme.error)
          : null,
    ),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing:
        trailing ??
        (onTap == null ? null : const Icon(Icons.chevron_right_rounded)),
    onTap: enabled ? onTap : null,
  );
}

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading your information',
    child: ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final height in [24.0, 112.0, 64.0]) ...[
            Container(
              height: height,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    ),
  );
}

class ProcessingPanel extends StatelessWidget {
  const ProcessingPanel({super.key, this.uploadProgress});
  final double? uploadProgress;
  @override
  Widget build(BuildContext context) {
    final uploading = uploadProgress != null && uploadProgress! < 1;
    final label = uploading ? 'Uploading file' : 'Analyzing your content';
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(label, style: Theme.of(context).textTheme.titleSmall),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: uploading ? uploadProgress!.clamp(0, 1) : null,
            semanticsLabel: label,
          ),
          const SizedBox(height: 8),
          Text(
            uploading
                ? '${(uploadProgress! * 100).round()}% uploaded'
                : 'Waiting for the analysis service. Your result will appear when it is ready.',
          ),
        ],
      ),
    );
  }
}

class ViewRefreshScope extends InheritedWidget {
  const ViewRefreshScope({
    super.key,
    required this.revision,
    required this.activeIndex,
    required super.child,
  });
  final int revision, activeIndex;
  static ViewRefreshScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ViewRefreshScope>();
  @override
  bool updateShouldNotify(ViewRefreshScope oldWidget) =>
      revision != oldWidget.revision || activeIndex != oldWidget.activeIndex;
}

class ApiPanel extends StatefulWidget {
  const ApiPanel({super.key, required this.load, required this.builder});
  final Future<Json> Function() load;
  final Widget Function(Json) builder;
  @override
  State<ApiPanel> createState() => _ApiPanelState();
}

class _ApiPanelState extends State<ApiPanel> {
  late Future<Json> data = widget.load();
  int? revision;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = ViewRefreshScope.of(context)?.revision;
    if (revision != null && next != revision) data = widget.load();
    revision = next;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Json>(
    future: data,
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: LoadingSkeleton(),
        );
      }
      if (snap.hasError) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Couldn’t load this information',
            body: errorMessage(snap.error!),
            actionLabel: 'Retry',
            onAction: () => setState(() => data = widget.load()),
          ),
        );
      }
      if (!snap.hasData) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: LoadingSkeleton(),
        );
      }
      return widget.builder(snap.data!);
    },
  );
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String message, {
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ) ??
    false;
void showMessage(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
