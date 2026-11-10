import '../database/database_helper.dart';
import '../models/alert.dart';

class AlertService {
  AlertService._();

  static String _now() => DateTime.now().toIso8601String();

  static Future<void> generateWeatherAlerts({
    required int userId,
    required double temperature,
    required double humidity,
    required double windSpeedKmh,
    required bool isRaining,
    required bool isFoggy,
    bool isThunderstorm = false,
  }) async {
    final alerts = <Alert>[];

    if (isThunderstorm) {
      alerts.add(
        Alert(
          userId: userId,
          title: 'Thunderstorm Alert',
          message:
              'Thunderstorm detected. Avoid working in open fields and protect crops and livestock.',
          type: 'Weather Alert',
          isRead: false,
          createdAt: _now(),
        ),
      );
    }

    if (isRaining) {
      alerts.add(
        Alert(
          userId: userId,
          title: 'Heavy Rain Alert',
          message:
              'Heavy rain detected. Avoid unnecessary irrigation and check field drainage.',
          type: 'Weather Alert',
          isRead: false,
          createdAt: _now(),
        ),
      );
    }

    if (isFoggy) {
      alerts.add(
        Alert(
          userId: userId,
          title: 'Foggy Conditions',
          message:
              'Foggy conditions detected. Monitor crops for fungal diseases.',
          type: 'Weather Alert',
          isRead: false,
          createdAt: _now(),
        ),
      );
    }

    if (temperature >= 35) {
      alerts.add(
        Alert(
          userId: userId,
          title: 'High Temperature Alert',
          message:
              'High temperature detected. Check crop moisture and avoid watering during the hottest hours.',
          type: 'Temperature Alert',
          isRead: false,
          createdAt: _now(),
        ),
      );
    }

    if (temperature <= 10) {
      alerts.add(
        Alert(
          userId: userId,
          title: 'Low Temperature Alert',
          message:
              'Low temperature detected. Protect young crops from cold stress.',
          type: 'Temperature Alert',
          isRead: false,
          createdAt: _now(),
        ),
      );
    }

    if (windSpeedKmh >= 30) {
      alerts.add(
        Alert(
          userId: userId,
          title: 'Strong Wind Alert',
          message:
              'Strong wind detected. Avoid spraying pesticides or fertilizers.',
          type: 'Weather Alert',
          isRead: false,
          createdAt: _now(),
        ),
      );
    }

    if (humidity < 30) {
      alerts.add(
        Alert(
          userId: userId,
          title: 'Dry Conditions',
          message:
              'Air humidity is low. Check soil moisture and plan irrigation if needed.',
          type: 'Irrigation Alert',
          isRead: false,
          createdAt: _now(),
        ),
      );
    }

    if (humidity > 85 && !isRaining) {
      alerts.add(
        Alert(
          userId: userId,
          title: 'High Humidity Alert',
          message:
              'High humidity detected. Watch for fungal disease and improve air flow.',
          type: 'Irrigation Alert',
          isRead: false,
          createdAt: _now(),
        ),
      );
    }

    for (final alert in alerts) {
      await _insertIfNew(alert);
    }
  }

  static Future<void> _insertIfNew(Alert alert) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'alerts',
      columns: ['id', 'createdAt'],
      where: 'title = ? AND type = ? AND userId = ?',
      whereArgs: [alert.title, alert.type, alert.userId],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      final last = DateTime.tryParse(
        (rows.first['createdAt'] as String?) ?? '',
      );
      if (last != null && DateTime.now().difference(last).inHours < 6) {
        return;
      }
    }
    await db.insert('alerts', alert.toMap()..remove('id'));
  }

  static Future<void> generateWaterAlerts({
    required int userId,
    required String farmName,
    required double moisturePercent,
    required double waterLevelPercent,
    required double minMoisturePercent,
    required double minWaterLevelPercent,
    required double requiredLitres,
    required double usedLitres,
  }) async {
    final alerts = <Alert>[];
    final name = farmName.isEmpty ? 'Your farm' : farmName;

    if (moisturePercent < minMoisturePercent) {
      alerts.add(
        Alert(
          userId: userId,
          title: 'Low Soil Moisture: $name',
          message:
              'Soil moisture is ${_round(moisturePercent)}%. '
              'The minimum for this crop is ${_round(minMoisturePercent)}%. '
              '${_wateringAdvice(requiredLitres, usedLitres)}',
          type: 'Moisture Alert',
          isRead: false,
          createdAt: _now(),
        ),
      );
    }

    if (waterLevelPercent < minWaterLevelPercent) {
      alerts.add(
        Alert(
          userId: userId,
          title: 'Low Water Level: $name',
          message:
              'Water level is ${_round(waterLevelPercent)}%. '
              'It should stay above ${_round(minWaterLevelPercent)}%. '
              '${_tankAdvice()}',
          type: 'Water Level Alert',
          isRead: false,
          createdAt: _now(),
        ),
      );
    }

    for (final alert in alerts) {
      await _insertIfNew(alert);
    }
  }

  static String _round(double value) => '${value.round()}%';

  static String _wateringAdvice(double requiredLitres, double usedLitres) {
    final remaining = requiredLitres - usedLitres;
    if (remaining <= 0) {
      return 'Water this field soon. Drip irrigation saves water.';
    }
    return 'Water about ${remaining.round()} litres today. '
        'Water in the early morning or evening.';
  }

  static String _tankAdvice() {
    return 'Fill the tank or pond, or arrange a water supply '
        'before the next irrigation.';
  }
}
