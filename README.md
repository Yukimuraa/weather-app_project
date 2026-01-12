# Weather Crops App

A Free and Open Source Software (FOSS) mobile application designed to help farmers make informed decisions about when to plant their crops based on weather data and crop biological requirements.

## Features

- **Weather Integration**: Real-time weather data from Open Meteo API including:
  - Temperature forecasts
  - Humidity levels
  - Precipitation forecasts
  - Wind speed
  - Soil temperature and moisture

- **Crops Dictionary**: Comprehensive database of crops with:
  - Biological requirements (temperature, soil moisture, rainfall, pH, etc.)
  - Growing seasons
  - Days to maturity
  - Scientific names and descriptions

- **Planting Recommendations**: AI-powered recommendations that analyze:
  - Weather forecasts
  - Crop biological requirements
  - Optimal planting dates
  - Suitability scores (0-100)

- **Local Notifications**: Get notified about the best planting dates for your selected crops

- **Beautiful Dashboard**: Interactive charts using FL Chart showing:
  - Temperature trends
  - Humidity patterns
  - Precipitation forecasts
  - Soil moisture levels

- **Dark Mode**: Toggle between light and dark themes for comfortable viewing

- **Location-Based**: Uses your device's location to provide personalized weather forecasts

## Supported Crops

The app includes data for 20+ crops including:
- Vegetables: Tomato, Potato, Carrot, Onion, Cabbage, Pepper, Cucumber, Lettuce, Spinach, Broccoli, Eggplant, Squash, Radish, Cauliflower
- Grains: Corn, Rice, Wheat
- Legumes: Green Beans, Peas
- And more...

## Technology Stack

- **Framework**: Flutter
- **Weather API**: Open Meteo API
- **Charts**: FL Chart
- **State Management**: Provider
- **Local Storage**: Shared Preferences
- **Notifications**: Flutter Local Notifications
- **Location**: Geolocator

## Getting Started

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Permissions

The app requires the following permissions:
- Location (for weather forecasts)
- Notifications (for planting alerts)

## License

This project is licensed as Free and Open Source Software (FOSS).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgments

- Open Meteo for providing free weather API
- Flutter community for excellent packages
- All contributors and farmers who help improve this app
