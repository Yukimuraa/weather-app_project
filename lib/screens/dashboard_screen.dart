import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/weather.dart';
import '../models/crop.dart';
import '../services/weather_service.dart';
import '../services/crop_data_service.dart';
import '../services/planting_recommendation_service.dart';
import '../services/notification_service.dart';
import '../widgets/weather_card.dart';
import '../widgets/weather_chart.dart';
import '../widgets/planting_recommendation_card.dart';
import '../widgets/planting_calendar.dart';
import '../widgets/horizontal_forecast.dart';
import 'crops_dictionary_screen.dart';
import 'crop_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final WeatherService _weatherService = WeatherService();
  final CropDataService _cropService = CropDataService();
  final PlantingRecommendationService _recommendationService =
      PlantingRecommendationService();
  final NotificationService _notificationService = NotificationService();

  // Default location: 10.7483° N, 122.9801° E (Philippines)
  static const double _defaultLatitude = 10.7483;
  static const double _defaultLongitude = 122.9801;

  WeatherForecast? _forecast;
  List<PlantingRecommendation> _recommendations = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  Position? _position;
  bool _usingDefaultLocation = false;
  List<Crop> _selectedCrops = [];

  @override
  void initState() {
    super.initState();
    _cropService.initializeCrops();
    // Delay loading to ensure widget is built first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWeatherData();
    });
  }

  Future<void> _loadWeatherData() async {
    if (!mounted) return;
    
    // Check internet connectivity FIRST before showing loading
    try {
      final List<ConnectivityResult> connectivityResult =
          await Connectivity().checkConnectivity();
      final bool hasConnection = connectivityResult
          .any((result) => result != ConnectivityResult.none);

      if (!hasConnection) {
        if (!mounted) return;
        
        // Set error state without loading
        setState(() {
          _isLoading = false;
          _error =
              'Weather data couldn’t be loaded.\nPlease check your internet connection.';
        });

        // Show a popup warning about no internet connection
        if (mounted) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No Internet Connection',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: const SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Weather data couldn’t be loaded.\nPlease check your internet connection.'),
                    SizedBox(height: 16),
                    Text(
                      'Error Handling Instructions:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• Check internet connection if errors occur.'),
                    Text('• Ensure Wi‑Fi or mobile data is turned on.'),
                    Text('• Retry failed actions if network interruptions happen.'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _loadWeatherData();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
          
          // Show in-app notification after dialog is dismissed
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Weather data couldn’t be loaded. Please check your internet connection.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () {
                    _loadWeatherData();
                  },
                ),
              ),
            );
          }
        }

        return;
      }
    } catch (e) {
      // If connectivity check fails, assume no connection
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Unable to check internet connection. Please check your network settings.';
      });
      
      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.red),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Connection Error',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: const SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Unable to verify internet connection. Please check your network settings.'),
                  SizedBox(height: 16),
                  Text(
                    'Error Handling Instructions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Check internet connection if errors occur.'),
                  Text('• Ensure Wi‑Fi or mobile data is turned on.'),
                  Text('• Retry failed actions if network interruptions happen.'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _loadWeatherData();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Only show full-screen loading if we have no data yet.
    if (!mounted) return;
    setState(() {
      _error = null;
      _usingDefaultLocation = false;
      if (_forecast == null) {
        _isLoading = true;
      } else {
        _isRefreshing = true;
      }
    });

    double latitude = _defaultLatitude;
    double longitude = _defaultLongitude;

    try {

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Use default location and warn the user
        _usingDefaultLocation = true;

        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.location_off, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'GPS is Turned Off',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: const SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Your device GPS/location is turned off. The app will use a default location, which may not match your actual farm location.'),
                    SizedBox(height: 16),
                    Text(
                      'Tip:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                        'Enable GPS/location services in your device settings for more accurate weather data and planting recommendations.'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          
          // Show in-app notification after dialog is dismissed
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.location_off, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'GPS is turned off. Using default location.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        }
      } else {
        // Check location permissions
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            // Use default location and warn the user
            _usingDefaultLocation = true;

            if (mounted) {
              await showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.location_off, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Location Permission Denied',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  content: const SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Location permission was denied. The app will use a default location, which may not match your actual farm location.'),
                        SizedBox(height: 16),
                        Text(
                          'Tip:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                            'You can enable location permission in your device settings for more accurate data.'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
              
              // Show in-app notification after dialog is dismissed
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.location_off, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'GPS permission denied. Using default location.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 5),
                    action: SnackBarAction(
                      label: 'OK',
                      textColor: Colors.white,
                      onPressed: () {},
                    ),
                  ),
                );
              }
            }
          }
        }

        if (permission == LocationPermission.deniedForever) {
          // Use default location and warn the user
          _usingDefaultLocation = true;

          if (mounted) {
            await showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.location_off, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Location Permission Permanently Denied',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                content: const SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Location permission is permanently denied. The app will always use a default location unless you change this in system settings.'),
                      SizedBox(height: 16),
                      Text(
                        'Tip:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                          'Open your device settings, go to App Permissions, and enable location access for this app.'),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
            
            // Show in-app notification after dialog is dismissed
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.location_off, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'GPS permission permanently denied. Using default location.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'OK',
                    textColor: Colors.white,
                    onPressed: () {},
                  ),
                ),
              );
            }
          }
        } else if (permission == LocationPermission.whileInUse ||
                   permission == LocationPermission.always) {
          // Try to get current position with timeout
          try {
            // First try last known position (fast), then try current with a shorter timeout.
            _position = await Geolocator.getLastKnownPosition();
            _position ??= await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 4),
            );
            latitude = _position!.latitude;
            longitude = _position!.longitude;
            _usingDefaultLocation = false;
          } catch (e) {
            // If GPS fails, use default location
            _usingDefaultLocation = true;
          }
        }
      }

      // Load weather data with GPS or default location
      final forecast = await _weatherService.getWeatherForecast(
        latitude,
        longitude,
        forceRefresh: _forecast == null ? false : true,
      );

      if (!mounted) return;
      setState(() {
        _forecast = forecast;
        _isLoading = false;
        _isRefreshing = false;
        if (_usingDefaultLocation) {
          _error =
              'Using default location (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}). Enable GPS for accurate location.';
        }
      });

      _updateRecommendations();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load weather data: ${e.toString()}';
        _isLoading = false;
        _isRefreshing = false;
      });

      // Show a popup warning when weather data fails to load (likely no internet)
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cloud_off, color: Colors.red),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Unable to Load Weather',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.toString(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                const Text(
                  'This often happens when there is no internet connection or the weather service is unreachable.',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error Handling Instructions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('• Check internet connection if errors occur.'),
                const Text('• Ensure Wi‑Fi or mobile data is turned on.'),
                const Text('• Retry failed actions if network interruptions happen.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _loadWeatherData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  void _updateRecommendations() {
    if (_forecast == null || _selectedCrops.isEmpty) return;

    final allRecommendations = <PlantingRecommendation>[];
    for (final crop in _selectedCrops) {
      final recommendations =
          _recommendationService.getRecommendations(crop, _forecast!);
      allRecommendations.addAll(recommendations);
    }

    // Sort by date and score
    allRecommendations.sort((a, b) {
      if (a.recommendedDate.isBefore(b.recommendedDate)) return -1;
      if (a.recommendedDate.isAfter(b.recommendedDate)) return 1;
      return b.suitabilityScore.compareTo(a.suitabilityScore);
    });

    setState(() {
      _recommendations = allRecommendations.take(5).toList();
    });

    // Create in-app notifications for best recommendations
    _createNotifications();
  }

  Future<void> _createNotifications() async {
    for (final recommendation in _recommendations.take(3)) {
      if (recommendation.suitabilityScore >= 75) {
        await _notificationService.createPlantingNotification(
          recommendation.crop,
          recommendation.recommendedDate,
          recommendation.reason,
        );
      }
    }
  }

  Future<void> _selectCrops() async {
    final selected = await Navigator.push<List<Crop>>(
      context,
      MaterialPageRoute(
        builder: (context) => const CropsDictionaryScreen(selectMode: true),
      ),
    );

    if (selected != null && selected.isNotEmpty) {
      setState(() {
        _selectedCrops = selected;
      });
      _updateRecommendations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeatherData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _forecast == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadWeatherData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadWeatherData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isRefreshing) ...[
                          const LinearProgressIndicator(),
                          const SizedBox(height: 12),
                        ],
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Location',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _usingDefaultLocation ? 'Default Location' : 'Current Location',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                            Text(
                                              _position != null
                                                  ? '${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}'
                                                  : '${_defaultLatitude.toStringAsFixed(4)}, ${_defaultLongitude.toStringAsFixed(4)}',
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                            if (_usingDefaultLocation)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4.0),
                                                child: Text(
                                                  'GPS unavailable - using default',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: Theme.of(context).colorScheme.primary,
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _loadWeatherData,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Refresh Location & Weather'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_forecast != null && _forecast!.dailyForecast.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          HorizontalForecast(forecast: _forecast!.dailyForecast),
                          const SizedBox(height: 16),
                          WeatherCard(weather: _forecast!.dailyForecast.first),
                          const SizedBox(height: 16),
                          WeatherChart(
                            weatherData: _forecast!.dailyForecast.take(7).toList(),
                            title: 'Temperature',
                          ),
                          const SizedBox(height: 16),
                          WeatherChart(
                            weatherData: _forecast!.dailyForecast.take(7).toList(),
                            title: 'Humidity',
                          ),
                          const SizedBox(height: 16),
                          WeatherChart(
                            weatherData: _forecast!.dailyForecast.take(7).toList(),
                            title: 'Precipitation',
                          ),
                          const SizedBox(height: 16),
                          WeatherChart(
                            weatherData: _forecast!.dailyForecast.take(7).toList(),
                            title: 'Soil Moisture',
                          ),
                          const SizedBox(height: 16),
                          PlantingCalendar(
                            forecast: _forecast!,
                            selectedCrops: _selectedCrops,
                            recommendationService: _recommendationService,
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Planting Recommendations',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: _selectCrops,
                              icon: const Icon(Icons.add),
                              label: Text(
                                _selectedCrops.isEmpty
                                    ? 'Select'
                                    : '${_selectedCrops.length}',
                              ),
                            ),
                          ],
                        ),
                        if (_selectedCrops.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.agriculture,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Select crops to get planting recommendations',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _selectCrops,
                                    icon: const Icon(Icons.search),
                                    label: const Text('Browse Crops'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._recommendations.map(
                            (rec) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CropDetailsScreen(
                                        crop: rec.crop,
                                      ),
                                    ),
                                  );
                                },
                                child: PlantingRecommendationCard(
                                  crop: rec.crop,
                                  recommendedDate: rec.recommendedDate,
                                  suitabilityScore: rec.suitabilityScore,
                                  reason: rec.reason,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
