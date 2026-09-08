import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/irrigation_calculator.dart';
import '../data/irrigation_models.dart';
import '../data/irrigation_repository.dart';
import '../../weather/data/weather_service.dart';

class IrrigationPage extends StatefulWidget {
  const IrrigationPage({super.key});
  @override State<IrrigationPage> createState() => _IrrigationPageState();
}

class _IrrigationPageState extends State<IrrigationPage> {
  final calculator = IrrigationCalculator();
  final repo = IrrigationRepository(Supabase.instance.client);
  final et0Controller = TextEditingController(text: '4.5');
  final rainController = TextEditingController(text: '0');
  final kcController = TextEditingController(text: '1.0');
  IrrigationRecommendation? result;
  bool loading = false;
  String? error;

  Future<void> _loadWeather() async {
    setState(() { loading = true; error = null; });
    try {
      const service = WeatherService();
      final weather = await service.current(16.5062, 80.6480);
      et0Controller.text = weather.et0Mm.toStringAsFixed(1);
      final forecast = await service.daily(16.5062, 80.6480);
      rainController.text = forecast.first.precipitation.toStringAsFixed(1);
      _calculate();
    } catch (e) {
      setState(() => error = 'Could not load weather-based water demand: $e');
    } finally { if (mounted) setState(() => loading = false); }
  }

  void _calculate() {
    final et0 = double.tryParse(et0Controller.text);
    final rain = double.tryParse(rainController.text);
    final kc = double.tryParse(kcController.text);
    if (et0 == null || rain == null || kc == null || et0 < 0 || rain < 0 || kc <= 0) {
      setState(() => error = 'Enter valid ET₀, rainfall and crop coefficient values.');
      return;
    }
    setState(() { error = null; result = calculator.calculate(et0Mm: et0, cropCoefficient: kc, rainMm: rain); });
  }

  @override void dispose() { et0Controller.dispose(); rainController.dispose(); kcController.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Irrigation')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Water demand planner', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Estimate crop water demand from weather, crop stage and recent rainfall. This is a planning aid, not a replacement for field measurements.'),
          const SizedBox(height: 18),
          TextField(controller: et0Controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reference ET₀ (mm/day)', prefixIcon: Icon(Icons.wb_sunny_outlined))),
          const SizedBox(height: 10),
          TextField(controller: kcController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Crop coefficient Kc', prefixIcon: Icon(Icons.eco_outlined))),
          const SizedBox(height: 10),
          TextField(controller: rainController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Recent rainfall (mm)', prefixIcon: Icon(Icons.water_drop_outlined))),
          const SizedBox(height: 16),
          Row(children: [Expanded(child: FilledButton.icon(onPressed: loading ? null : _loadWeather, icon: const Icon(Icons.cloud_download_outlined), label: const Text('Use weather'))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(onPressed: _calculate, icon: const Icon(Icons.calculate_outlined), label: const Text('Calculate')))]),
        ]))),
        if (loading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        if (result != null) _RecommendationCard(result: result!),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.info_outline), const SizedBox(width: 12), const Expanded(child: Text('AgriSense uses the FAO-style ET₀ × Kc approach as a starting point. Soil type, effective rainfall, irrigation efficiency and measured soil moisture should be incorporated before automating irrigation.'))]))),
      ],),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.result});
  final IrrigationRecommendation result;
  @override Widget build(BuildContext context) {
    final litresPerSquareMeter = result.netWaterMm;
    return Card(margin: const EdgeInsets.only(top: 16), child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Today’s recommendation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 16),
      Row(children: [Expanded(child: _Metric(label: 'Crop ET', value: '${result.cropEtMm.toStringAsFixed(1)} mm')), Expanded(child: _Metric(label: 'Rain used', value: '${result.rainMm.toStringAsFixed(1)} mm')), Expanded(child: _Metric(label: 'Net need', value: '${result.netWaterMm.toStringAsFixed(1)} mm'))]),
      const SizedBox(height: 18),
      LinearProgressIndicator(value: (result.netWaterMm / 12).clamp(0, 1)),
      const SizedBox(height: 14),
      Text(result.message, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text('1 mm of water is approximately 1 litre per m², so ${litresPerSquareMeter.toStringAsFixed(1)} mm corresponds to about ${litresPerSquareMeter.toStringAsFixed(1)} L/m² before field losses.', style: Theme.of(context).textTheme.bodySmall),
    ])));
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label; final String value;
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(label, style: Theme.of(context).textTheme.bodySmall)]);
}
