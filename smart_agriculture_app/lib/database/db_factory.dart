import 'db_factory_stub.dart'
    if (dart.library.js_interop) 'db_factory_web.dart'
    if (dart.library.io) 'db_factory_io.dart'
    as db_factory;

/// Ensures the correct [databaseFactory] is active for the current platform
/// before the database is opened.
Future<void> initializeDatabaseFactory() {
  return db_factory.initializeDatabaseFactory();
}
