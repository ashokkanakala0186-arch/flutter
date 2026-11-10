Future<void> initializeDatabaseFactory() async {
  // Fallback for unusual environments. Android/iOS register their own factory
  // via the sqflite plugin; web and desktop use the dedicated variants.
}
