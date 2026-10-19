import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Always use ONE standard key name
  static const String _tokenKey = 'jwt_token';

  /// Save JWT Token after successful login/registration
  static Future saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    // Clear old data first to avoid key collisions
    await clearToken();
    await prefs.setString(_tokenKey, token);
  }

  /// Retrieve stored JWT Token
  static Future getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // Fallback to check both possible keys if one exists
    return prefs.getString(_tokenKey) ?? prefs.getString('p2p_auth_token') ?? prefs.getString('auth_token');
  }

  /// Completely wipe ALL storage data on logout or account switch
  static Future clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove('p2p_auth_token'); // Remove legacy key
    await prefs.remove('auth_token');     // Remove secondary key
    await prefs.remove('p2p_user_role');  // Remove saved role
    await prefs.clear();                   // Wipes ALL cached app preferences
  }
}