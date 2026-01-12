import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/weather.dart';

class WeatherChart extends StatelessWidget {
  final List<WeatherData> weatherData;
  final String title;

  const WeatherChart({
    super.key,
    required this.weatherData,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (weatherData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Theme.of(context).dividerColor,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: weatherData.length > 7 ? 2 : 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= weatherData.length) {
                            return const Text('');
                          }
                          final date = weatherData[value.toInt()].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '${date.day}/${date.month}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  minX: 0,
                  maxX: (weatherData.length - 1).toDouble(),
                  minY: _getMinY(),
                  maxY: _getMaxY(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: weatherData.asMap().entries.map((e) {
                        return FlSpot(
                          e.key.toDouble(),
                          _getChartValue(e.value),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getChartValue(WeatherData weather) {
    switch (title.toLowerCase()) {
      case 'temperature':
        return weather.temperature;
      case 'humidity':
        return weather.humidity;
      case 'precipitation':
        return weather.precipitation;
      case 'soil moisture':
        return weather.soilMoisture;
      default:
        return weather.temperature;
    }
  }

  double _getMinY() {
    switch (title.toLowerCase()) {
      case 'temperature':
        return weatherData.map((w) => w.temperature).reduce((a, b) => a < b ? a : b) - 5;
      case 'humidity':
        return 0;
      case 'precipitation':
        return 0;
      case 'soil moisture':
        return 0;
      default:
        return 0;
    }
  }

  double _getMaxY() {
    switch (title.toLowerCase()) {
      case 'temperature':
        return weatherData.map((w) => w.temperature).reduce((a, b) => a > b ? a : b) + 5;
      case 'humidity':
        return 100;
      case 'precipitation':
        return weatherData.map((w) => w.precipitation).reduce((a, b) => a > b ? a : b) + 5;
      case 'soil moisture':
        return 100;
      default:
        return 50;
    }
  }
}

