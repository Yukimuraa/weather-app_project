class WeatherData {
  final double temperature;
  final double humidity;
  final double precipitation;
  final double windSpeed;
  final double soilTemperature;
  final double soilMoisture;
  final DateTime date;
  final String? description;
  final int? weatherCode;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.precipitation,
    required this.windSpeed,
    required this.soilTemperature,
    required this.soilMoisture,
    required this.date,
    this.description,
    this.weatherCode,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json, DateTime date) {
    return WeatherData(
      temperature: (json['temperature_2m'] ?? 0.0).toDouble(),
      humidity: (json['relative_humidity_2m'] ?? 0.0).toDouble(),
      precipitation: (json['precipitation'] ?? 0.0).toDouble(),
      windSpeed: (json['wind_speed_10m'] ?? 0.0).toDouble(),
      soilTemperature: (json['soil_temperature_0cm'] ?? json['temperature_2m'] ?? 0.0).toDouble(),
      soilMoisture: (json['soil_moisture_0_1cm'] ?? 0.0).toDouble(),
      date: date,
    );
  }
}

class WeatherForecast {
  final List<WeatherData> dailyForecast;
  final double latitude;
  final double longitude;

  WeatherForecast({
    required this.dailyForecast,
    required this.latitude,
    required this.longitude,
  });
}

