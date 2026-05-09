import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:a4g/model.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Used a quiz app tutorial to base our quiz off of https://www.youtube.com/watch?v=VEbNXOe2O04

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

  void resetAllProgress() {
    _categoryCorrectAnswers.clear();
    _categoryTotalQuestions.clear();
    _correctAnswers = 0;
    _totalQuestions = 0;
    notifyListeners();
    _saveStoredQuizProgress();
  }

  CategoryQuizProgress getOverallProgress() {
    return CategoryQuizProgress(
      categoryId: 'overall',
      correctAnswers: _correctAnswers,
      totalQuestions: _totalQuestions,
    );
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
    // Only update total if the new value is meaningful, to avoid
    // overwriting a seeded total with 0 during an edge-case load
    if (totalQuestions > 0) {
      _categoryTotalQuestions[categoryId] = totalQuestions;
    }
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

    // Seed question counts from JSON for any category not yet stored in prefs.
    // This ensures the home screen shows "0/N" instead of "0/0" before the
    // user has ever opened a quiz.
    await loadCategoryQuestionCounts();
    notifyListeners();
  }

  /// Reads questions.json and populates _categoryTotalQuestions for any
  /// category that doesn't already have a stored total.
  Future<void> loadCategoryQuestionCounts() async {
    try {
      final String raw =
          await rootBundle.loadString('assets/data/questions.json');
      final Map<String, dynamic> decoded = jsonDecode(raw);
      final List<dynamic> allCategories = decoded['Questions'] as List<dynamic>;

      for (final entry in allCategories) {
        final map = entry as Map<String, dynamic>;
        final id = map['id']?.toString().trim() ?? '';
        final items = map['items'] as List<dynamic>? ?? [];
        // Always overwrite total from JSON — it's the source of truth
        _categoryTotalQuestions[id] = items.length;
      }

      _syncOverallProgress();
    } catch (e) {}
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

  // JSON linking made with help from https://www.youtube.com/watch?v=tgvfhWqS39o

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
