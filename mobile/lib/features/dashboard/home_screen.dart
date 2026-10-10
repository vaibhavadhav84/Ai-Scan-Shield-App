import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../shared/widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(apiProvider);
    return ApiPanel(
      load: () async {
        final summary = await api.get('/scans/summary');
        final history = await api.get('/scans', query: {'limit': 3});
        final capability = await api.get('/capabilities');
        return {
          'summary': summary,
          'history': history,
          'capability': capability,
        };
      },
      builder: (data) => PageBody(
        children: [
          Text(
            'Stay a step ahead',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const Text('A clear view of the communication you chose to check.'),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined, size: 36),
                  const SizedBox(height: 16),
                  Text(
                    '${data['summary']['total']} scans in your history',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No background monitoring. Your scans, your choice.',
                  ),
                ],
              ),
            ),
          ),
          Text('Quick scan', style: Theme.of(context).textTheme.titleLarge),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final entry in {
                'sms': (Icons.sms_outlined, 'SMS / text'),
                'email': (Icons.mail_outline, 'Email'),
                'url': (Icons.link, 'URL'),
                'voice': (Icons.mic_none, 'Voice'),
                'call': (Icons.call_outlined, 'Call details'),
              }.entries)
                OutlinedButton.icon(
                  onPressed: () => context.go('/scan?channel=${entry.key}'),
                  icon: Icon(entry.value.$1),
                  label: Text(entry.value.$2),
                ),
            ],
          ),
          Text(
            'Risk distribution',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Wrap(
            spacing: 12,
            children: [
              for (final level in ['Safe', 'Suspicious', 'High Risk'])
                Chip(
                  label: Text(
                    '$level: ${data['summary']['risk_distribution'][level] ?? 0}',
                  ),
                  avatar: Icon(Icons.circle, size: 12, color: riskColor(level)),
                ),
            ],
          ),
          Text('Recent checks', style: Theme.of(context).textTheme.titleLarge),
          if ((data['history']['items'] as List).isEmpty)
            const Notice('No scans yet. Start with a message or link.'),
          for (final scan in data['history']['items'])
            ScanTile(scan, onTap: () => context.push('/result/${scan['id']}')),
          OutlinedButton.icon(
            onPressed: () => context.push('/alerts'),
            icon: const Icon(Icons.notifications_none),
            label: const Text('Security alerts'),
          ),
          Notice(
            data['capability']['engine'] == 'rule-baseline'
                ? 'Transparent rule baseline active. No validated machine-learning model is loaded.'
                : 'Rules and a versioned model are active. Results still require independent verification.',
          ),
          const Notice(
            'A low score is not proof of safety. This app cannot authenticate callers '
            'or protect communications you have not submitted.',
          ),
        ],
      ),
    );
  }
}
