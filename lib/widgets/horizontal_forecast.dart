import 'package:flutter/material.dart';
import '../models/weather.dart';
import 'package:intl/intl.dart';

class HorizontalForecast extends StatelessWidget {
  final List<WeatherData> forecast;

  const HorizontalForecast({
    super.key,
    required this.forecast,
  });

  @override
  Widget build(BuildContext context) {
    // Take first 7 days
    final sevenDayForecast = forecast.take(7).toList();

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
                  Icons.calendar_view_week,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '7-Day Forecast',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: sevenDayForecast.length,
                itemBuilder: (context, index) {
                  final weather = sevenDayForecast[index];
                  return _buildForecastCard(context, weather);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastCard(BuildContext context, WeatherData weather) {
    final color = _getWeatherColor(weather.weatherCode);
    final isToday = _isToday(weather.date);
    final textColor = _getTextColor(color);

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: isToday
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? 'Today' : DateFormat('EEE').format(weather.date),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd').format(weather.date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textColor.withValues(alpha: 0.8),
                      ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather.temperature.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '°C',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textColor,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (weather.description != null)
                  Text(
                    weather.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textColor.withValues(alpha: 0.9),
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWeatherInfo(context, Icons.water_drop, '${weather.humidity.toStringAsFixed(0)}%', textColor),
                const SizedBox(height: 4),
                _buildWeatherInfo(context, Icons.cloud, '${weather.precipitation.toStringAsFixed(1)}mm', textColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherInfo(BuildContext context, IconData icon, String value, Color textColor) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: textColor.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textColor.withValues(alpha: 0.8),
              ),
        ),
      ],
    );
  }

  Color _getWeatherColor(int? weatherCode) {
    if (weatherCode == null) {
      return Colors.grey.shade300;
    }

    // Clear sky (Open-Meteo code 0) - dark green #14532D
    if (weatherCode == 0) {
      return const Color(0xFF14532D);
    }
    // Mainly clear to overcast skies (codes 1–3) - deep olive #365314
    if (weatherCode >= 1 && weatherCode <= 3) {
      return const Color(0xFF365314);
    }
    // Fog and rime fog (codes 45–48) - dark amber #854D0E
    if (weatherCode >= 45 && weatherCode <= 48) {
      return const Color(0xFF854D0E);
    }
    // Drizzle of all intensities (codes 51–57) - burnt orange #9A3412
    if (weatherCode >= 51 && weatherCode <= 57) {
      return const Color(0xFF9A3412);
    }
    // Rain and freezing rain (codes 61–67) - deep orange #C2410C
    if (weatherCode >= 61 && weatherCode <= 67) {
      return const Color(0xFFC2410C);
    }
    // Snowfall and snow grains (codes 71–77) - dark red #991B1B
    if (weatherCode >= 71 && weatherCode <= 77) {
      return const Color(0xFF991B1B);
    }
    // Rain or snow showers (codes 80–82 and 85–86) - crimson #7F1D1D
    if ((weatherCode >= 80 && weatherCode <= 82) || (weatherCode >= 85 && weatherCode <= 86)) {
      return const Color(0xFF7F1D1D);
    }
    // Thunderstorms without hail (code 95) - very dark maroon #4C0519
    if (weatherCode == 95) {
      return const Color(0xFF4C0519);
    }
    // Thunderstorms with hail (codes 96–99) - near-black red #2A020F
    if (weatherCode >= 96 && weatherCode <= 99) {
      return const Color(0xFF2A020F);
    }
    // Catastrophic or system-override conditions - pure black #000000
    if (weatherCode >= 100) {
      return const Color(0xFF000000);
    }

    // Default for unhandled codes (4-44, 49-50, 58-60, 68-70, 78-79, 83-84, 87-94)
    return Colors.grey.shade400;
  }

  Color _getTextColor(Color backgroundColor) {
    // Calculate luminance to determine if text should be light or dark
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

