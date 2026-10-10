import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api.dart';
import '../../core/providers.dart';
import '../../shared/widgets.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});
  @override
  ConsumerState<HistoryScreen> createState() => _HistoryState();
}

class _HistoryState extends ConsumerState<HistoryScreen> {
  String? channel, risk;
  String appliedSearch = '';
  int offset = 0, revision = 0;
  bool clearing = false;
  final search = TextEditingController();
  DateTime? start, end;
  @override
  void dispose() { search.dispose(); super.dispose(); }

  bool get filtered => channel != null || risk != null || appliedSearch.isNotEmpty || start != null;
  void _reset() => setState(() {
    channel = risk = null;
    appliedSearch = '';
    search.clear();
    start = end = null;
    offset = 0;
  });
  void _search() => setState(() { appliedSearch = search.text.trim(); offset = 0; });

  @override
  Widget build(BuildContext context) {
    final api = ref.read(apiProvider);
    return PageBody(storageKey: 'scan-history', children: [
      const PageHeading(title: 'Scan history', eyebrow: 'YOUR ACTIVITY', subtitle: 'Revisit results and the guidance behind them.'),
      const Text('History stores result metadata. Original messages, URLs and recordings are not stored.'),
      SurfaceCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: search, textInputAction: TextInputAction.search, decoration: InputDecoration(labelText: 'Search scan ID', prefixIcon: const Icon(Icons.search), suffixIcon: IconButton(tooltip: 'Search history', icon: const Icon(Icons.arrow_forward), onPressed: _search)), onSubmitted: (_) => _search()),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          final channelField = DropdownButtonFormField<String>(key: ValueKey('channel:$channel'), initialValue: channel ?? '', isExpanded: true, decoration: const InputDecoration(labelText: 'Channel'), items: ['', 'sms', 'email', 'url', 'voice', 'call'].map((v) => DropdownMenuItem(value: v, child: Text(v.isEmpty ? 'All channels' : channelLabel(v)))).toList(), onChanged: (v) => setState(() { channel = v!.isEmpty ? null : v; offset = 0; }));
          final riskField = DropdownButtonFormField<String>(key: ValueKey('risk:$risk'), initialValue: risk ?? '', isExpanded: true, decoration: const InputDecoration(labelText: 'Risk level'), items: ['', 'Safe', 'Suspicious', 'High Risk'].map((v) => DropdownMenuItem(value: v, child: Text(v.isEmpty ? 'All levels' : v))).toList(), onChanged: (v) => setState(() { risk = v!.isEmpty ? null : v; offset = 0; }));
          if (constraints.maxWidth < 460 || MediaQuery.textScalerOf(context).scale(16) > 24) return Column(children: [channelField, const SizedBox(height: 16), riskField]);
          return Row(children: [Expanded(child: channelField), const SizedBox(width: 16), Expanded(child: riskField)]);
        }),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(onPressed: _selectDates, icon: const Icon(Icons.date_range_outlined), label: Text(start == null ? 'Filter dates' : '${_date(start!)} – ${_date(end!.subtract(const Duration(days: 1)))}')),
          if (filtered) TextButton(onPressed: _reset, child: const Text('Reset filters')),
        ]),
      ])),
      ApiPanel(
        key: ValueKey('$offset:$channel:$risk:$revision:$appliedSearch:$start:$end'),
        load: () => api.get('/scans', allowCache: true, query: {'offset': offset, 'limit': 20, 'search': appliedSearch, if (channel != null) 'channel': channel, if (risk != null) 'risk': risk, if (start != null) 'start': start!.millisecondsSinceEpoch / 1000, if (end != null) 'end': end!.millisecondsSinceEpoch / 1000}),
        builder: (data) {
          final items = data['items'] as List;
          final total = data['total'] as int;
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (data['offline_cache'] == true) ...[
              const Notice('Offline: cached results from the last 24 hours. Changes require a connection.', icon: Icons.cloud_off_outlined, kind: NoticeKind.warning),
              const SizedBox(height: 16),
            ],
            SectionHeading('$total ${total == 1 ? 'scan' : 'scans'}${filtered ? ' found' : ' saved'}', action: IconButton(tooltip: 'Refresh history', onPressed: () => setState(() => revision++), icon: const Icon(Icons.refresh))),
            const SizedBox(height: 16),
            if (items.isEmpty) EmptyState(icon: Icons.history_outlined, title: filtered ? 'No matching scans' : 'Your history starts here', body: filtered ? 'Try a different scan ID, channel, risk level or date range.' : 'Run a scan to save its result and recommended next steps.', actionLabel: filtered ? 'Reset filters' : 'Start a scan', onAction: filtered ? _reset : () => context.go('/scan')),
            for (final scan in items) Padding(padding: const EdgeInsets.only(bottom: 12), child: ScanTile(Map<String, dynamic>.from(scan as Map), onTap: () => context.push('/result/${scan['id']}', extra: scan))),
            if (total > 20 || offset > 0) ...[
              const SizedBox(height: 12),
              Text('Page ${offset ~/ 20 + 1}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              AdaptiveActions(children: [OutlinedButton.icon(onPressed: offset == 0 ? null : () => setState(() => offset -= 20), icon: const Icon(Icons.chevron_left), label: const Text('Previous')), OutlinedButton.icon(onPressed: offset + 20 >= total ? null : () => setState(() => offset += 20), icon: const Icon(Icons.chevron_right), label: const Text('Next'))]),
            ],
          ]);
        },
      ),
      const Divider(),
      TextButton.icon(onPressed: clearing ? null : () => _clear(api), icon: const Icon(Icons.delete_outline), label: Text(clearing ? 'Clearing history…' : 'Clear all history')),
    ]);
  }

  String _date(DateTime date) => '${date.day}/${date.month}/${date.year}';
  Future<void> _selectDates() async {
    final dates = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now(), initialDateRange: start == null ? null : DateTimeRange(start: start!, end: end!.subtract(const Duration(days: 1))));
    if (dates != null && mounted) setState(() { start = dates.start; end = DateTime(dates.end.year, dates.end.month, dates.end.day + 1); offset = 0; });
  }
  Future<void> _clear(Api api) async {
    if (clearing) return;
    setState(() => clearing = true);
    try {
      if (!await confirm(context, 'Clear all history?', 'This permanently removes all your scans and linked alerts, feedback and reports, including results outside the current filters.', confirmLabel: 'Clear all history', destructive: true)) return;
      await api.request('DELETE', '/scans');
      await api.clearCache();
      if (mounted) { setState(() { revision++; offset = 0; }); showMessage(context, 'Your scan history was cleared.'); }
    } catch (e) { if (mounted) showMessage(context, errorMessage(e)); }
    finally { if (mounted) setState(() => clearing = false); }
  }
}
