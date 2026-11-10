-- ============================================================================
--  SMART AGRICULTURE MONITORING APP
--  SQLite schema and data export
-- ----------------------------------------------------------------------------
--  Database file   : smart_agriculture.db
--  Schema version  : 2   (DatabaseHelper._dbVersion)
--  Created by      : lib/database/database_helper.dart
--  Engine          : SQLite 3 (Android / iOS / Windows / Linux / macOS)
--  Exported on     : 10-Nov-2026
--
--  Sources
--    1. Development database : <project>\.dart_tool\sqflite_common_ffi\
--                              databases\smart_agriculture.db   (schema v2)
--    2. Phone database       : /data/data/com.smartagri.smart_agriculture_app/
--                              databases/smart_agriculture.db    (schema v1)
--       The phone database predates the soil_readings table, so its rows are
--       included below in the version-2 schema.
--
--  Run with:
--      sqlite3 smart_agriculture.db < smart_agriculture_database.sql
--
--  Notes
--    * The app enables "PRAGMA foreign_keys = ON", but no FOREIGN KEY
--      constraints are declared in the schema. Related rows are removed
--      manually in DatabaseHelper.deleteFarm() (crops first, then the farm).
--    * AUTOINCREMENT tables maintain sqlite_sequence automatically, so no
--      explicit sqlite_sequence rows are needed after importing.
--    * "android_metadata" (locale table added by the Android sqflite plugin)
--      is created by the platform and is not part of the application schema.
--    * The login session is kept outside SQLite, in shared_preferences under
--      the key "logged_in_user_id".
-- ============================================================================

PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

-- ----------------------------------------------------------------------------
-- 1. users - one row per registered account
-- ----------------------------------------------------------------------------
CREATE TABLE users(
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  name     TEXT NOT NULL,
  email    TEXT NOT NULL UNIQUE,
  phone    TEXT,
  password TEXT NOT NULL
);

-- ----------------------------------------------------------------------------
-- 2. farms - farms owned by a user (userId -> users.id)
-- ----------------------------------------------------------------------------
CREATE TABLE farms(
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  userId      INTEGER NOT NULL,
  farmName    TEXT NOT NULL,
  location    TEXT,
  farmSize    TEXT,
  soilType    TEXT,
  mainCrop    TEXT,
  description TEXT
);

-- ----------------------------------------------------------------------------
-- 3. crops - crops grown on a farm (farmId -> farms.id)
-- ----------------------------------------------------------------------------
CREATE TABLE crops(
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  farmId       INTEGER NOT NULL,
  cropName     TEXT NOT NULL,
  plantingDate TEXT,
  growthStage  TEXT,
  status       TEXT,
  notes        TEXT
);

-- ----------------------------------------------------------------------------
-- 4. alerts - generated irrigation / moisture warnings (userId -> users.id)
-- ----------------------------------------------------------------------------
CREATE TABLE alerts(
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  userId    INTEGER NOT NULL,
  title     TEXT NOT NULL,
  message   TEXT NOT NULL,
  type      TEXT NOT NULL,
  isRead    INTEGER NOT NULL DEFAULT 0,
  createdAt TEXT NOT NULL
);

-- ----------------------------------------------------------------------------
-- 5. crop_scans - history of AI crop scanner results (userId -> users.id)
-- ----------------------------------------------------------------------------
CREATE TABLE crop_scans(
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  userId    INTEGER NOT NULL,
  cropName  TEXT,
  imagePath TEXT,
  condition TEXT,
  problem   TEXT,
  care      TEXT,
  createdAt TEXT NOT NULL
);

-- ----------------------------------------------------------------------------
-- 6. chat_history - questions and answers of the offline assistant
--    (userId -> users.id)
-- ----------------------------------------------------------------------------
CREATE TABLE chat_history(
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  userId    INTEGER NOT NULL,
  question  TEXT,
  answer    TEXT,
  createdAt TEXT NOT NULL
);

-- ----------------------------------------------------------------------------
-- 7. soil_readings - soil moisture, water level and irrigation record
--    (userId -> users.id, farmId -> farms.id)
--    Added in schema version 2 by DatabaseHelper._onUpgrade().
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS soil_readings(
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  userId                INTEGER NOT NULL,
  farmId                INTEGER NOT NULL,
  moisturePercent       REAL NOT NULL DEFAULT 0,
  waterLevelPercent     REAL NOT NULL DEFAULT 0,
  waterUsedLitres       REAL NOT NULL DEFAULT 0,
  waterRequiredLitres   REAL NOT NULL DEFAULT 0,
  minMoisturePercent    REAL NOT NULL DEFAULT 30,
  minWaterLevelPercent  REAL NOT NULL DEFAULT 25,
  note                  TEXT,
  createdAt             TEXT NOT NULL
);

-- ============================================================================
--  RECORDS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- users (2 rows)
--   id 10 : development database, created by test/layout_test.dart
--   id 1  : phone database, the account registered on the device
-- ----------------------------------------------------------------------------
INSERT INTO users (id, name, email, phone, password) VALUES
  (10, 'Test Farmer', 'layout@test.com', '9000000000', 'secret12'),
  (1,  'Ashok',       'ashok@gmail.com', '9874566321', '123456');

-- ----------------------------------------------------------------------------
-- farms (1 row)
-- ----------------------------------------------------------------------------
INSERT INTO farms (id, userId, farmName, location, farmSize, soilType,
                   mainCrop, description) VALUES
  (10, 10, 'Green Valley Farm', 'North field', '2 acres', 'Loamy', 'Rice', '');

-- ----------------------------------------------------------------------------
-- crops (0 rows - no crop has been added yet)
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- alerts (1 row)
-- ----------------------------------------------------------------------------
INSERT INTO alerts (id, userId, title, message, type, isRead, createdAt) VALUES
  (10, 10,
   'Low Soil Moisture: Green Valley Farm',
   'Soil moisture is 18%. The minimum for this crop is 35%. Water about 4300 litres today.',
   'Moisture Alert', 0, '2026-10-30T18:38:15.779455');

-- ----------------------------------------------------------------------------
-- crop_scans (0 rows)
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- chat_history (0 rows)
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- soil_readings (1 row)
--   The row was written by the layout test with farmId = 1, while the only
--   farm in the database has id = 10. The stored value is kept as it is.
-- ----------------------------------------------------------------------------
INSERT INTO soil_readings (id, userId, farmId, moisturePercent,
                           waterLevelPercent, waterUsedLitres,
                           waterRequiredLitres, minMoisturePercent,
                           minWaterLevelPercent, note, createdAt) VALUES
  (10, 10, 1, 18.0, 12.0, 900.0, 5200.0, 35.0, 25.0, '',
   '2026-10-30T18:38:15.771939');

COMMIT;

PRAGMA user_version = 2;
