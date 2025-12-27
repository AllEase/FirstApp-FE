import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CacheStorage {
  static Future<void> save(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<void> saveObj(String key, Map<String, dynamic> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(value));
  }

  static Future<String?> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<Map<String, dynamic>?> getObj(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(key);
    if (jsonStr == null) return null;
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  static Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<void> debugDumpCache() async {
    print("started");
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys(); // Gets all stored keys

    print("--- 📱 CACHE DUMP ---");
    for (String key in keys) {
      print("$key: ${prefs.get(key)}");
    }
    print("---------------------");
  }
}
