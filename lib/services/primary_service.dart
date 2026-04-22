import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:a4g/model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirstAidService extends ChangeNotifier {
  static const String _categoryCorrectAnswersKey =
      'category_quiz_correct_answers';
  static const String _categoryTotalQuestionsKey =
      'category_quiz_total_questions';

  static final FirstAidService _instance = FirstAidService._internal();

  factory FirstAidService() => _instance;

  FirstAidService._internal();

  int _correctAnswers = 0;
  int _totalQuestions = 0;
  final Map<String, int> _categoryCorrectAnswers = {};
  final Map<String, int> _categoryTotalQuestions = {};

  int get correctAnswers => _correctAnswers;
  int get totalQuestions => _totalQuestions;
  double get correctProgress =>
      _totalQuestions == 0 ? 0 : _correctAnswers / _totalQuestions;

  int getCategoryCorrectAnswers(String categoryId) {
    return _categoryCorrectAnswers[categoryId] ?? 0;
  }

  int getCategoryTotalQuestions(String categoryId) {
    return _categoryTotalQuestions[categoryId] ?? 0;
  }

  double getCategoryProgress(String categoryId) {
    final total = getCategoryTotalQuestions(categoryId);
    if (total == 0) return 0;
    return getCategoryCorrectAnswers(categoryId) / total;
  }

  CategoryQuizProgress getCategoryQuizProgress(String categoryId) {
    return CategoryQuizProgress(
      categoryId: categoryId,
      correctAnswers: getCategoryCorrectAnswers(categoryId),
      totalQuestions: getCategoryTotalQuestions(categoryId),
    );
  }

  void setCategoryQuizProgress({
    required String categoryId,
    required int correctAnswers,
    required int totalQuestions,
  }) {
    _categoryCorrectAnswers[categoryId] = correctAnswers;
    _categoryTotalQuestions[categoryId] = totalQuestions;
    _syncOverallProgress();
    notifyListeners();
    _saveStoredQuizProgress();
  }

  void setQuizProgress({
    required int correctAnswers,
    required int totalQuestions,
  }) {
    _correctAnswers = correctAnswers;
    _totalQuestions = totalQuestions;
    notifyListeners();
  }

  void _syncOverallProgress() {
    _correctAnswers = _categoryCorrectAnswers.values.fold(
      0,
      (sum, value) => sum + value,
    );
    _totalQuestions = _categoryTotalQuestions.values.fold(
      0,
      (sum, value) => sum + value,
    );
  }

  void resetQuizProgress() {
    _correctAnswers = 0;
    _totalQuestions = 0;
    _categoryCorrectAnswers.clear();
    _categoryTotalQuestions.clear();
    notifyListeners();
    _saveStoredQuizProgress();
  }

  Future<void> loadStoredQuizProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final storedCorrectAnswers = prefs.getString(_categoryCorrectAnswersKey);
    final storedTotalQuestions = prefs.getString(_categoryTotalQuestionsKey);

    _categoryCorrectAnswers
      ..clear()
      ..addAll(_decodeIntMap(storedCorrectAnswers));
    _categoryTotalQuestions
      ..clear()
      ..addAll(_decodeIntMap(storedTotalQuestions));

    _syncOverallProgress();
    notifyListeners();
  }

  Future<void> _saveStoredQuizProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _categoryCorrectAnswersKey,
      jsonEncode(_categoryCorrectAnswers),
    );
    await prefs.setString(
      _categoryTotalQuestionsKey,
      jsonEncode(_categoryTotalQuestions),
    );
  }

  Map<String, int> _decodeIntMap(String? encoded) {
    if (encoded == null || encoded.isEmpty) {
      return <String, int>{};
    }

    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic>) {
      return <String, int>{};
    }

    return decoded.map((key, value) => MapEntry(key, value as int));
  }

  // ─── Load JSON from assets ───────────────────────────────────────────────
  Future<List<AilmentCategory>> loadCategories() async {
    final String jsonString = await rootBundle.loadString(
      'assets/data/ailments.json',
    );
    final Map<String, dynamic> data = json.decode(jsonString);
    return (data['categories'] as List)
        .map((c) => AilmentCategory.fromJson(c))
        .toList();
  }
}
