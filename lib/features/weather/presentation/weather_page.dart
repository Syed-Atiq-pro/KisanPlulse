import 'package:flutter/material.dart';
import '../data/weather_service.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});
  @override State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final service = WeatherService();
  Future<({WeatherSnapshot current, List<DailyForecast> days})>? future;
  static const latitude = 16.5062;
  static const longitude = 80.6480;

  @override void initState() { super.initState(); _load(); }
  void _load() => setState(() => future = _fetch());
  Future<({WeatherSnapshot current, List<DailyForecast> days})> _fetch() async => (current: await service.current(latitude, longitude), days: await service.daily(latitude, longitude));

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Weather Intelligence')),
    body: FutureBuilder<({WeatherSnapshot current, List<DailyForecast> days})>(future: future, builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snap.hasError) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, size: 52), const SizedBox(height: 12), const Text('Unable to load weather'), TextButton(onPressed: _load, child: const Text('Retry'))]));
      final data = snap.data!;
      return RefreshIndicator(onRefresh: () async { _load(); }, child: ListView(padding: const EdgeInsets.all(20), children: [
        Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [Icon(Icons.wb_sunny_rounded, size: 56, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 12), Text('${data.current.temperature.toStringAsFixed(1)}°C', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)), Text(weatherLabel(data.current.weatherCode), style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 18), Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Text('Feels ${data.current.apparentTemperature.toStringAsFixed(1)}°'), Text('Humidity ${data.current.humidity.toStringAsFixed(0)}%'), Text('Wind ${data.current.windSpeed.toStringAsFixed(1)} km/h')])]))),
        const SizedBox(height: 20), const Text('7-day forecast', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 10),
        ...data.days.map((d) => Card(child: ListTile(leading: const Icon(Icons.cloud_rounded), title: Text('${d.date.day}/${d.date.month} • ${weatherLabel(d.code)}'), subtitle: Text('Rain ${d.precipitation.toStringAsFixed(1)} mm'), trailing: Text('${d.max.toStringAsFixed(0)}° / ${d.min.toStringAsFixed(0)}°', style: const TextStyle(fontWeight: FontWeight.w700)))))
      ]));
    }),
  );
}
