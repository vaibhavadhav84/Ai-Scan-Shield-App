import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api.dart';
import '../../core/providers.dart';
import '../../shared/widgets.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key, this.alerts = false});
  final bool alerts;
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsState();
}

class _ReportsState extends ConsumerState<ReportsScreen> {
  int offset = 0, revision = 0;
  final Set<String> markingRead = {};
  @override
  void didUpdateWidget(ReportsScreen oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.alerts != widget.alerts) { offset = 0; revision++; } }
  @override
  Widget build(BuildContext context) {
    final api = ref.read(apiProvider);
    final body = ApiPanel(
      key: ValueKey('${widget.alerts}:$offset:$revision'),
      load: () => api.get(widget.alerts ? '/alerts' : '/reports', query: {'offset': offset, 'limit': 20}),
      builder: (data) {
        final items = data['items'] as List;
        return PageBody(storageKey: widget.alerts ? 'security-alerts' : 'your-reports', children: [
          PageHeading(title: widget.alerts ? 'Security alerts' : 'Your reports', eyebrow: widget.alerts ? 'REVIEW & RESPOND' : 'INTERNAL REVIEW', subtitle: widget.alerts ? 'Review the guidance for scans that need attention.' : 'Track the concerns you have submitted.', trailing: IconButton(tooltip: widget.alerts ? 'Refresh alerts' : 'Refresh reports', icon: const Icon(Icons.refresh), onPressed: () => setState(() => revision++))),
          if (!widget.alerts) const Notice('Reports go to internal review. Government and cybercrime submission is not connected. Submit a report from a scan result.'),
          if (items.isEmpty) EmptyState(icon: widget.alerts ? Icons.notifications_none_outlined : Icons.flag_outlined, title: offset > 0 ? 'You have reached the end' : widget.alerts ? 'No alerts to review' : 'No reports yet', body: offset > 0 ? 'Return to the previous page to view earlier items.' : widget.alerts ? 'Alerts for scans that need attention will appear here. No alerts does not guarantee safety.' : 'If a scan raises a concern, open its result and choose Report this scan.', actionLabel: offset > 0 ? 'Previous page' : widget.alerts ? 'View scan history' : 'Review a scan', onAction: offset > 0 ? () => setState(() => offset -= 20) : () => context.go('/history')),
          for (final item in items) widget.alerts ? _alertCard(context, api, Map<String, dynamic>.from(item as Map)) : _reportCard(context, Map<String, dynamic>.from(item as Map)),
          if (items.length == 20 || offset > 0) ...[
            Text('Page ${offset ~/ 20 + 1}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelLarge),
            AdaptiveActions(children: [OutlinedButton.icon(onPressed: offset == 0 ? null : () => setState(() => offset -= 20), icon: const Icon(Icons.chevron_left), label: const Text('Previous')), OutlinedButton.icon(onPressed: items.length < 20 ? null : () => setState(() => offset += 20), icon: const Icon(Icons.chevron_right), label: const Text('Next'))]),
          ],
        ]);
      },
    );
    return widget.alerts ? Scaffold(appBar: AppBar(title: const Text('Alerts')), body: body) : body;
  }

  Widget _alertCard(BuildContext context, Api api, Json item) {
    final unread = item['read'] == false;
    final busy = markingRead.contains(item['id']);
    return SurfaceCard(color: unread ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .28) : null, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [RiskBadge(item['severity']), Text(unread ? 'Unread' : 'Read', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: unread ? FontWeight.w700 : FontWeight.w400))]),
      const SizedBox(height: 12),
      Text(item['message'], style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Text(timestamp(item['created_at']), style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 16),
      AdaptiveActions(children: [FilledButton.tonalIcon(onPressed: () => context.push('/result/${item['scan_id']}'), icon: const Icon(Icons.arrow_forward), label: const Text('Review result')), if (unread) TextButton.icon(onPressed: busy ? null : () => _markRead(api, item['id']), icon: const Icon(Icons.done), label: Text(busy ? 'Marking read…' : 'Mark read'))]),
    ]));
  }

  Widget _reportCard(BuildContext context, Json item) => SurfaceCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Text(_category(item['category']), style: Theme.of(context).textTheme.titleMedium),
    const SizedBox(height: 8),
    Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [Chip(avatar: const Icon(Icons.assignment_outlined, size: 18), label: Text(_status(item['status']))), Text(timestamp(item['created_at']), style: Theme.of(context).textTheme.bodySmall)]),
    const SizedBox(height: 8),
    Text(_statusDescription(item['status']), style: Theme.of(context).textTheme.bodyMedium),
    const SizedBox(height: 16),
    Align(alignment: AlignmentDirectional.centerStart, child: OutlinedButton.icon(onPressed: () => context.push('/result/${item['scan_id']}'), icon: const Icon(Icons.arrow_forward), label: const Text('View scan result'))),
  ]));

  String _category(String category) => switch (category) { 'credentials' => 'Credential theft', 'payment' => 'Payment request', 'impersonation' => 'Impersonation', 'investment' => 'Investment offer', _ => 'Other concern' };
  String _status(String status) => switch (status) { 'submitted' => 'Submitted', 'pending' => 'Pending review', 'reviewed' => 'Reviewed', 'dismissed' => 'Dismissed', 'escalated' => 'Escalated', _ => status };
  String _statusDescription(String status) => switch (status) { 'reviewed' => 'Marked reviewed by an internal reviewer.', 'dismissed' => 'Dismissed during internal review.', 'escalated' => 'Escalated within the internal review process.', _ => 'Submitted for internal review. No review timeframe is guaranteed.' };
  Future<void> _markRead(Api api, String id) async {
    if (markingRead.contains(id)) return;
    setState(() => markingRead.add(id));
    try { await api.request('PATCH', '/alerts/$id/read'); if (mounted) setState(() => revision++); }
    catch (e) { if (mounted) showMessage(context, errorMessage(e)); }
    finally { if (mounted) setState(() => markingRead.remove(id)); }
  }
}
