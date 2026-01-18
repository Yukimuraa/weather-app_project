import '../models/crop.dart';
import '../models/weather.dart';
import 'season_service.dart';

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

    // Evaluate all days first to support fallback
    final evaluated = <Map<String, dynamic>>[];

    for (final weather in forecast.dailyForecast) {
      final score = _calculateSuitabilityScore(crop, weather);
      evaluated.add({
        'weather': weather,
        'score': score,
      });

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

    // If no recommendations meet the threshold, provide season-aware fallback
    if (recommendations.isEmpty && evaluated.isNotEmpty) {
      // Sort all evaluated days by score (desc)
      evaluated.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

      // Prefer days that match PH season vs crop, otherwise just take top
      final seasonMatched = evaluated.where((e) {
        final w = e['weather'] as WeatherData;
        final currentPh = SeasonService.getPhilippineSeason(w.date);
        return crop.growingSeasons.any((s) => SeasonService.matchesPhilippineSeason(s, currentPh));
      }).toList();

      final fallbackList = seasonMatched.isNotEmpty ? seasonMatched : evaluated;
      final takeCount = fallbackList.length >= 3 ? 3 : fallbackList.length;
      for (int i = 0; i < takeCount; i++) {
        final w = fallbackList[i]['weather'] as WeatherData;
        final s = fallbackList[i]['score'] as double;
        final reason = '${_generateReason(crop, w, s)}, Season-based fallback';
        recommendations.add(PlantingRecommendation(
          crop: crop,
          recommendedDate: w.date,
          suitabilityScore: s,
          reason: reason,
          weatherData: w,
        ));
      }
    }

    // Sort by suitability score (highest first)
    recommendations.sort((a, b) => b.suitabilityScore.compareTo(a.suitabilityScore));

    return recommendations;
  }

  double _calculateSuitabilityScore(Crop crop, WeatherData weather) {
    final biology = crop.biology;

    // Temperature component (70% weight)
    double tempScore;
    if (weather.temperature < biology.minTemperature || weather.temperature > biology.maxTemperature) {
      tempScore = 40.0; // out of range but not a hard zero
    } else {
      final tempDiff = (weather.temperature - biology.optimalTemperature).abs();
      final tempRange = (biology.maxTemperature - biology.minTemperature).abs();
      final normalized = (tempDiff / (tempRange == 0 ? 1 : tempRange)) * 100.0;
      tempScore = (100.0 - normalized).clamp(50.0, 100.0);
    }

    // Precipitation component (30% weight)
    // Approximate monthly precipitation from daily value (mm/day -> mm/month)
    final monthlyPrecip = weather.precipitation * 30.0;
    double precipScore;
    if (monthlyPrecip < biology.minRainfall) {
      // Too dry: penalize proportionally
      final deficit = (biology.minRainfall - monthlyPrecip).clamp(0.0, biology.minRainfall);
      final ratio = deficit / (biology.minRainfall == 0 ? 1 : biology.minRainfall);
      precipScore = (85.0 * (1.0 - ratio)).clamp(40.0, 85.0);
    } else if (monthlyPrecip > biology.maxRainfall) {
      // Too wet: softer penalty
      final excess = (monthlyPrecip - biology.maxRainfall).clamp(0.0, biology.maxRainfall);
      final ratio = excess / (biology.maxRainfall == 0 ? 1 : biology.maxRainfall);
      precipScore = (90.0 * (1.0 - 0.6 * ratio)).clamp(50.0, 90.0);
    } else {
      // Within range: better score if closer to optimal midpoint
      final mid = (biology.minRainfall + biology.maxRainfall) / 2.0;
      final diff = (monthlyPrecip - mid).abs();
      final range = (biology.maxRainfall - biology.minRainfall).abs();
      final normalized = (diff / (range == 0 ? 1 : range)) * 100.0;
      precipScore = (100.0 - normalized).clamp(70.0, 100.0);
    }

    // Weighted aggregate using only temperature and precipitation
    final score = (tempScore * 0.7) + (precipScore * 0.3);

    // Note: Philippine season is shown in reasons but not used in score per requirement
    return score.clamp(0.0, 100.0);
  }

  String _generateReason(Crop crop, WeatherData weather, double score) {
    final reasons = <String>[];
    final biology = crop.biology;

    // Temperature reason
    if ((weather.temperature - biology.optimalTemperature).abs() <= 2) {
      reasons.add('Near-optimal temperature');
    } else if (weather.temperature >= biology.minTemperature && weather.temperature <= biology.maxTemperature) {
      reasons.add('Temperature within range');
    } else {
      reasons.add('Temperature outside range');
    }

    // Precipitation reason (based on monthly estimate)
    final monthlyPrecip = weather.precipitation * 30.0;
    if (monthlyPrecip >= biology.minRainfall && monthlyPrecip <= biology.maxRainfall) {
      reasons.add('Rainfall within range');
    } else if (monthlyPrecip < biology.minRainfall) {
      reasons.add('Too dry');
    } else {
      reasons.add('Too wet');
    }

    // Season context (informational)
    final phSeason = SeasonService.getPhilippineSeason(weather.date);
    final matches = crop.growingSeasons.any(
      (s) => SeasonService.matchesPhilippineSeason(s, phSeason),
    );
    reasons.add(matches ? 'In-season for Philippines ($phSeason)' : 'Off-season for Philippines ($phSeason)');

    // Overall condition label
    if (score >= 80) {
      reasons.add('Excellent conditions');
    } else if (score >= 65) {
      reasons.add('Good conditions');
    } else if (score >= 50) {
      reasons.add('Fair conditions');
    } else {
      reasons.add('Poor conditions');
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

class MonthSummary {
  final int month; // 1-12
  final double averageScore; // 0-100
  final String category; // Best, Good, Caution

  MonthSummary({required this.month, required this.averageScore, required this.category});
}

extension PlantingRecommendationMonthly on PlantingRecommendationService {
  List<MonthSummary> getMonthlyPlantingSummary(Crop crop, WeatherForecast forecast) {
    // Aggregate scores by month
    final Map<int, List<double>> monthScores = {};
    for (final weather in forecast.dailyForecast) {
      final m = weather.date.month;
      final score = _calculateSuitabilityScore(crop, weather);
      monthScores.putIfAbsent(m, () => []).add(score);
    }

    // Compute averages and categorize
    final List<MonthSummary> summaries = [];
    for (final entry in monthScores.entries) {
      final month = entry.key;
      final scores = entry.value;
      if (scores.isEmpty) continue;
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      String category;
      if (avg >= 80) {
        category = 'Best';
      } else if (avg >= 65) {
        category = 'Good';
      } else {
        category = 'Caution';
      }
      summaries.add(MonthSummary(month: month, averageScore: avg, category: category));
    }

    // Sort by calendar order starting from current month
    summaries.sort((a, b) => a.month.compareTo(b.month));
    return summaries;
  }
}
