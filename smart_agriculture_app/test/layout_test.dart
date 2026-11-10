import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:smart_agriculture_app/database/database_helper.dart';
import 'package:smart_agriculture_app/main.dart';
import 'package:smart_agriculture_app/models/alert.dart';
import 'package:smart_agriculture_app/models/farm.dart';
import 'package:smart_agriculture_app/models/soil_reading.dart';
import 'package:smart_agriculture_app/models/user.dart';
import 'package:smart_agriculture_app/screens/dashboard/dashboard_screen.dart';
import 'package:smart_agriculture_app/screens/moisture/soil_moisture_screen.dart';
import 'package:smart_agriculture_app/services/session_service.dart';

const List<Size> _screenSizes = [
  Size(320, 2400),
  Size(360, 2600),
  Size(414, 2800),
  Size(768, 3200),
];

Future<void> _pumpAt(WidgetTester tester, Widget screen, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.runAsync(() async {
    await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: screen));
    await Future<void>.delayed(const Duration(milliseconds: 800));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _seed() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final db = await DatabaseHelper.instance.database;
  await db.delete('alerts');
  await db.delete('soil_readings');
  await db.delete('crops');
  await db.delete('farms');
  await db.delete('users');

  final user = await DatabaseHelper.instance.registerUser(
    name: 'Test Farmer',
    email: 'layout@test.com',
    phone: '9000000000',
    password: 'secret12',
  );
  SessionService.instance.currentUser = User(
    id: user.id,
    name: user.name,
    email: user.email,
    phone: user.phone,
    password: user.password,
  );

  await DatabaseHelper.instance.addFarm(
    Farm(
      userId: user.id!,
      farmName: 'Green Valley Farm',
      location: 'North field',
      farmSize: '2 acres',
      soilType: 'Loamy',
      mainCrop: 'Rice',
      description: '',
    ),
  );
  await DatabaseHelper.instance.addSoilReading(
    SoilReading(
      userId: user.id!,
      farmId: 1,
      moisturePercent: 18,
      waterLevelPercent: 12,
      waterUsedLitres: 900,
      waterRequiredLitres: 5200,
      minMoisturePercent: 35,
      minWaterLevelPercent: 25,
      note: '',
      createdAt: DateTime.now().toIso8601String(),
    ),
  );
  await DatabaseHelper.instance.addAlert(
    Alert(
      userId: user.id!,
      title: 'Low Soil Moisture: Green Valley Farm',
      message:
          'Soil moisture is 18%. The minimum for this crop is 35%. '
          'Water about 4300 litres today.',
      type: 'Moisture Alert',
      isRead: false,
      createdAt: DateTime.now().toIso8601String(),
    ),
  );
}

void main() {
  setUpAll(_seed);

  group('home screen fits small screens', () {
    for (final size in _screenSizes) {
      testWidgets('dashboard renders without overflow at '
          '${size.width.toInt()}px', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await _pumpAt(tester, const DashboardScreen(), size);

        expect(find.text('Soil & Water'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('soil and water screen fits small screens', () {
    for (final size in _screenSizes) {
      testWidgets('soil screen renders without overflow at '
          '${size.width.toInt()}px', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await _pumpAt(tester, const SoilMoistureScreen(), size);

        expect(find.text('Record Reading'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
