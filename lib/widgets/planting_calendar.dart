import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../models/crop.dart';
import '../services/planting_recommendation_service.dart';
import '../services/season_service.dart';

class PlantingCalendar extends StatelessWidget {
  final WeatherForecast forecast;
  final List<Crop> selectedCrops;
  final PlantingRecommendationService recommendationService;

  const PlantingCalendar({
    super.key,
    required this.forecast,
    required this.selectedCrops,
    required this.recommendationService,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedCrops.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today,
                size: 48,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Select crops to see planting calendar',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Get the best score for each day across all selected crops
    final Map<DateTime, double> dayScores = {};
    for (final crop in selectedCrops) {
      final recommendations = recommendationService.getRecommendations(crop, forecast);
      for (final rec in recommendations) {
        final date = DateTime(rec.recommendedDate.year, rec.recommendedDate.month, rec.recommendedDate.day);
        if (!dayScores.containsKey(date) || rec.suitabilityScore > dayScores[date]!) {
          dayScores[date] = rec.suitabilityScore;
        }
      }
    }

    // Also add days with low scores (bad days)
    for (final weather in forecast.dailyForecast) {
      final date = DateTime(weather.date.year, weather.date.month, weather.date.day);
      if (!dayScores.containsKey(date)) {
        // Calculate average score across all crops for this day
        double totalScore = 0.0;
        int count = 0;
        for (final crop in selectedCrops) {
          final score = _calculateSuitabilityScore(crop, weather);
          totalScore += score;
          count++;
        }
        final avgScore = count > 0 ? totalScore / count : 0.0;
        dayScores[date] = avgScore;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Planting Calendar',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCalendarGrid(context, dayScores),
            const SizedBox(height: 16),
            _buildLegend(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context, Map<DateTime, double> dayScores) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);

    // Get all dates in the range (16 days)
    final dates = <DateTime>[];
    for (var i = 0; i < 16; i++) {
      dates.add(startDate.add(Duration(days: i)));
    }

    // Find the first Monday before or on startDate
    // Monday = 1, so we need to go back (weekday - 1) days
    final firstMonday = startDate.subtract(Duration(days: (startDate.weekday - 1) % 7));
    
    // Create a grid starting from the first Monday
    // Calculate how many weeks we need (at least 3 weeks for 16 days)
    final totalDays = 21; // 3 weeks
    final allDays = <DateTime>[];
    for (var i = 0; i < totalDays; i++) {
      allDays.add(firstMonday.add(Duration(days: i)));
    }
    
    // Group into weeks
    final weeks = <List<DateTime>>[];
    for (var i = 0; i < allDays.length; i += 7) {
      weeks.add(allDays.sublist(i, (i + 7 > allDays.length) ? allDays.length : i + 7));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Weekday headers
        Row(
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Calendar days
        ...weeks.map((week) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                children: List.generate(7, (index) {
                  Widget cell;
                  if (index < week.length) {
                    final date = week[index];
                    final isInRange = !date.isBefore(startDate) &&
                        date.isBefore(startDate.add(const Duration(days: 16)));

                    if (!isInRange) {
                      cell = Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${date.day}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                    ),
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      final score = dayScores[date] ?? 0.0;
                      final color = _getDayColor(context, score);
                      final isToday = date.year == now.year &&
                          date.month == now.month &&
                          date.day == now.day;

                      // In-season badge detection for selected crops
                      final phSeason = SeasonService.getPhilippineSeason(date);
                      final inSeason = selectedCrops.any(
                        (crop) => crop.growingSeasons.any(
                          (s) => SeasonService.matchesPhilippineSeason(s, phSeason),
                        ),
                      );

                      cell = Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: Stack(
                            children: [
                              Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(8),
                                  border: isToday
                                      ? Border.all(
                                          color: Theme.of(context).colorScheme.primary,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${date.day}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                              color: _getTextColor(context, color),
                                            ),
                                      ),
                                      if (score > 0)
                                        Text(
                                          '${score.toInt()}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                fontSize: 8,
                                                color: _getTextColor(context, color),
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              if (inSeason)
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: Icon(
                                    Icons.eco,
                                    size: 14,
                                    color: _getTextColor(context, color),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }
                  } else {
                    cell = const Expanded(child: SizedBox());
                  }
                  return cell;
                }),
              ),
            )),
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceAround,
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildLegendItem(context, Colors.green, 'Best (≥80) – In-season ideal'),
        _buildLegendItem(context, Colors.blue, 'Good (≥65)'),
        _buildLegendItem(context, Colors.red, 'Caution (<65)'),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.eco, size: 16),
            const SizedBox(width: 4),
            Text('In-season day'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Color _getDayColor(BuildContext context, double score) {
    if (score >= 80) {
      return Colors.green.withValues(alpha: 0.7);
    } else if (score >= 65) {
      return Colors.blue.withValues(alpha: 0.7);
    } else {
      return Colors.red.withValues(alpha: 0.7);
    }
  }

  Color _getTextColor(BuildContext context, Color backgroundColor) {
    // Calculate luminance to determine if text should be light or dark
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  // Copy of the scoring logic from PlantingRecommendationService
  double _calculateSuitabilityScore(Crop crop, WeatherData weather) {
    final biology = crop.biology;
    double score = 100.0;

    // Temperature score (40% weight)
    double tempScore = 100.0;
    if (weather.temperature < biology.minTemperature ||
        weather.temperature > biology.maxTemperature) {
      tempScore = 40.0; // soften harsh zero
    } else {
      final tempDiff = (weather.temperature - biology.optimalTemperature).abs();
      final tempRange = (biology.maxTemperature - biology.minTemperature).abs();
      final normalized = (tempDiff / (tempRange == 0 ? 1 : tempRange)) * 100.0;
      tempScore = (100.0 - normalized).clamp(40.0, 100.0);
    }
    score = score * 0.4 + tempScore * 0.4;

    // Soil moisture score (30% weight)
    double moistureScore = 100.0;
    if (weather.soilMoisture < biology.minSoilMoisture ||
        weather.soilMoisture > biology.maxSoilMoisture) {
      moistureScore = 60.0; // soften out-of-range
    } else {
      final moistureDiff = (weather.soilMoisture - biology.optimalSoilMoisture).abs();
      final moistureRange = (biology.maxSoilMoisture - biology.minSoilMoisture).abs();
      final normalized = (moistureDiff / (moistureRange == 0 ? 1 : moistureRange)) * 100.0;
      moistureScore = (100.0 - normalized).clamp(60.0, 100.0);
    }
    score = score * 0.3 + moistureScore * 0.3;

    // Precipitation score (20% weight)
    double precipScore = 100.0;
    final monthlyPrecip = weather.precipitation * 30; // Estimate monthly
    if (monthlyPrecip < biology.minRainfall) {
      precipScore = 70.0; // further softened
    } else if (monthlyPrecip > biology.maxRainfall) {
      precipScore = 85.0; // further softened
    }
    score = score * 0.2 + precipScore * 0.2;

    // Soil temperature score (10% weight)
    double soilTempScore = 100.0;
    final soilTempDiff = (weather.soilTemperature - biology.optimalTemperature).abs();
    final soilTempRange = (biology.maxTemperature - biology.minTemperature).abs();
    final normalizedSoil = (soilTempDiff / (soilTempRange == 0 ? 1 : soilTempRange)) * 100.0;
    soilTempScore = (100.0 - normalizedSoil).clamp(50.0, 100.0);
    score = score * 0.1 + soilTempScore * 0.1;

    // Philippine season bonus (up to +12)
    final phSeason = SeasonService.getPhilippineSeason(weather.date);
    final hasMatchingSeason = crop.growingSeasons.any(
      (s) => SeasonService.matchesPhilippineSeason(s, phSeason),
    );
    if (hasMatchingSeason) {
      score = (score + 12).clamp(0.0, 100.0);
    } else {
      score = (score - 1).clamp(0.0, 100.0);
    }

    return score.clamp(0.0, 100.0);
  }
}
