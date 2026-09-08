import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/finance_models.dart';
import '../data/finance_repository.dart';

class FinanceAnalyticsPage extends StatefulWidget {
  const FinanceAnalyticsPage({super.key});
  @override State<FinanceAnalyticsPage> createState() => _FinanceAnalyticsPageState();
}

class _FinanceAnalyticsPageState extends State<FinanceAnalyticsPage> {
  final _repo = FinanceRepository(Supabase.instance.client);
  final _money = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  List<FinanceTransaction> _items = <FinanceTransaction>[];
  int _days = 90;
  bool _loading = true;
  String? _error;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await _repo.listTransactions(from: DateTime.now().subtract(Duration(days: _days)));
      if (!mounted) return;
      setState(() { _items = rows; _loading = false; });
    } catch (error) {
      if (!mounted) return;
      setState(() { _error = error.toString(); _loading = false; });
    }
  }

  Map<String, List<FinanceTransaction>> _groupByMonth() {
    final grouped = <String, List<FinanceTransaction>>{};
    for (final item in _items) {
      final key = DateFormat('MMM yy').format(item.transactionDate);
      grouped.putIfAbsent(key, () => <FinanceTransaction>[]).add(item);
    }
    return grouped;
  }

  double _total(String type) => _items.where((item) => item.type == type).fold(0.0, (sum, item) => sum + item.amount);

  List<Widget> _categoryRows() {
    final totals = <String, double>{};
    for (final item in _items.where((item) => item.type == 'expense')) {
      totals[item.category] = (totals[item.category] ?? 0) + item.amount;
    }
    final entries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) return const <Widget>[Text('No expense categories recorded yet.')];
    return entries.take(8).map((entry) => ListTile(title: Text(entry.key), trailing: Text(_money.format(entry.value), style: const TextStyle(fontWeight: FontWeight.w700)))).toList();
  }

  @override Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(title: const Text('Finance analytics')), body: const Center(child: CircularProgressIndicator()));
    final income = _total('income');
    final expense = _total('expense');
    final grouped = _groupByMonth();
    final months = grouped.entries.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Finance analytics')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text('Income vs expense', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [ButtonSegment<int>(value: 30, label: Text('30d')), ButtonSegment<int>(value: 90, label: Text('90d')), ButtonSegment<int>(value: 365, label: Text('1y'))],
            selected: <int>{_days},
            onSelectionChanged: (values) { setState(() => _days = values.first); _load(); },
          ),
          const SizedBox(height: 18),
          if (_error != null)
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!)))
          else
            Card(child: Padding(padding: const EdgeInsets.fromLTRB(10, 20, 20, 16), child: SizedBox(
              height: 280,
              child: months.isEmpty ? const Center(child: Text('No transactions for this period.')) : BarChart(
                BarChartData(
                  maxY: _chartMaxY(months),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= months.length) return const SizedBox.shrink();
                      return SideTitleWidget(meta: meta, child: Text(months[index].key, style: const TextStyle(fontSize: 10)));
                    })),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 46)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: List.generate(months.length, (index) {
                    final monthItems = months[index].value;
                    final incomeMonth = monthItems.where((item) => item.type == 'income').fold(0.0, (sum, item) => sum + item.amount);
                    final expenseMonth = monthItems.where((item) => item.type == 'expense').fold(0.0, (sum, item) => sum + item.amount);
                    return BarChartGroupData(x: index, barsSpace: 4, barRods: [BarChartRodData(toY: incomeMonth, width: 9), BarChartRodData(toY: expenseMonth, width: 9)]);
                  }),
                ),
              ),
            ))),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: Card(child: ListTile(title: const Text('Total income'), subtitle: Text(_money.format(income)), leading: const Icon(Icons.south_west_rounded)))),
            const SizedBox(width: 10),
            Expanded(child: Card(child: ListTile(title: const Text('Total expense'), subtitle: Text(_money.format(expense)), leading: const Icon(Icons.north_east_rounded)))),
          ]),
          const SizedBox(height: 10),
          Card(child: ListTile(title: const Text('Net profit'), subtitle: Text(_money.format(income - expense), style: const TextStyle(fontWeight: FontWeight.w800)), leading: const Icon(Icons.account_balance_wallet_rounded))),
          const SizedBox(height: 18),
          Text('Expense categories', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ..._categoryRows(),
          const SizedBox(height: 20),
          const Text('Analytics are calculated from your recorded ledger entries.'),
        ]),
      ),
    );
  }

  double _chartMaxY(Iterable<MapEntry<String, List<FinanceTransaction>>> grouped) {
    var maxValue = 1.0;
    for (final entry in grouped) {
      for (final item in entry.value) {
        if (item.amount > maxValue) maxValue = item.amount;
      }
    }
    return maxValue * 1.2;
  }
}
