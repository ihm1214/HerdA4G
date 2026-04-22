import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:a4g/model.dart';
import 'package:flutter/foundation.dart';

class FirstAidService {
  static const String _prefLargeText = 'pref_large_text';
  static const String _prefShowImages = 'pref_show_images';
  static const String _prefDarkMode = 'pref_dark_mode';

  // ─── Load JSON from assets ───────────────────────────────────────────────
  Future<List<AilmentCategory>> loadCategories() async {
    final String jsonString =
      await rootBundle.loadString('assets/data/ailments.json');
    final Map<String, dynamic> data = json.decode(jsonString);
    debugPrint(JsonEncoder.withIndent('  ').convert(data));
    return (data['categories'] as List)
        .map((c) => AilmentCategory.fromJson(c))
        .toList();
  }

  // ─── SharedPreferences helpers ───────────────────────────────────────────
  Future<Map<String, bool>> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      _prefLargeText: prefs.getBool(_prefLargeText) ?? false,
      _prefShowImages: prefs.getBool(_prefShowImages) ?? true,
      _prefDarkMode: prefs.getBool(_prefDarkMode) ?? false,
    };
  }

  Future<void> savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // Convenience getters
  static String get keyLargeText => _prefLargeText;
  static String get keyShowImages => _prefShowImages;
  static String get keyDarkMode => _prefDarkMode;
}