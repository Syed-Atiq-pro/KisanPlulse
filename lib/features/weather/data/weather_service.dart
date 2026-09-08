import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherSnapshot {
  const WeatherSnapshot({required this.temperature, required this.apparentTemperature, required this.humidity, required this.windSpeed, required this.weatherCode, required this.et0Mm, required this.time});
  final double temperature;
  final double apparentTemperature;
  final double humidity;
  final double windSpeed;
  final int weatherCode;
  final double et0Mm;
  final DateTime time;
  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) {
    final current = Map<String, dynamic>.from(json['current'] as Map);
    final daily = Map<String, dynamic>.from(json['daily'] as Map);
    final et0 = (daily['et0_fao_evapotranspiration'] as List).first as num;
    return WeatherSnapshot(temperature: (current['temperature_2m'] as num).toDouble(), apparentTemperature: (current['apparent_temperature'] as num).toDouble(), humidity: (current['relative_humidity_2m'] as num).toDouble(), windSpeed: (current['wind_speed_10m'] as num).toDouble(), weatherCode: (current['weather_code'] as num).toInt(), et0Mm: et0.toDouble(), time: DateTime.parse(current['time'] as String));
  }
}

class DailyForecast {
  const DailyForecast({required this.date, required this.max, required this.min, required this.precipitation, required this.et0Mm, required this.code});
  final DateTime date;
  final double max;
  final double min;
  final double precipitation;
  final double et0Mm;
  final int code;
}

class WeatherService {
  Future<WeatherSnapshot> current(double latitude, double longitude) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {'latitude': '$latitude', 'longitude': '$longitude', 'current': 'temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code', 'daily': 'et0_fao_evapotranspiration', 'forecast_days': '1', 'timezone': 'auto'});
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) throw Exception('Weather service returned ${response.statusCode}.');
    return WeatherSnapshot.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<DailyForecast>> daily(double latitude, double longitude) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {'latitude': '$latitude', 'longitude': '$longitude', 'daily': 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,et0_fao_evapotranspiration', 'forecast_days': '7', 'timezone': 'auto'});
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) throw Exception('Weather service returned ${response.statusCode}.');
    final daily = Map<String, dynamic>.from((jsonDecode(response.body) as Map)['daily'] as Map);
    final dates = List<String>.from(daily['time']);
    final max = List<num>.from(daily['temperature_2m_max']);
    final min = List<num>.from(daily['temperature_2m_min']);
    final rain = List<num>.from(daily['precipitation_sum']);
    final et0 = List<num>.from(daily['et0_fao_evapotranspiration']);
    final codes = List<num>.from(daily['weather_code']);
    return List.generate(dates.length, (i) => DailyForecast(date: DateTime.parse(dates[i]), max: max[i].toDouble(), min: min[i].toDouble(), precipitation: rain[i].toDouble(), et0Mm: et0[i].toDouble(), code: codes[i].toInt()));
  }
}

String weatherLabel(int code) {
  if (code == 0) return 'Clear sky';
  if ([1, 2, 3].contains(code)) return 'Partly cloudy';
  if ([45, 48].contains(code)) return 'Fog';
  if ([51, 53, 55, 56, 57].contains(code)) return 'Drizzle';
  if ([61, 63, 65, 66, 67].contains(code)) return 'Rain';
  if ([71, 73, 75, 77].contains(code)) return 'Snow';
  if ([80, 81, 82].contains(code)) return 'Rain showers';
  if ([95, 96, 99].contains(code)) return 'Thunderstorm';
  return 'Mixed conditions';
}
