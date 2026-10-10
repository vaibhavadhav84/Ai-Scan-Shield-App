import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/api.dart';

Color riskColor(String level) => switch (level) {
  'High Risk' => const Color(0xffc43b48),
  'Suspicious' => const Color(0xff966000),
  _ => const Color(0xff087d69),
};

String timestamp(dynamic seconds) => DateTime.fromMillisecondsSinceEpoch(
  ((seconds as num) * 1000).round(),
).toLocal().toString().substring(0, 16);

class Brand extends StatelessWidget {
  const Brand({super.key, this.large = false});
  final bool large;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SvgPicture.asset(
        'assets/branding/icon.svg',
        width: large ? 72 : 32,
        semanticsLabel: 'Scan Shield logo',
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          'Scan Shield',
          style: TextStyle(
            fontSize: large ? 32 : 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -.7,
          ),
        ),
      ),
    ],
  );
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children
              .map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: w,
                ),
              )
              .toList(),
        ),
      ),
    ),
  );
}

class Notice extends StatelessWidget {
  const Notice(this.text, {super.key, this.icon = Icons.info_outline});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}

class RiskBadge extends StatelessWidget {
  const RiskBadge(this.level, {super.key});
  final String level;
  @override
  Widget build(BuildContext context) => Chip(
    side: BorderSide(color: riskColor(level)),
    avatar: Icon(
      level == 'Safe' ? Icons.check_circle_outline : Icons.warning_amber,
      color: riskColor(level),
      size: 18,
    ),
    label: Text(level),
  );
}

class ScanTile extends StatelessWidget {
  const ScanTile(this.scan, {super.key, required this.onTap});
  final Json scan;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: riskColor(scan['risk_level']),
        foregroundColor: Colors.white,
        child: Text('${scan['score']}'),
      ),
      title: Text(
        '${(scan['channel'] as String).toUpperCase()} · ${scan['risk_level']}',
      ),
      subtitle: Text(timestamp(scan['created_at'])),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
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
  @override
  void didUpdateWidget(ApiPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    data = widget.load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Json>(
    future: data,
    builder: (context, snap) {
      if (snap.hasError) {
        return PageBody(
          children: [
            Notice(errorMessage(snap.error!)),
            FilledButton.icon(
              onPressed: () => setState(() => data = widget.load()),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        );
      }
      if (!snap.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      return widget.builder(snap.data!);
    },
  );
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ??
    false;

void showMessage(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
