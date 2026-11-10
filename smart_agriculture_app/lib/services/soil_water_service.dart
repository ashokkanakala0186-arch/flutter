import 'dart:math' as math;

import '../database/database_helper.dart';
import '../models/crop.dart';
import '../models/farm.dart';
import '../models/soil_reading.dart';
import '../models/weather_data.dart';
import 'alert_service.dart';
import 'session_service.dart';

enum WaterStatus { healthy, stable, low, critical }

class DailyWaterBalance {
  const DailyWaterBalance({
    required this.cropName,
    required this.cropCoefficient,
    required this.et0Mm,
    required this.cropNeedMm,
    required this.rainMm,
    required this.netNeedMm,
  });

  final String cropName;
  final double cropCoefficient;
  final double et0Mm;
  final double cropNeedMm;
  final double rainMm;
  final double netNeedMm;
}

class WaterPlan {
  const WaterPlan({
    required this.farmName,
    required this.balance,
    required this.areaSquareMetres,
    required this.requiredLitres,
    required this.usedLitres,
    required this.minMoisturePercent,
    required this.minWaterLevelPercent,
    required this.status,
    required this.advice,
    required this.weatherBased,
  });

  final String farmName;
  final DailyWaterBalance balance;
  final double areaSquareMetres;
  final double requiredLitres;
  final double usedLitres;
  final double minMoisturePercent;
  final double minWaterLevelPercent;
  final WaterStatus? status;
  final String advice;
  final bool weatherBased;

  double get remainingLitres => math.max(0, requiredLitres - usedLitres);

  double get extraLitres => math.max(0, usedLitres - requiredLitres);

  double get usagePercent {
    if (requiredLitres <= 0) return 0;
    return (usedLitres / requiredLitres * 100).clamp(0, 999).toDouble();
  }
}

class SoilWaterService {
  SoilWaterService._();

  static const double _squareMetresPerAcre = 4046.86;
  static const double _squareMetresPerHectare = 10000;
  static const double _squareMetresPerBigha = 2023;
  static const double _fallbackEt0Mm = 5;
  static const double _rainUseFactor = 0.8;
  static const double _maxRainCreditMm = 25;

  static const Map<String, double> _baseMoisturePercent = {
    'Rice': 35,
    'Banana': 35,
    'Wheat': 30,
    'Cotton': 30,
    'Tomato': 30,
    'Potato': 30,
    'Corn': 28,
    'Chilli': 28,
  };

  static const Map<String, double> _baseWaterLevelPercent = {
    'Rice': 60,
    'Banana': 45,
  };

  static const Map<String, double> _cropCoefficient = {
    'Rice': 1.05,
    'Banana': 1,
    'Cotton': 1.15,
    'Corn': 1.15,
    'Wheat': 1.05,
    'Tomato': 1,
    'Potato': 1,
    'Chilli': 0.9,
  };

  static const Map<String, double> _stageCoefficient = {
    'Seedling': 0.7,
    'Vegetative': 0.9,
    'Flowering': 1.15,
    'Harvest': 0.8,
  };

  static double parseAreaSquareMetres(String farmSize) {
    final text = farmSize.toLowerCase().trim();
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(text);
    if (match == null) return _squareMetresPerAcre;
    final value = double.tryParse(match.group(1) ?? '') ?? 0;
    if (value <= 0) return _squareMetresPerAcre;
    if (text.contains('sq') ||
        text.contains('m2') ||
        text.contains('m²') ||
        text.contains('sq.m')) {
      return value;
    }
    if (text.contains('hectare') ||
        text.contains('hecta') ||
        RegExp(r'\bha\b').hasMatch(text)) {
      return value * _squareMetresPerHectare;
    }
    if (text.contains('bigha')) return value * _squareMetresPerBigha;
    return value * _squareMetresPerAcre;
  }

  static double cropCoefficient(String cropName, String growthStage) {
    final crop = _cropCoefficient[cropName] ?? 1;
    final stage = _stageCoefficient[growthStage] ?? 1;
    return crop * stage;
  }

  static double minimumMoisturePercent({
    String cropName = 'General Crop',
    WeatherData? weather,
  }) {
    var value = _baseMoisturePercent[cropName] ?? 30;
    if (weather != null) {
      if (weather.isHot) value += 5;
      if (weather.isCold) value -= 3;
      if (weather.windSpeed >= 25) value += 2;
      if (weather.rainTodayMm >= 5) value -= 6;
    }
    return value.clamp(15, 60).toDouble();
  }

  static double minimumWaterLevelPercent({
    String cropName = 'General Crop',
    WeatherData? weather,
  }) {
    var value = _baseWaterLevelPercent[cropName] ?? 25;
    if (weather != null) {
      if (weather.rainTodayMm < 1) value += 5;
      if (weather.rainTodayMm >= 10) value -= 5;
    }
    return value.clamp(10, 85).toDouble();
  }

  static double referenceEvapotranspiration({
    required WeatherData weather,
    DateTime? day,
  }) {
    final high = math.max(weather.maxTemp, weather.minTemp);
    final low = math.min(weather.maxTemp, weather.minTemp);
    final mean = (high + low) / 2;
    final range = (high - low).clamp(0.0, 30.0);
    if (range < 0.5) return _fallbackEt0Mm;
    final radiation = _extraterrestrialRadiation(
      weather.latitude,
      day ?? DateTime.now(),
    );
    if (radiation <= 0) return _fallbackEt0Mm;
    final warmth = math.max(0.0, mean + 17.8);
    final et0 = 0.0023 * radiation * warmth * math.sqrt(range);
    return et0.clamp(0.5, 14).toDouble();
  }

  static double _extraterrestrialRadiation(double latitude, DateTime day) {
    const double solarConstant = 0.0820;
    final dayOfYear = day.difference(DateTime(day.year)).inDays + 1;
    final latitudeRadians = latitude * math.pi / 180;
    final inverseDistance = 1 + 0.033 * math.cos(2 * math.pi * dayOfYear / 365);
    final declination = 0.409 * math.sin(2 * math.pi * dayOfYear / 365 - 0.39);
    final sunsetArgument = (-math.tan(latitudeRadians) * math.tan(declination))
        .clamp(-1.0, 1.0)
        .toDouble();
    final sunsetAngle = math.acos(sunsetArgument);
    final projection =
        sunsetAngle * math.sin(latitudeRadians) * math.sin(declination) +
        math.cos(latitudeRadians) *
            math.cos(declination) *
            math.sin(sunsetAngle);
    if (projection <= 0) return 0;
    final radiation =
        24 * 60 / math.pi * solarConstant * inverseDistance * projection;
    return radiation.clamp(0.0, 42).toDouble();
  }

  static DailyWaterBalance dailyBalance({
    required WeatherData weather,
    String cropName = 'General Crop',
    String growthStage = '',
  }) {
    final et0 = referenceEvapotranspiration(weather: weather);
    final coefficient = cropCoefficient(cropName, growthStage);
    final cropNeed = et0 * coefficient;
    final rain =
        math.min(weather.rainTodayMm, _maxRainCreditMm) * _rainUseFactor;
    final netNeed = math.max(0.0, cropNeed - rain);
    return DailyWaterBalance(
      cropName: cropName,
      cropCoefficient: coefficient,
      et0Mm: et0,
      cropNeedMm: cropNeed,
      rainMm: rain,
      netNeedMm: netNeed,
    );
  }

  static DailyWaterBalance typicalBalance({
    String cropName = 'General Crop',
    String growthStage = '',
  }) {
    final coefficient = cropCoefficient(cropName, growthStage);
    final cropNeed = _fallbackEt0Mm * coefficient;
    return DailyWaterBalance(
      cropName: cropName,
      cropCoefficient: coefficient,
      et0Mm: _fallbackEt0Mm,
      cropNeedMm: cropNeed,
      rainMm: 0,
      netNeedMm: cropNeed,
    );
  }

  static WaterStatus statusFor({
    required double moisturePercent,
    required double minMoisturePercent,
    required double waterLevelPercent,
    required double minWaterLevelPercent,
  }) {
    final moistureGap = moisturePercent - minMoisturePercent;
    final levelGap = waterLevelPercent - minWaterLevelPercent;
    if (moistureGap < 0 && levelGap < 0) return WaterStatus.critical;
    if (moistureGap < 0 || levelGap < 0) return WaterStatus.low;
    if (moistureGap >= 10 && levelGap >= 15) return WaterStatus.healthy;
    return WaterStatus.stable;
  }

  static String statusLabel(WaterStatus? status) {
    switch (status) {
      case WaterStatus.healthy:
        return 'Healthy';
      case WaterStatus.stable:
        return 'Stable';
      case WaterStatus.low:
        return 'Needs Water';
      case WaterStatus.critical:
        return 'Water Now';
      case null:
        return 'No Reading';
    }
  }

  static String adviceFor({
    required Farm farm,
    required DailyWaterBalance balance,
    required double requiredLitres,
    required double usedLitres,
    required WaterStatus? status,
    WeatherData? weather,
  }) {
    final lines = <String>[];
    switch (status) {
      case WaterStatus.healthy:
        lines.add('Soil moisture and water level are healthy.');
      case WaterStatus.stable:
        lines.add(
          'Levels are just above the safe minimum. Check again tomorrow.',
        );
      case WaterStatus.low:
        lines.add(
          'One reading is below the safe level. Plan a watering slot soon.',
        );
      case WaterStatus.critical:
        lines.add('Soil moisture and water level are both low. Water today.');
      case null:
        lines.add('Record a reading to get live advice for this farm.');
    }
    if (weather != null && weather.isRainExpected) {
      lines.add(
        'Rain is expected (${weather.rainTodayMm.round()} mm), '
        'so you may not need to water today.',
      );
    }
    if (requiredLitres > 0) {
      if (usedLitres <= 0) {
        lines.add(
          "Today's need for ${farm.farmName}: about ${requiredLitres.round()} litres.",
        );
      } else if (usedLitres < requiredLitres) {
        final pending = requiredLitres - usedLitres;
        lines.add('Still need about ${pending.round()} litres today.');
      } else {
        final extra = usedLitres - requiredLitres;
        lines.add(
          'You used ${usedLitres.round()} litres today, '
          '${extra.round()} litres more than needed.',
        );
      }
    } else {
      lines.add(
        'No irrigation is needed today. ${balance.netNeedMm.round()} mm.',
      );
    }
    return lines.join('\n');
  }

  static WaterPlan buildPlan({
    required Farm farm,
    SoilReading? reading,
    WeatherData? weather,
    String cropName = 'General Crop',
    String growthStage = '',
  }) {
    final balance = weather == null
        ? typicalBalance(cropName: cropName, growthStage: growthStage)
        : dailyBalance(
            weather: weather,
            cropName: cropName,
            growthStage: growthStage,
          );
    final area = parseAreaSquareMetres(farm.farmSize);
    final requiredLitres = balance.netNeedMm * area;
    final usedLitres = reading?.waterUsedLitres ?? 0;
    final minMoisture = minimumMoisturePercent(
      cropName: cropName,
      weather: weather,
    );
    final minLevel = minimumWaterLevelPercent(
      cropName: cropName,
      weather: weather,
    );
    final status = reading == null
        ? null
        : statusFor(
            moisturePercent: reading.moisturePercent,
            minMoisturePercent: minMoisture,
            waterLevelPercent: reading.waterLevelPercent,
            minWaterLevelPercent: minLevel,
          );
    return WaterPlan(
      farmName: farm.farmName,
      balance: balance,
      areaSquareMetres: area,
      requiredLitres: requiredLitres,
      usedLitres: usedLitres,
      minMoisturePercent: minMoisture,
      minWaterLevelPercent: minLevel,
      status: status,
      weatherBased: weather != null,
      advice: adviceFor(
        farm: farm,
        balance: balance,
        requiredLitres: requiredLitres,
        usedLitres: usedLitres,
        status: status,
        weather: weather,
      ),
    );
  }

  static double averageMoisturePercent(List<SoilReading> readings) {
    if (readings.isEmpty) return 0;
    final total = readings.fold<double>(
      0,
      (sum, item) => sum + item.moisturePercent,
    );
    return total / readings.length;
  }

  static double averageWaterLevelPercent(List<SoilReading> readings) {
    if (readings.isEmpty) return 0;
    final total = readings.fold<double>(
      0,
      (sum, item) => sum + item.waterLevelPercent,
    );
    return total / readings.length;
  }

  static int countNeedingWater(List<SoilReading> readings) {
    return readings.where((reading) => reading.needsWater).length;
  }

  static double highestRequiredMoisture(List<SoilReading> readings) {
    if (readings.isEmpty) return 30;
    var highest = readings.first.minMoisturePercent;
    for (final reading in readings) {
      if (reading.minMoisturePercent > highest) {
        highest = reading.minMoisturePercent;
      }
    }
    return highest;
  }

  static double highestRequiredWaterLevel(List<SoilReading> readings) {
    if (readings.isEmpty) return 25;
    var highest = readings.first.minWaterLevelPercent;
    for (final reading in readings) {
      if (reading.minWaterLevelPercent > highest) {
        highest = reading.minWaterLevelPercent;
      }
    }
    return highest;
  }

  static String cropNameFor(Farm farm, List<Crop> crops) {
    if (crops.isNotEmpty && crops.first.cropName.isNotEmpty) {
      return crops.first.cropName;
    }
    if (farm.mainCrop.isNotEmpty) return farm.mainCrop;
    return 'General Crop';
  }

  static Future<void> runAutomaticChecks({WeatherData? weather}) async {
    final userId = SessionService.instance.userId;
    if (userId == null) return;
    try {
      final farms = await DatabaseHelper.instance.getAllFarms(userId);
      if (farms.isEmpty) return;
      final readings = await DatabaseHelper.instance.getLatestSoilReadings(
        userId,
      );
      if (readings.isEmpty) return;
      for (final farm in farms) {
        final farmId = farm.id;
        if (farmId == null) continue;
        SoilReading? reading;
        for (final item in readings) {
          if (item.farmId == farmId) reading = item;
        }
        if (reading == null) continue;
        final crops = await DatabaseHelper.instance.getCropsForFarm(farmId);
        final plan = buildPlan(
          farm: farm,
          reading: reading,
          weather: weather,
          cropName: cropNameFor(farm, crops),
          growthStage: crops.isEmpty ? '' : crops.first.growthStage,
        );
        await AlertService.generateWaterAlerts(
          userId: userId,
          farmName: farm.farmName,
          moisturePercent: reading.moisturePercent,
          waterLevelPercent: reading.waterLevelPercent,
          minMoisturePercent: plan.minMoisturePercent,
          minWaterLevelPercent: plan.minWaterLevelPercent,
          requiredLitres: plan.requiredLitres,
          usedLitres: reading.waterUsedLitres,
        );
      }
    } catch (_) {}
  }
}
