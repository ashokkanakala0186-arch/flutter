class WeatherData {
  const WeatherData({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.time,
    required this.latitude,
    required this.longitude,
    this.dailyMaxTemp,
    this.dailyMinTemp,
    this.precipitationMm,
    this.rainChancePercent,
  });

  final double temperature;
  final double humidity;
  final double windSpeed;
  final int weatherCode;
  final String time;
  final double latitude;
  final double longitude;
  final double? dailyMaxTemp;
  final double? dailyMinTemp;
  final double? precipitationMm;
  final double? rainChancePercent;

  String get condition => WeatherCondition.label(weatherCode);

  String get conditionEmoji => WeatherCondition.emoji(weatherCode);

  bool get isRaining => WeatherCondition.isRaining(weatherCode);

  bool get isFoggy => WeatherCondition.isFoggy(weatherCode);

  bool get isSnowy => WeatherCondition.isSnowy(weatherCode);

  bool get isThunderstorm => WeatherCondition.isThunderstorm(weatherCode);

  double get maxTemp => dailyMaxTemp ?? temperature;

  double get minTemp => dailyMinTemp ?? temperature;

  double get rainTodayMm => precipitationMm ?? 0;

  bool get isRainExpected => rainTodayMm >= 1 || (rainChancePercent ?? 0) >= 50;

  bool get isHot => temperature >= 32;

  bool get isCold => temperature <= 12;
}

class WeatherCondition {
  WeatherCondition._();

  static String label(int code) {
    switch (code) {
      case 0:
        return 'Clear Sky';
      case 1:
        return 'Mainly Clear';
      case 2:
        return 'Partly Cloudy';
      case 3:
        return 'Overcast';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 56:
      case 57:
        return 'Freezing Drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rainy';
      case 66:
      case 67:
        return 'Freezing Rain';
      case 71:
      case 73:
      case 75:
        return 'Snowy';
      case 77:
        return 'Snow Grains';
      case 80:
      case 81:
      case 82:
        return 'Rain Showers';
      case 85:
      case 86:
        return 'Snow Showers';
      case 95:
        return 'Thunderstorm';
      case 96:
      case 99:
        return 'Thunderstorm';
      default:
        return 'Unknown';
    }
  }

  static String emoji(int code) {
    switch (code) {
      case 0:
        return '☀️';
      case 1:
        return '🌤️';
      case 2:
        return '⛅';
      case 3:
        return '☁️';
      case 45:
      case 48:
        return '🌫️';
      case 51:
      case 53:
      case 55:
      case 80:
      case 81:
      case 82:
        return '🌦️';
      case 56:
      case 57:
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
        return '🌧️';
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return '🌨️';
      case 95:
      case 96:
      case 99:
        return '⛈️';
      default:
        return '🌤️';
    }
  }

  static bool isRaining(int code) {
    const codes = {51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82};
    return codes.contains(code);
  }

  static bool isFoggy(int code) {
    const codes = {45, 48};
    return codes.contains(code);
  }

  static bool isSnowy(int code) {
    const codes = {71, 73, 75, 77, 85, 86};
    return codes.contains(code);
  }

  static bool isThunderstorm(int code) {
    const codes = {95, 96, 99};
    return codes.contains(code);
  }
}
