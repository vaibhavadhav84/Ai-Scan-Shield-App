import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../shared/widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeState();
}

class _HomeState extends ConsumerState<HomeScreen> {
  int revision = 0;
  @override
  Widget build(BuildContext context) {
    final api = ref.read(apiProvider);
    return ApiPanel(
      key: ValueKey(revision),
      load: () async {
        final values = await Future.wait([
          api.get('/scans/summary'),
          api.get('/scans', query: {'limit': 3}),
          api.get('/capabilities'),
        ]);
        return {
          'summary': values[0],
          'history': values[1],
          'capability': values[2],
        };
      },
      builder: (data) => PageBody(
        storageKey: 'home',
        children: [
          PageHeading(
            title: 'A little clarity.\nA safer next step.',
            eyebrow: 'YOUR PERSONAL CHECKPOINT',
            trailing: IconButton(
              tooltip: 'Refresh dashboard',
              onPressed: () => setState(() => revision++),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ShieldPalette.hero,
              borderRadius: BorderRadius.circular(ShieldShape.hero),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: ShieldPalette.heroText,
                  size: 32,
                ),
                const SizedBox(height: 20),
                Text(
                  'Something feels off?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: ShieldPalette.heroText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check a message or link before you respond, pay or share details.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: ShieldPalette.heroMuted,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: ShieldPalette.hero,
                  ),
                  onPressed: () => context.go('/scan?channel=sms'),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Start a scan'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Only what you choose to share.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ShieldPalette.heroMuted,
                  ),
                ),
              ],
            ),
          ),
          const SectionHeading('What would you like to check?'),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns =
                  constraints.maxWidth >= 340 &&
                      MediaQuery.textScalerOf(context).scale(16) < 23
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final entry in {
                    'sms': 'A message that asks too much',
                    'email': 'Sender details and message',
                    'url': 'A link you haven’t opened',
                    'voice': 'Recording or transcript',
                  }.entries)
                    SizedBox(
                      width: width,
                      child: ChannelTile(
                        channel: entry.key,
                        description: entry.value,
                        onTap: () => context.go('/scan?channel=${entry.key}'),
                      ),
                    ),
                ],
              );
            },
          ),
          OutlinedButton.icon(
            onPressed: () => context.go('/scan?channel=call'),
            icon: const Icon(Icons.call_outlined),
            label: const Text('Describe a suspicious call'),
          ),
          SectionHeading(
            'Recent checks',
            subtitle: '${data['summary']['total']} scans in your saved history',
            action: TextButton(
              onPressed: () => context.go('/history'),
              child: const Text('View history'),
            ),
          ),
          if ((data['history']['items'] as List).isEmpty)
            EmptyState(
              icon: Icons.history_rounded,
              title: 'Your first check starts here',
              body:
                  'Results you save will appear here, with the guidance behind each score.',
              actionLabel: 'Check a message',
              onAction: () => context.go('/scan?channel=sms'),
            ),
          for (final scan in data['history']['items'])
            ScanTile(
              scan,
              onTap: () => context.push('/result/${scan['id']}', extra: scan),
            ),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: SettingsRow(
              icon: Icons.notifications_none_rounded,
              title: 'Security alerts',
              subtitle: 'Review alerts from your submitted scans',
              onTap: () => context.push('/alerts'),
            ),
          ),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              title: const Text('Know your protection boundaries'),
              subtitle: const Text(
                'You choose the content. You stay in control.',
              ),
              expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Scan Shield does not monitor your inbox or calls. A low score is not proof of safety, and callers are not authenticated.',
                ),
                const SizedBox(height: 12),
                Text(
                  data['capability']['engine'] == 'rule-baseline'
                      ? 'Rule-based indicators are active. No validated machine-learning model is loaded.'
                      : 'Rules and a versioned model are active. Independently verify sensitive requests.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
