import 'package:flutter/material.dart';
import '../models/weather.dart';
import 'package:intl/intl.dart';

class WeatherCard extends StatelessWidget {
  final WeatherData weather;

  const WeatherCard({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(weather.date),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${weather.temperature.toStringAsFixed(1)}°C',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoItem(
                  context,
                  Icons.water_drop,
                  'Humidity',
                  '${weather.humidity.toStringAsFixed(0)}%',
                ),
                const SizedBox(width: 16),
                _buildInfoItem(
                  context,
                  Icons.cloud,
                  'Rain',
                  '${weather.precipitation.toStringAsFixed(1)}mm',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoItem(
                  context,
                  Icons.air,
                  'Wind',
                  '${weather.windSpeed.toStringAsFixed(1)} km/h',
                ),
                const SizedBox(width: 16),
                _buildInfoItem(
                  context,
                  Icons.thermostat,
                  'Soil Temp',
                  '${weather.soilTemperature.toStringAsFixed(1)}°C',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoItem(
                  context,
                  Icons.water,
                  'Soil Moisture',
                  '${weather.soilMoisture.toStringAsFixed(0)}%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

