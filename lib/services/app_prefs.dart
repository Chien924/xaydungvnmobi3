import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  static const String _introSeenKey = 'xaydungvn_intro_seen_v1';

  static Future<bool> introSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_introSeenKey) ?? false;
  }

  static Future<void> setIntroSeen(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_introSeenKey, value);
  }
}
