import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:a4g/model.dart';
class FirstAidService {
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