import 'package:flutter_test/flutter_test.dart';

import 'package:smart_agriculture_app/models/farm.dart';
import 'package:smart_agriculture_app/models/soil_reading.dart';
import 'package:smart_agriculture_app/models/weather_data.dart';
import 'package:smart_agriculture_app/services/soil_water_service.dart';

Farm _farm({String size = '1 acre', String name = 'Green Farm'}) {
  return Farm(
    userId: 1,
    farmName: name,
    location: 'Field',
    farmSize: size,
    soilType: 'Loamy',
    mainCrop: 'Rice',
    description: '',
  );
}

WeatherData _weather({
  double max = 34,
  double min = 22,
  double rain = 0,
  double temperature = 32,
}) {
  return WeatherData(
    temperature: temperature,
    humidity: 55,
    windSpeed: 8,
    weatherCode: 0,
    time: '2026-10-03T10:00',
    latitude: 17.4,
    longitude: 78.5,
    dailyMaxTemp: max,
    dailyMinTemp: min,
    precipitationMm: rain,
    rainChancePercent: rain > 0 ? 70 : 10,
  );
}

SoilReading _reading({
  double moisture = 28,
  double level = 60,
  double used = 0,
  double required = 0,
}) {
  return SoilReading(
    userId: 1,
    farmId: 1,
    moisturePercent: moisture,
    waterLevelPercent: level,
    waterUsedLitres: used,
    waterRequiredLitres: required,
    minMoisturePercent: 35,
    minWaterLevelPercent: 25,
    note: '',
    createdAt: '2026-10-03T06:00:00.000',
  );
}

void main() {
  group('farm area parsing', () {
    test('reads acres, hectares and square metres', () {
      expect(
        SoilWaterService.parseAreaSquareMetres('2 acres'),
        closeTo(8093.72, 0.01),
      );
      expect(SoilWaterService.parseAreaSquareMetres('1 hectare'), 10000);
      expect(SoilWaterService.parseAreaSquareMetres('500 sq m'), 500);
      expect(SoilWaterService.parseAreaSquareMetres('3 bigha'), 6069);
    });

    test('falls back to one acre for unknown text', () {
      expect(
        SoilWaterService.parseAreaSquareMetres(''),
        closeTo(4046.86, 0.01),
      );
      expect(
        SoilWaterService.parseAreaSquareMetres('along the road'),
        closeTo(4046.86, 0.01),
      );
    });
  });

  group('water requirement from weather', () {
    test('a hot dry day needs more water than a mild day', () {
      final hot = SoilWaterService.dailyBalance(
        weather: _weather(max: 38, min: 26, temperature: 36),
        cropName: 'Tomato',
      );
      final mild = SoilWaterService.dailyBalance(
        weather: _weather(max: 20, min: 12, temperature: 16),
        cropName: 'Tomato',
      );

      expect(hot.et0Mm, greaterThan(mild.et0Mm));
      expect(hot.netNeedMm, greaterThan(0));
    });

    test('rain gives a credit and lowers the net need', () {
      final dry = SoilWaterService.dailyBalance(
        weather: _weather(),
        cropName: 'Rice',
      );
      final wet = SoilWaterService.dailyBalance(
        weather: _weather(rain: 10),
        cropName: 'Rice',
      );

      expect(wet.rainMm, closeTo(8, 0.001));
      expect(wet.netNeedMm, lessThan(dry.netNeedMm));
      expect(wet.netNeedMm, greaterThanOrEqualTo(0));
    });

    test('growth stage changes the crop need', () {
      final seedling = SoilWaterService.cropCoefficient('Rice', 'Seedling');
      final flowering = SoilWaterService.cropCoefficient('Rice', 'Flowering');

      expect(flowering, greaterThan(seedling));
    });
  });

  group('thresholds', () {
    test('rice needs wetter soil than a general crop', () {
      expect(
        SoilWaterService.minimumMoisturePercent(cropName: 'Rice'),
        greaterThan(
          SoilWaterService.minimumMoisturePercent(cropName: 'General Crop'),
        ),
      );
    });

    test('hot dry weather raises the requirement, rain lowers it', () {
      final hot = SoilWaterService.minimumMoisturePercent(
        cropName: 'Tomato',
        weather: _weather(temperature: 36),
      );
      final wet = SoilWaterService.minimumMoisturePercent(
        cropName: 'Tomato',
        weather: _weather(rain: 12, temperature: 24),
      );

      expect(hot, greaterThan(wet));
    });

    test('a reading below the minimum is flagged', () {
      final reading = _reading(moisture: 20, level: 20);

      expect(reading.isMoistureLow, isTrue);
      expect(reading.isWaterLevelLow, isTrue);
      expect(reading.needsWater, isTrue);
      expect(_reading(moisture: 45, level: 60).needsWater, isFalse);
    });

    test('status moves from healthy to critical', () {
      expect(
        SoilWaterService.statusFor(
          moisturePercent: 45,
          minMoisturePercent: 35,
          waterLevelPercent: 60,
          minWaterLevelPercent: 40,
        ),
        WaterStatus.healthy,
      );
      expect(
        SoilWaterService.statusFor(
          moisturePercent: 25,
          minMoisturePercent: 35,
          waterLevelPercent: 60,
          minWaterLevelPercent: 40,
        ),
        WaterStatus.low,
      );
      expect(
        SoilWaterService.statusFor(
          moisturePercent: 20,
          minMoisturePercent: 35,
          waterLevelPercent: 10,
          minWaterLevelPercent: 40,
        ),
        WaterStatus.critical,
      );
    });
  });

  group('daily plan for a farm', () {
    test('converts millimetres into litres using the farm area', () {
      final weather = _weather();
      final plan = SoilWaterService.buildPlan(
        farm: _farm(),
        weather: weather,
        cropName: 'Rice',
        growthStage: 'Flowering',
      );

      expect(plan.areaSquareMetres, closeTo(4046.86, 0.01));
      expect(
        plan.requiredLitres,
        closeTo(plan.balance.netNeedMm * plan.areaSquareMetres, 0.001),
      );
      expect(plan.weatherBased, isTrue);
      expect(plan.status, isNull);
    });

    test('tracks what is still to be used', () {
      final plan = SoilWaterService.buildPlan(
        farm: _farm(),
        reading: _reading(moisture: 28, level: 70, used: 1000, required: 2500),
        weather: _weather(),
        cropName: 'Rice',
      );

      expect(plan.remainingLitres, closeTo(plan.requiredLitres - 1000, 0.001));
      expect(plan.extraLitres, 0);
      expect(plan.minMoisturePercent, 40);
      expect(plan.minWaterLevelPercent, 65);
      expect(plan.status, WaterStatus.low);
      expect(plan.advice, isNotEmpty);
    });

    test('flags over watering without going negative', () {
      final plan = SoilWaterService.buildPlan(
        farm: _farm(),
        reading: _reading(used: 9000, required: 1000),
        weather: _weather(rain: 40),
        cropName: 'Rice',
      );

      expect(plan.remainingLitres, 0);
      expect(plan.extraLitres, greaterThan(0));
    });

    test('works without weather using a typical day', () {
      final plan = SoilWaterService.buildPlan(farm: _farm(), cropName: 'Rice');

      expect(plan.weatherBased, isFalse);
      expect(plan.requiredLitres, greaterThan(0));
    });
  });

  group('dashboard helpers', () {
    test('averages and counts farms that need water', () {
      final readings = [
        _reading(moisture: 20, level: 30),
        _reading(moisture: 40, level: 70),
      ];

      expect(SoilWaterService.averageMoisturePercent(readings), 30);
      expect(SoilWaterService.averageWaterLevelPercent(readings), 50);
      expect(SoilWaterService.countNeedingWater(readings), 1);
      expect(SoilWaterService.highestRequiredMoisture(readings), 35);
      expect(SoilWaterService.highestRequiredWaterLevel(readings), 25);
    });

    test('empty readings stay safe', () {
      expect(SoilWaterService.averageMoisturePercent([]), 0);
      expect(SoilWaterService.countNeedingWater([]), 0);
      expect(SoilWaterService.highestRequiredMoisture([]), 30);
      expect(SoilWaterService.highestRequiredWaterLevel([]), 25);
    });
  });
}
