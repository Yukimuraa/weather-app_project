import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class WeatherService {
  static const String baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const Duration _cacheTtl = Duration(minutes: 10);
  static const Duration _httpTimeout = Duration(seconds: 8);

  WeatherForecast? _cachedForecast;
  DateTime? _cachedAt;
  double? _cachedLat;
  double? _cachedLon;

  Future<WeatherForecast> getWeatherForecast(
    double latitude,
    double longitude,
    {bool forceRefresh = false}
  ) async {
    try {
      // Fast path: return recent in-memory cache
      if (!forceRefresh &&
          _cachedForecast != null &&
          _cachedAt != null &&
          _cachedLat == latitude &&
          _cachedLon == longitude &&
          DateTime.now().difference(_cachedAt!) <= _cacheTtl) {
        return _cachedForecast!;
      }

      final url = Uri.parse(
        '$baseUrl?latitude=$latitude&longitude=$longitude'
        '&hourly=temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m,weather_code'
        '&daily=weather_code'
        '&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,rain,showers,snowfall,weather_code,cloud_cover,pressure_msl,surface_pressure,wind_speed_10m,wind_direction_10m,wind_gusts_10m'
        '&timezone=auto'
        '&forecast_days=16',
      );

      final response = await http.get(url).timeout(_httpTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final forecast = _parseWeatherData(data, latitude, longitude);

        // Save cache
        _cachedForecast = forecast;
        _cachedAt = DateTime.now();
        _cachedLat = latitude;
        _cachedLon = longitude;

        return forecast;
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather: $e');
    }
  }

  // Helper function to safely convert dynamic to double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Helper function to convert list of dynamic to list of double
  List<double> _toDoubleList(List<dynamic>? list) {
    if (list == null) return [];
    return list.map((e) => _toDouble(e)).toList();
  }

  WeatherForecast _parseWeatherData(
    Map<String, dynamic> data,
    double latitude,
    double longitude,
  ) {
    final dailyForecast = <WeatherData>[];
    
    // Parse current weather data
    final current = data['current'] as Map<String, dynamic>?;
    if (current != null) {
      final currentTime = DateTime.parse(current['time'] as String);
      final currentWeatherCode = current['weather_code'] as int?;
      dailyForecast.add(WeatherData(
        temperature: _toDouble(current['temperature_2m']),
        humidity: _toDouble(current['relative_humidity_2m']),
        precipitation: _toDouble(current['precipitation']),
        windSpeed: _toDouble(current['wind_speed_10m']),
        soilTemperature: _toDouble(current['temperature_2m']), // Use air temp as fallback
        soilMoisture: 50.0, // Default value since not in current data
        date: currentTime,
        description: _getWeatherDescription(currentWeatherCode),
        weatherCode: currentWeatherCode,
      ));
    }

    // Parse daily weather codes
    final daily = data['daily'] as Map<String, dynamic>?;
    final dailyWeatherCodes = <DateTime, int>{};
    if (daily != null) {
      final dailyTimes = (daily['time'] as List?)?.map((e) => DateTime.parse(e)).toList() ?? [];
      final dailyCodes = (daily['weather_code'] as List?)?.map((e) => e as int).toList() ?? [];
      for (int i = 0; i < dailyTimes.length && i < dailyCodes.length; i++) {
        final date = DateTime(dailyTimes[i].year, dailyTimes[i].month, dailyTimes[i].day);
        dailyWeatherCodes[date] = dailyCodes[i];
      }
    }

    // Parse hourly data and group into daily averages
    final hourly = data['hourly'] as Map<String, dynamic>?;
    if (hourly != null) {
      final times = (hourly['time'] as List).map((e) => DateTime.parse(e)).toList();
      final temperatures = _toDoubleList(hourly['temperature_2m'] as List?);
      final humidities = _toDoubleList(hourly['relative_humidity_2m'] as List?);
      final precipitations = _toDoubleList(hourly['precipitation'] as List?);
      final windSpeeds = _toDoubleList(hourly['wind_speed_10m'] as List?);
      final weatherCodes = (hourly['weather_code'] as List?)?.map((e) => e as int?).toList() ?? [];

      // Group hourly data into daily averages
      final Map<DateTime, List<Map<String, dynamic>>> dailyData = {};

      // Ensure all lists have the same length
      final minLength = [
        times.length,
        temperatures.length,
        humidities.length,
        precipitations.length,
        windSpeeds.length,
        weatherCodes.length,
      ].reduce((a, b) => a < b ? a : b);

      for (int i = 0; i < minLength; i++) {
        final date = DateTime(times[i].year, times[i].month, times[i].day);
        // Skip if we already have current data for today
        if (current != null) {
          final currentDate = DateTime.parse(current['time'] as String);
          if (date.year == currentDate.year &&
              date.month == currentDate.month &&
              date.day == currentDate.day) {
            continue; // Skip today's hourly data since we have current data
          }
        }
        
        if (!dailyData.containsKey(date)) {
          dailyData[date] = [];
        }
        dailyData[date]!.add({
          'temp': temperatures[i],
          'humidity': humidities[i],
          'precipitation': precipitations[i],
          'wind': windSpeeds[i],
          'weather_code': i < weatherCodes.length ? weatherCodes[i] : null,
        });
      }

      dailyData.forEach((date, values) {
        if (values.isEmpty) return;
        
        final avgTemp = values.map((v) => v['temp'] as double).reduce((a, b) => a + b) / values.length;
        final avgHumidity = values.map((v) => v['humidity'] as double).reduce((a, b) => a + b) / values.length;
        final totalPrecip = values.map((v) => v['precipitation'] as double).reduce((a, b) => a + b);
        final avgWind = values.map((v) => v['wind'] as double).reduce((a, b) => a + b) / values.length;
        
        // Get weather code - prefer daily, fallback to most common hourly code
        int? weatherCode = dailyWeatherCodes[date];
        if (weatherCode == null && values.isNotEmpty) {
          final codes = values.map((v) => v['weather_code'] as int?).where((c) => c != null).toList();
          if (codes.isNotEmpty) {
            // Get most common weather code
            final codeCounts = <int, int>{};
            for (final code in codes) {
              codeCounts[code!] = (codeCounts[code] ?? 0) + 1;
            }
            weatherCode = codeCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
          }
        }

        dailyForecast.add(WeatherData(
          temperature: avgTemp,
          humidity: avgHumidity,
          precipitation: totalPrecip,
          windSpeed: avgWind,
          soilTemperature: avgTemp, // Use air temp as fallback
          soilMoisture: 50.0, // Default value
          date: date,
          description: _getWeatherDescription(weatherCode),
          weatherCode: weatherCode,
        ));
      });
    }

    dailyForecast.sort((a, b) => a.date.compareTo(b.date));

    return WeatherForecast(
      dailyForecast: dailyForecast,
      latitude: latitude,
      longitude: longitude,
    );
  }

  String _getWeatherDescription(int? weatherCode) {
    if (weatherCode == null) return 'Unknown';
    
    // WMO Weather interpretation codes (WW)
    if (weatherCode == 0) return 'Clear sky';
    if (weatherCode <= 3) return 'Mainly clear';
    if (weatherCode <= 48) return 'Foggy';
    if (weatherCode <= 49) return 'Depositing rime fog';
    if (weatherCode <= 55) return 'Drizzle';
    if (weatherCode <= 57) return 'Freezing drizzle';
    if (weatherCode <= 65) return 'Rain';
    if (weatherCode <= 67) return 'Freezing rain';
    if (weatherCode <= 77) return 'Snow';
    if (weatherCode <= 82) return 'Rain showers';
    if (weatherCode <= 86) return 'Snow showers';
    if (weatherCode <= 99) return 'Thunderstorm';
    
    return 'Unknown';
  }
}

