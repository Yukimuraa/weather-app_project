import '../models/crop.dart';
import '../models/weather.dart';

class PlantingRecommendationService {
  static final PlantingRecommendationService _instance =
      PlantingRecommendationService._internal();
  factory PlantingRecommendationService() => _instance;
  PlantingRecommendationService._internal();

  List<PlantingRecommendation> getRecommendations(
    Crop crop,
    WeatherForecast forecast,
  ) {
    final recommendations = <PlantingRecommendation>[];

    for (final weather in forecast.dailyForecast) {
      final score = _calculateSuitabilityScore(crop, weather);
      
      if (score >= 60) {
        recommendations.add(PlantingRecommendation(
          crop: crop,
          recommendedDate: weather.date,
          suitabilityScore: score,
          reason: _generateReason(crop, weather, score),
          weatherData: weather,
        ));
      }
    }

    // Sort by suitability score (highest first)
    recommendations.sort((a, b) => b.suitabilityScore.compareTo(a.suitabilityScore));

    return recommendations;
  }

  double _calculateSuitabilityScore(Crop crop, WeatherData weather) {
    final biology = crop.biology;
    double score = 100.0;

    // Temperature score (40% weight)
    double tempScore = 100.0;
    if (weather.temperature < biology.minTemperature ||
        weather.temperature > biology.maxTemperature) {
      tempScore = 0.0;
    } else {
      final tempDiff = (weather.temperature - biology.optimalTemperature).abs();
      final tempRange = biology.maxTemperature - biology.minTemperature;
      tempScore = 100.0 - (tempDiff / tempRange * 100.0);
      if (tempScore < 0) tempScore = 0;
    }
    score = score * 0.4 + tempScore * 0.4;

    // Soil moisture score (30% weight)
    double moistureScore = 100.0;
    if (weather.soilMoisture < biology.minSoilMoisture ||
        weather.soilMoisture > biology.maxSoilMoisture) {
      moistureScore = 50.0;
    } else {
      final moistureDiff = (weather.soilMoisture - biology.optimalSoilMoisture).abs();
      final moistureRange = biology.maxSoilMoisture - biology.minSoilMoisture;
      moistureScore = 100.0 - (moistureDiff / moistureRange * 100.0);
      if (moistureScore < 0) moistureScore = 0;
    }
    score = score * 0.3 + moistureScore * 0.3;

    // Precipitation score (20% weight)
    double precipScore = 100.0;
    final monthlyPrecip = weather.precipitation * 30; // Estimate monthly
    if (monthlyPrecip < biology.minRainfall) {
      precipScore = 50.0;
    } else if (monthlyPrecip > biology.maxRainfall) {
      precipScore = 70.0;
    }
    score = score * 0.2 + precipScore * 0.2;

    // Soil temperature score (10% weight)
    double soilTempScore = 100.0;
    final soilTempDiff = (weather.soilTemperature - biology.optimalTemperature).abs();
    final soilTempRange = biology.maxTemperature - biology.minTemperature;
    soilTempScore = 100.0 - (soilTempDiff / soilTempRange * 100.0);
    if (soilTempScore < 0) soilTempScore = 0;
    score = score * 0.1 + soilTempScore * 0.1;

    return score.clamp(0.0, 100.0);
  }

  String _generateReason(Crop crop, WeatherData weather, double score) {
    final reasons = <String>[];
    final biology = crop.biology;

    if ((weather.temperature - biology.optimalTemperature).abs() < 3) {
      reasons.add('Optimal temperature');
    }

    if ((weather.soilMoisture - biology.optimalSoilMoisture).abs() < 5) {
      reasons.add('Good soil moisture');
    }

    if (weather.precipitation > 0 && weather.precipitation < 10) {
      reasons.add('Adequate rainfall expected');
    }

    if (score >= 85) {
      reasons.add('Excellent conditions');
    } else if (score >= 70) {
      reasons.add('Good conditions');
    } else {
      reasons.add('Acceptable conditions');
    }

    return reasons.join(', ');
  }

  PlantingRecommendation? getBestRecommendation(
    Crop crop,
    WeatherForecast forecast,
  ) {
    final recommendations = getRecommendations(crop, forecast);
    if (recommendations.isEmpty) return null;
    return recommendations.first;
  }
}

