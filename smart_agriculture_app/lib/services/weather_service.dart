import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather_data.dart';

class WeatherService {
  WeatherService._();

  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  static Future<WeatherData> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'latitude': latitude.toStringAsFixed(4),
        'longitude': longitude.toStringAsFixed(4),
        'current':
            'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
        'daily':
            'temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max',
        'forecast_days': '1',
        'temperature_unit': 'celsius',
        'windspeed_unit': 'kmh',
        'timezone': 'auto',
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Could not fetch weather. Please check your connection.');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final current = json['current'] as Map<String, dynamic>?;
    if (current == null) {
      throw Exception('Weather data is not available right now.');
    }

    final daily = json['daily'] as Map<String, dynamic>?;

    return WeatherData(
      temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 0,
      humidity: (current['relative_humidity_2m'] as num?)?.toDouble() ?? 0,
      windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0,
      weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
      time: (current['time'] as String?) ?? '',
      latitude: latitude,
      longitude: longitude,
      dailyMaxTemp: _first(daily, 'temperature_2m_max'),
      dailyMinTemp: _first(daily, 'temperature_2m_min'),
      precipitationMm: _first(daily, 'precipitation_sum'),
      rainChancePercent: _first(daily, 'precipitation_probability_max'),
    );
  }

  static double? _first(Map<String, dynamic>? daily, String key) {
    final values = daily?[key];
    if (values is! List || values.isEmpty) return null;
    return (values.first as num?)?.toDouble();
  }
}
