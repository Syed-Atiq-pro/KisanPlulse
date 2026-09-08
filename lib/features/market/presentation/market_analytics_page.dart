import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/market_models.dart';
import '../data/market_repository.dart';

class MarketAnalyticsPage extends StatefulWidget {
  const MarketAnalyticsPage({super.key, required this.commodity});
  final String commodity;

  @override
  State<MarketAnalyticsPage> createState() => _MarketAnalyticsPageState();
}

class _MarketAnalyticsPageState extends State<MarketAnalyticsPage> {
  final repo = MarketRepository(Supabase.instance.client);
  int days = 30;
  Future<List<MarketPrice>>? history;
  Future<List<MarketPrice>>? comparison;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      history = repo.latestPrices(commodity: widget.commodity, days: days);
      comparison = repo.latestPrices(commodity: widget.commodity, days: 7);
    });
  }

  List<MarketPrice> _latestPerMarket(List<MarketPrice> rows) {
    final result = <String, MarketPrice>{};
    for (final row in rows) {
      final current = result[row.marketId];
      if (current == null || row.priceDate.isAfter(current.priceDate)) {
        result[row.marketId] = row;
      }
    }
    return result.values.toList()
      ..sort((a, b) => b.modalPrice.compareTo(a.modalPrice));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.commodity} Analytics', style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.insights_rounded),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Price trend for ${widget.commodity}', style: const TextStyle(fontWeight: FontWeight.w700))),
                  DropdownButton<int>(
                    value: days,
                    items: const [7, 14, 30, 90].map((v) => DropdownMenuItem(value: v, child: Text('$v days'))).toList(),
                    onChanged: (v) { if (v != null) { days = v; _reload(); } },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<MarketPrice>>(
            future: history,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const SizedBox(height: 260, child: Center(child: CircularProgressIndicator()));
              if (snap.hasError) return _errorCard('Unable to load price history.');
              final rows = [...(snap.data ?? [])]..sort((a, b) => a.priceDate.compareTo(b.priceDate));
              if (rows.isEmpty) return _emptyCard('No price history is available yet.');
              final spots = <FlSpot>[];
              for (var i = 0; i < rows.length; i++) {
                spots.add(FlSpot(i.toDouble(), rows[i].modalPrice));
              }
              final minY = rows.map((e) => e.modalPrice).reduce((a, b) => a < b ? a : b);
              final maxY = rows.map((e) => e.modalPrice).reduce((a, b) => a > b ? a : b);
              final padding = ((maxY - minY) * .15).clamp(10, 1000).toDouble();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
                  child: SizedBox(
                    height: 260,
                    child: LineChart(LineChartData(
                      minY: (minY - padding).clamp(0, double.infinity),
                      maxY: maxY + padding,
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: rows.length > 6 ? (rows.length / 4).ceilToDouble() : 1, getTitlesWidget: (value, meta) {
                          final index = value.round();
                          if (index < 0 || index >= rows.length) return const SizedBox.shrink();
                          final d = rows[index].priceDate;
                          return Padding(padding: const EdgeInsets.only(top: 8), child: Text('${d.day}/${d.month}', style: const TextStyle(fontSize: 10)));
                        })),
                      ),
                      lineBarsData: [LineChartBarData(spots: spots, isCurved: true, barWidth: 3, dotData: FlDotData(show: rows.length <= 20))],
                    )),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          const Text('Best recent mandi prices', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          FutureBuilder<List<MarketPrice>>(
            future: comparison,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
              if (snap.hasError) return _errorCard('Unable to compare markets.');
              final rows = _latestPerMarket(snap.data ?? []);
              if (rows.isEmpty) return _emptyCard('No market comparison data is available yet.');
              return Column(children: rows.take(10).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final price = entry.value;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text('₹${price.modalPrice.toStringAsFixed(0)} / ${price.unit}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${price.commodity} • ${price.priceDate.day}/${price.priceDate.month}/${price.priceDate.year}'),
                    trailing: price.maxPrice == null ? null : Text('Max ₹${price.maxPrice!.toStringAsFixed(0)}'),
                  ),
                );
              }).toList());
            },
          ),
          const SizedBox(height: 12),
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Ranking uses the latest available modal price per market in the selected data window. Verify the current local mandi quotation before selling.'))),
        ],
      ),
    );
  }

  Widget _errorCard(String text) => Card(child: Padding(padding: const EdgeInsets.all(20), child: Text(text)));
  Widget _emptyCard(String text) => Card(child: Padding(padding: const EdgeInsets.all(20), child: Text(text)));
}
