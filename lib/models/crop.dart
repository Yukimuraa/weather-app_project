import 'weather.dart';

class Crop {
  final String id;
  final String name;
  final String scientificName;
  final String category; // Vegetable, Fruit, Grain, Legume, etc.
  final String description;
  final CropBiology biology;
  final List<String> growingSeasons;
  final String imageUrl;

  Crop({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.category,
    required this.description,
    required this.biology,
    required this.growingSeasons,
    this.imageUrl = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'scientificName': scientificName,
      'category': category,
      'description': description,
      'biology': biology.toJson(),
      'growingSeasons': growingSeasons,
      'imageUrl': imageUrl,
    };
  }

  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop(
      id: json['id'],
      name: json['name'],
      scientificName: json['scientificName'],
      category: json['category'],
      description: json['description'],
      biology: CropBiology.fromJson(json['biology']),
      growingSeasons: List<String>.from(json['growingSeasons']),
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}

class CropBiology {
  final double minTemperature; // Celsius
  final double maxTemperature; // Celsius
  final double optimalTemperature; // Celsius
  final double minSoilMoisture; // Percentage
  final double maxSoilMoisture; // Percentage
  final double optimalSoilMoisture; // Percentage
  final int daysToMaturity; // Days from planting to harvest
  final int germinationDays; // Days for seed germination
  final double minRainfall; // mm per month
  final double maxRainfall; // mm per month
  final String soilType; // Sandy, Loamy, Clay, etc.
  final double phMin;
  final double phMax;
  final double optimalPh;
  final int sunlightHours; // Hours of sunlight needed per day

  CropBiology({
    required this.minTemperature,
    required this.maxTemperature,
    required this.optimalTemperature,
    required this.minSoilMoisture,
    required this.maxSoilMoisture,
    required this.optimalSoilMoisture,
    required this.daysToMaturity,
    required this.germinationDays,
    required this.minRainfall,
    required this.maxRainfall,
    required this.soilType,
    required this.phMin,
    required this.phMax,
    required this.optimalPh,
    required this.sunlightHours,
  });

  Map<String, dynamic> toJson() {
    return {
      'minTemperature': minTemperature,
      'maxTemperature': maxTemperature,
      'optimalTemperature': optimalTemperature,
      'minSoilMoisture': minSoilMoisture,
      'maxSoilMoisture': maxSoilMoisture,
      'optimalSoilMoisture': optimalSoilMoisture,
      'daysToMaturity': daysToMaturity,
      'germinationDays': germinationDays,
      'minRainfall': minRainfall,
      'maxRainfall': maxRainfall,
      'soilType': soilType,
      'phMin': phMin,
      'phMax': phMax,
      'optimalPh': optimalPh,
      'sunlightHours': sunlightHours,
    };
  }

  factory CropBiology.fromJson(Map<String, dynamic> json) {
    return CropBiology(
      minTemperature: (json['minTemperature'] ?? 0.0).toDouble(),
      maxTemperature: (json['maxTemperature'] ?? 0.0).toDouble(),
      optimalTemperature: (json['optimalTemperature'] ?? 0.0).toDouble(),
      minSoilMoisture: (json['minSoilMoisture'] ?? 0.0).toDouble(),
      maxSoilMoisture: (json['maxSoilMoisture'] ?? 0.0).toDouble(),
      optimalSoilMoisture: (json['optimalSoilMoisture'] ?? 0.0).toDouble(),
      daysToMaturity: json['daysToMaturity'] ?? 0,
      germinationDays: json['germinationDays'] ?? 0,
      minRainfall: (json['minRainfall'] ?? 0.0).toDouble(),
      maxRainfall: (json['maxRainfall'] ?? 0.0).toDouble(),
      soilType: json['soilType'] ?? 'Loamy',
      phMin: (json['phMin'] ?? 6.0).toDouble(),
      phMax: (json['phMax'] ?? 7.0).toDouble(),
      optimalPh: (json['optimalPh'] ?? 6.5).toDouble(),
      sunlightHours: json['sunlightHours'] ?? 8,
    );
  }
}

class PlantingRecommendation {
  final Crop crop;
  final DateTime recommendedDate;
  final double suitabilityScore; // 0-100
  final String reason;
  final WeatherData weatherData;

  PlantingRecommendation({
    required this.crop,
    required this.recommendedDate,
    required this.suitabilityScore,
    required this.reason,
    required this.weatherData,
  });
}

