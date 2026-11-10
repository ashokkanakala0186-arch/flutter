import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../models/user.dart';

class SessionService {
  SessionService._();

  static final SessionService instance = SessionService._();

  User? currentUser;

  static const String _userIdKey = 'logged_in_user_id';

  // ------------------------------------------------------------
  // CHECK LOGIN STATUS
  // ------------------------------------------------------------

  bool get isLoggedIn {
    return currentUser != null;
  }

  // ------------------------------------------------------------
  // GET CURRENT USER ID
  // ------------------------------------------------------------

  int? get userId {
    return currentUser?.id;
  }

  // ------------------------------------------------------------
  // SAVE USER SESSION
  // ------------------------------------------------------------

  Future<void> setUser(User user) async {
    if (user.id == null) {
      throw ArgumentError('Cannot save a session for a user without an id.');
    }

    currentUser = user;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_userIdKey, user.id!);
  }

  // ------------------------------------------------------------
  // RESTORE USER SESSION
  // ------------------------------------------------------------

  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();

    final int? savedUserId = prefs.getInt(_userIdKey);

    // No saved user ID
    if (savedUserId == null) {
      currentUser = null;
      return false;
    }

    final int userId = savedUserId;

    try {
      final User? user = await DatabaseHelper.instance.getUserById(userId);

      if (user != null) {
        currentUser = user;
        return true;
      }

      // User no longer exists in SQLite
      await prefs.remove(_userIdKey);

      currentUser = null;

      return false;
    } catch (e) {
      currentUser = null;
      return false;
    }
  }

  // ------------------------------------------------------------
  // LOGOUT
  // ------------------------------------------------------------

  Future<void> clear() async {
    currentUser = null;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_userIdKey);
  }
}
