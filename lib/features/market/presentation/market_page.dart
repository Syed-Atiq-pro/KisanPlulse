import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/market_models.dart';
import '../data/market_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});
  @override State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  final repo = MarketRepository(Supabase.instance.client);
  final commodity = TextEditingController(text: 'Tomato');
  Future<List<MarketPrice>>? prices;
  List<Market> markets = [];
  String? selectedMarket;
  bool loadingMarkets = true;

  @override
  void initState() { super.initState(); _loadMarkets(); _loadPrices(); }
  @override
  void dispose() { commodity.dispose(); super.dispose(); }

  Future<void> _loadMarkets() async {
    try {
      final data = await repo.listMarkets();
      if (mounted) setState(() { markets = data; loadingMarkets = false; });
    } catch (_) { if (mounted) setState(() => loadingMarkets = false); }
  }
  void _loadPrices() => setState(() => prices = repo.latestPrices(commodity: commodity.text.trim(), marketId: selectedMarket));

  Future<void> _addAlert() async {
    final target = TextEditingController();
    String direction = 'above';
    final ok = await showDialog<bool>(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(
      title: const Text('Create price alert'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Alert for ${commodity.text.trim()}'),
        const SizedBox(height: 12),
        TextField(controller: target, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Target ₹ / quintal')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: direction, decoration: const InputDecoration(labelText: 'Notify when'), items: const [DropdownMenuItem(value: 'above', child: Text('Price reaches above target')), DropdownMenuItem(value: 'below', child: Text('Price falls below target'))], onChanged: (v) => setDialog(() => direction = v ?? 'above')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, double.tryParse(target.text) != null), child: const Text('Save'))],
    )));
    final value = double.tryParse(target.text);
    target.dispose();
    if (ok == true && value != null && value >= 0) {
      await repo.createAlert(commodity: commodity.text.trim(), targetPrice: value, direction: direction, marketId: selectedMarket);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Price alert created')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Market Intelligence', style: TextStyle(fontWeight: FontWeight.w800)), actions: [IconButton(onPressed: _addAlert, icon: const Icon(Icons.notifications_active_rounded), tooltip: 'Price alert')]),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Mandi prices', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        TextField(controller: commodity, textInputAction: TextInputAction.search, onSubmitted: (_) => _loadPrices(), decoration: InputDecoration(labelText: 'Commodity', suffixIcon: IconButton(onPressed: _loadPrices, icon: const Icon(Icons.search_rounded)))),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(value: selectedMarket, decoration: const InputDecoration(labelText: 'Market'), items: [const DropdownMenuItem<String?>(value: null, child: Text('All markets')), ...markets.map((m) => DropdownMenuItem<String?>(value: m.id, child: Text('${m.name}${m.district == null ? '' : ' • ${m.district}'}', overflow: TextOverflow.ellipsis)))], onChanged: (v) { setState(() => selectedMarket = v); _loadPrices(); }),
        if (loadingMarkets) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
      ])),
      const SizedBox(height: 18),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Recent prices', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), TextButton.icon(onPressed: () => context.push('/market/analytics?commodity=${Uri.encodeComponent(commodity.text.trim())}'), icon: const Icon(Icons.analytics_outlined), label: const Text('Analytics'))]),
      const SizedBox(height: 8),
      FutureBuilder<List<MarketPrice>>(future: prices, builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()));
        if (snap.hasError) return Card(child: Padding(padding: const EdgeInsets.all(20), child: Text('Market data is unavailable. Apply the Phase 8 migration and sync official market data first.')));
        final items = snap.data ?? [];
        if (items.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No recent market records found for this commodity.')));
        return Column(children: items.map((p) => Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.storefront_rounded)), title: Text('${p.commodity} • ₹${p.modalPrice.toStringAsFixed(0)} / ${p.unit}'), subtitle: Text('${p.priceDate.day}/${p.priceDate.month}/${p.priceDate.year}  •  Min ₹${p.minPrice?.toStringAsFixed(0) ?? '-'}  •  Max ₹${p.maxPrice?.toStringAsFixed(0) ?? '-'}'), trailing: p.arrivalsTonnes == null ? null : Text('${p.arrivalsTonnes!.toStringAsFixed(1)} t')))).toList());
      }),
      const SizedBox(height: 16),
      const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Data source: Government Open Data / market-price datasets. Prices are informational and should be verified with the local mandi before a sale decision.'))),
    ],
  );
}
