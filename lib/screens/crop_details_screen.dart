import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/crop.dart';
import '../services/weather_service.dart';
import '../services/planting_recommendation_service.dart';
import '../services/notification_service.dart';
import '../widgets/planting_recommendation_card.dart';
import '../services/season_service.dart';
import '../models/weather.dart';

class CropDetailsScreen extends StatefulWidget {
  final Crop crop;

  const CropDetailsScreen({super.key, required this.crop});

  @override
  State<CropDetailsScreen> createState() => _CropDetailsScreenState();
}

class _CropDetailsScreenState extends State<CropDetailsScreen> {
  final WeatherService _weatherService = WeatherService();
  final PlantingRecommendationService _recommendationService =
      PlantingRecommendationService();
  final NotificationService _notificationService = NotificationService();

  // Default location: Talisay City, Negros Occidental (Philippines)
  // Approx coordinates: 10.7350° N, 122.9670° E
  static const double _defaultLatitude = 10.7350;
  static const double _defaultLongitude = 122.9670;

  List<PlantingRecommendation> _recommendations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
    });

    double latitude = _defaultLatitude;
    double longitude = _defaultLongitude;

    try {
      // Try to get GPS location, fallback to default if unavailable
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          try {
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 10),
            );
            latitude = position.latitude;
            longitude = position.longitude;
          } catch (e) {
            // Use default location if GPS fails
          }
        }
      }

      final forecast = await _weatherService.getWeatherForecast(
        latitude,
        longitude,
      );

      final recommendations =
          _recommendationService.getRecommendations(widget.crop, forecast);

      if (!mounted) return;
      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });

      // Create in-app notification for best recommendation
      if (recommendations.isNotEmpty && recommendations.first.suitabilityScore >= 75) {
        await _notificationService.createPlantingNotification(
          widget.crop,
          recommendations.first.recommendedDate,
          recommendations.first.reason,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final biology = widget.crop.biology;
    final phSeasonNow = SeasonService.getPhilippineSeason(DateTime.now());
    final phSeasonsForCrop = SeasonService.mapSeasonsToPhilippines(widget.crop.growingSeasons);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.crop.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.crop.name,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.crop.scientificName,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.crop.category,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.crop.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Biological Requirements',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              context,
              'Temperature',
              '${biology.minTemperature}°C - ${biology.maxTemperature}°C',
              'Optimal: ${biology.optimalTemperature}°C',
              Icons.thermostat,
            ),
            _buildInfoCard(
              context,
              'Soil Moisture',
              '${biology.minSoilMoisture}% - ${biology.maxSoilMoisture}%',
              'Optimal: ${biology.optimalSoilMoisture}%',
              Icons.water_drop,
            ),
            _buildInfoCard(
              context,
              'Rainfall',
              '${biology.minRainfall}mm - ${biology.maxRainfall}mm per month',
              '',
              Icons.cloud,
            ),
            _buildInfoCard(
              context,
              'Soil Type',
              biology.soilType,
              'pH: ${biology.phMin} - ${biology.phMax} (Optimal: ${biology.optimalPh})',
              Icons.landscape,
            ),
            _buildInfoCard(
              context,
              'Sunlight',
              '${biology.sunlightHours} hours per day',
              '',
              Icons.wb_sunny,
            ),
            _buildInfoCard(
              context,
              'Growth Period',
              '${biology.germinationDays} days to germinate',
              '${biology.daysToMaturity} days to maturity',
              Icons.timeline,
            ),
            const SizedBox(height: 16),
            Text(
              'Growing Seasons',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: phSeasonsForCrop.map(
                (season) => Chip(
                  label: Text(season),
                  avatar: Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.wb_sunny_outlined),
                const SizedBox(width: 6),
                Text('Current PH Season: $phSeasonNow'),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Planting Recommendations',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_recommendations.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No recommendations available.\nEnable location to get personalized recommendations.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._recommendations.take(5).map(
                    (rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PlantingRecommendationCard(
                        crop: rec.crop,
                        recommendedDate: rec.recommendedDate,
                        suitabilityScore: rec.suitabilityScore,
                        reason: rec.reason,
                      ),
                    ),
                  ),
            const SizedBox(height: 24),
            Text(
              'Monthly Planting Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<WeatherForecast>(
              future: _weatherService.getWeatherForecast(_defaultLatitude, _defaultLongitude),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return Text(
                    'Unable to load monthly summary',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }
                final forecast = snapshot.data!;
                final summaries = _recommendationService.getMonthlyPlantingSummary(widget.crop, forecast);
                if (summaries.isEmpty) {
                  return Text(
                    'No monthly data available from forecast window',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: summaries.map((s) {
                    final label = _monthName(s.month);
                    final color = _summaryColor(context, s.category);
                    final onColor = _summaryOnColor(context, color);
                    return Chip(
                      label: Text('$label: ${s.category} (${s.averageScore.toStringAsFixed(0)})',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: onColor)),
                      avatar: Icon(Icons.calendar_month, color: onColor, size: 18),
                      backgroundColor: color.withValues(alpha: 0.15),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'January','February','March','April','May','June','July','August','September','October','November','December'
    ];
    return names[(month - 1).clamp(0, 11)];
  }

  Color _summaryColor(BuildContext context, String category) {
    switch (category) {
      case 'Best':
        return Colors.green;
      case 'Good':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  Color _summaryOnColor(BuildContext context, Color bg) {
    return bg.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}