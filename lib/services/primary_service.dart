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
    return (data['categories'] as List)
        .map((c) => AilmentCategory.fromJson(c))
        .toList();
  }
}