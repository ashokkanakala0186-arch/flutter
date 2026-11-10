import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'
    show databaseFactoryFfiWeb;

bool _initialized = false;

Future<void> initializeDatabaseFactory() async {
  if (_initialized) return;
  _initialized = true;
  databaseFactory = databaseFactoryFfiWeb;
}
