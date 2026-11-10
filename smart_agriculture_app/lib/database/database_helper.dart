import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/alert.dart';
import '../models/chat_message.dart';
import '../models/crop.dart';
import '../models/crop_scan.dart';
import '../models/farm.dart';
import '../models/soil_reading.dart';
import '../models/user.dart';
import 'db_factory.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _dbName = 'smart_agriculture.db';
  static const int _dbVersion = 2;
  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    await initializeDatabaseFactory();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE farms(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        farmName TEXT NOT NULL,
        location TEXT,
        farmSize TEXT,
        soilType TEXT,
        mainCrop TEXT,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE crops(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        farmId INTEGER NOT NULL,
        cropName TEXT NOT NULL,
        plantingDate TEXT,
        growthStage TEXT,
        status TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE alerts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE crop_scans(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        cropName TEXT,
        imagePath TEXT,
        condition TEXT,
        problem TEXT,
        care TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        question TEXT,
        answer TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await _createSoilReadings(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createSoilReadings(db);
    }
  }

  Future<void> _createSoilReadings(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS soil_readings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        farmId INTEGER NOT NULL,
        moisturePercent REAL NOT NULL DEFAULT 0,
        waterLevelPercent REAL NOT NULL DEFAULT 0,
        waterUsedLitres REAL NOT NULL DEFAULT 0,
        waterRequiredLitres REAL NOT NULL DEFAULT 0,
        minMoisturePercent REAL NOT NULL DEFAULT 30,
        minWaterLevelPercent REAL NOT NULL DEFAULT 25,
        note TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  String now() => DateTime.now().toIso8601String();

  // ------------------- USERS -------------------

  Future<User> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final db = await database;
    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (existing.isNotEmpty) {
      throw Exception('This email is already registered.');
    }
    final id = await db.insert('users', {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    });
    return User(
      id: id,
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
  }

  Future<User> loginUser({
    required String email,
    required String password,
  }) async {
    final db = await database;
    final rows = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw Exception('Invalid email or password.');
    }
    return User.fromMap(rows.first);
  }
  // ------------------------------------------------------------
  // GET USER BY ID
  // ------------------------------------------------------------

  Future<User?> getUserById(int id) async {
    final db = await database;

    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return User.fromMap(rows.first);
  }

  Future<void> updateUser(User user) async {
    final db = await database;
    final data = user.toMap()..remove('id');
    await db.update('users', data, where: 'id = ?', whereArgs: [user.id]);
  }

  // ------------------- FARMS -------------------

  Future<List<Farm>> getAllFarms(int userId) async {
    final db = await database;
    final rows = await db.query(
      'farms',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return rows.map(Farm.fromMap).toList();
  }

  Future<int> addFarm(Farm farm) async {
    final db = await database;
    final data = farm.toMap()..remove('id');
    return db.insert('farms', data);
  }

  Future<void> updateFarm(Farm farm) async {
    final db = await database;
    final data = farm.toMap()..remove('id');
    await db.update('farms', data, where: 'id = ?', whereArgs: [farm.id]);
  }

  Future<void> deleteFarm(int id) async {
    final db = await database;
    await db.delete('crops', where: 'farmId = ?', whereArgs: [id]);
    await db.delete('farms', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------- CROPS -------------------

  Future<List<Crop>> getCropsForFarm(int farmId) async {
    final db = await database;
    final rows = await db.query(
      'crops',
      where: 'farmId = ?',
      whereArgs: [farmId],
      orderBy: 'id DESC',
    );
    return rows.map(Crop.fromMap).toList();
  }

  Future<List<Crop>> getCropsForUser(int userId) async {
    final db = await database;
    final farmRows = await db.query(
      'farms',
      columns: ['id'],
      where: 'userId = ?',
      whereArgs: [userId],
    );
    if (farmRows.isEmpty) return [];
    final farmIds = farmRows.map((f) => f['id'] as int).toList();
    final placeholders = List.filled(farmIds.length, '?').join(',');
    final rows = await db.query(
      'crops',
      where: 'farmId IN ($placeholders)',
      whereArgs: farmIds,
      orderBy: 'id DESC',
    );
    return rows.map(Crop.fromMap).toList();
  }

  Future<int> addCrop(Crop crop) async {
    final db = await database;
    final data = crop.toMap()..remove('id');
    return db.insert('crops', data);
  }

  Future<void> updateCrop(Crop crop) async {
    final db = await database;
    final data = crop.toMap()..remove('id');
    await db.update('crops', data, where: 'id = ?', whereArgs: [crop.id]);
  }

  Future<void> deleteCrop(int id) async {
    final db = await database;
    await db.delete('crops', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------- ALERTS -------------------

  Future<void> addAlert(Alert alert) async {
    final db = await database;
    final data = alert.toMap()..remove('id');
    await db.insert('alerts', data);
  }

  Future<List<Alert>> getAlerts(int userId) async {
    final db = await database;
    final rows = await db.query(
      'alerts',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return rows.map(Alert.fromMap).toList();
  }

  Future<void> markAlertRead(int id) async {
    final db = await database;
    await db.update('alerts', {'isRead': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAlert(int id) async {
    final db = await database;
    await db.delete('alerts', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> unreadAlertCount(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM alerts WHERE userId = ? AND isRead = 0',
      [userId],
    );
    return (result.first['c'] as int?) ?? 0;
  }

  // ------------------- CROP SCANS -------------------

  Future<int> addCropScan(CropScan scan) async {
    final db = await database;
    final data = scan.toMap()..remove('id');
    return db.insert('crop_scans', data);
  }

  Future<List<CropScan>> getCropScans(int userId) async {
    final db = await database;
    final rows = await db.query(
      'crop_scans',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return rows.map(CropScan.fromMap).toList();
  }

  // ------------------- CHAT HISTORY -------------------

  Future<int> addChatMessage(ChatMessage message) async {
    final db = await database;
    final data = message.toMap()..remove('id');
    return db.insert('chat_history', data);
  }

  Future<List<ChatMessage>> getChatHistory(int userId) async {
    final db = await database;
    final rows = await db.query(
      'chat_history',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'id ASC',
    );
    return rows.map(ChatMessage.fromMap).toList();
  }

  // ------------------- SOIL READINGS -------------------

  Future<int> addSoilReading(SoilReading reading) async {
    final db = await database;
    final data = reading.toMap()..remove('id');
    return db.insert('soil_readings', data);
  }

  Future<List<SoilReading>> getSoilReadingsForFarm(
    int farmId, {
    int limit = 20,
  }) async {
    final db = await database;
    final rows = await db.query(
      'soil_readings',
      where: 'farmId = ?',
      whereArgs: [farmId],
      orderBy: 'id DESC',
      limit: limit,
    );
    return rows.map(SoilReading.fromMap).toList();
  }

  Future<SoilReading?> getLatestSoilReading(int farmId) async {
    final readings = await getSoilReadingsForFarm(farmId, limit: 1);
    return readings.isEmpty ? null : readings.first;
  }

  Future<List<SoilReading>> getLatestSoilReadings(int userId) async {
    final db = await database;
    final farmRows = await db.query(
      'farms',
      columns: ['id'],
      where: 'userId = ?',
      whereArgs: [userId],
    );
    if (farmRows.isEmpty) return [];
    final farmIds = farmRows.map((f) => f['id'] as int).toList();
    final placeholders = List.filled(farmIds.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT r.* FROM soil_readings r '
      'JOIN (SELECT farmId, MAX(id) AS latestId FROM soil_readings '
      'WHERE farmId IN ($placeholders) GROUP BY farmId) latest '
      'ON r.id = latest.latestId',
      farmIds,
    );
    return rows.map(SoilReading.fromMap).toList();
  }

  Future<List<SoilReading>> getSoilReadingsForUser(int userId) async {
    final db = await database;
    final farmRows = await db.query(
      'farms',
      columns: ['id'],
      where: 'userId = ?',
      whereArgs: [userId],
    );
    if (farmRows.isEmpty) return [];
    final farmIds = farmRows.map((f) => f['id'] as int).toList();
    final placeholders = List.filled(farmIds.length, '?').join(',');
    final rows = await db.query(
      'soil_readings',
      where: 'farmId IN ($placeholders)',
      whereArgs: farmIds,
      orderBy: 'id DESC',
    );
    return rows.map(SoilReading.fromMap).toList();
  }

  Future<void> deleteSoilReading(int id) async {
    final db = await database;
    await db.delete('soil_readings', where: 'id = ?', whereArgs: [id]);
  }
}
