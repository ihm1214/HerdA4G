import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:a4g/model.dart';
import 'package:shared_preferences/shared_preferences.dart';

// primary_service.dart is the "brain" of the whole app
// it loads data from JSON files, saves quiz scores, and tells the UI when scores change
// Used a quiz app tutorial to base our quiz off of https://www.youtube.com/watch?v=VEbNXOe2O04
// ChangeNotifier docs: https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html

// FirstAidService extends ChangeNotifier so it can tell widgets to rebuild when data changes
// any widget using AnimatedBuilder(animation: service) automatically redraws when notifyListeners() is called
class FirstAidService extends ChangeNotifier {
  // SharedPreferences keys - these are the string "labels" used to store data on the device
  // SharedPreferences stores key-value pairs kind of like a dictionary saved to the phone
  // SharedPreferences docs: https://pub.dev/packages/shared_preferences
  static const String _categoryCorrectAnswersKey =
      'category_quiz_correct_answers';
  static const String _categoryTotalQuestionsKey =
      'category_quiz_total_questions';

  // singleton pattern - only one instance of this class ever exists in the whole app
  // this means every screen reads and writes to the exact same score data
  // singleton / factory constructor explained: https://dart.dev/language/constructors#factory-constructors
  static final FirstAidService _instance = FirstAidService._internal();

  factory FirstAidService() => _instance; // every "new" FirstAidService() returns the same object

  FirstAidService._internal(); // private constructor so nothing outside can create a second copy

  // overall totals across all categories (sum of all per-category scores)
  int _correctAnswers = 0;
  int _totalQuestions = 0;

  // per-category score maps, keyed by category ID string like "burns" or "cuts"
  final Map<String, int> _categoryCorrectAnswers = {};
  final Map<String, int> _categoryTotalQuestions = {};

  // public getters - other files can read these but not change them directly
  int get correctAnswers => _correctAnswers;
  int get totalQuestions => _totalQuestions;
  // correctProgress is a 0.0-1.0 value used for progress bars
  double get correctProgress =>
      _totalQuestions == 0 ? 0 : _correctAnswers / _totalQuestions;

  // returns how many questions a specific category got correct (0 if never answered)
  int getCategoryCorrectAnswers(String categoryId) {
    return _categoryCorrectAnswers[categoryId] ?? 0;
  }

  // returns how many questions exist in a specific category (0 if not seeded yet)
  int getCategoryTotalQuestions(String categoryId) {
    return _categoryTotalQuestions[categoryId] ?? 0;
  }

  // resetAllProgress wipes every score from memory and from the device storage
  // called when the user hits "Reset All Progress" in the settings screen
  void resetAllProgress() {
    _categoryCorrectAnswers.clear();
    _categoryTotalQuestions.clear();
    _correctAnswers = 0;
    _totalQuestions = 0;
    notifyListeners();        // tell all AnimatedBuilders to redraw with zeroed scores
    _saveStoredQuizProgress(); // write the zeroed scores to SharedPreferences immediately
  }

  // getOverallProgress returns a CategoryQuizProgress object for the settings summary card
  CategoryQuizProgress getOverallProgress() {
    return CategoryQuizProgress(
      categoryId: 'overall',
      correctAnswers: _correctAnswers,
      totalQuestions: _totalQuestions,
    );
  }

  // getCategoryProgress returns a 0.0-1.0 fraction for one category's progress bar
  double getCategoryProgress(String categoryId) {
    final total = getCategoryTotalQuestions(categoryId);
    if (total == 0) return 0; // guard against dividing by zero
    return getCategoryCorrectAnswers(categoryId) / total;
  }

  // getCategoryQuizProgress returns the full progress object for one category
  // used by the home screen category cards to show the score and progress bar
  CategoryQuizProgress getCategoryQuizProgress(String categoryId) {
    return CategoryQuizProgress(
      categoryId: categoryId,
      correctAnswers: getCategoryCorrectAnswers(categoryId),
      totalQuestions: getCategoryTotalQuestions(categoryId),
    );
  }

  // setCategoryQuizProgress updates the score for one category after a quiz answer is submitted
  // saves to SharedPreferences right away so the score is never lost if the app closes
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
    _syncOverallProgress();    // recalculate the grand total across all categories
    notifyListeners();          // tell the home screen cards to redraw their progress bars
    _saveStoredQuizProgress(); // persist to device storage
  }

  // setQuizProgress sets totals directly - used less often than setCategoryQuizProgress
  void setQuizProgress({
    required int correctAnswers,
    required int totalQuestions,
  }) {
    _correctAnswers = correctAnswers;
    _totalQuestions = totalQuestions;
    notifyListeners();
  }

  // _syncOverallProgress adds up all per-category counts into the grand total
  // called any time a category score changes so the overall totals stay in sync
  void _syncOverallProgress() {
    // fold() is basically a loop that accumulates a running total
    _correctAnswers = _categoryCorrectAnswers.values.fold(
      0,
      (sum, value) => sum + value,
    );
    _totalQuestions = _categoryTotalQuestions.values.fold(
      0,
      (sum, value) => sum + value,
    );
  }

  // resetQuizProgress does the same thing as resetAllProgress
  // kept here so nothing breaks if it's called from somewhere else
  void resetQuizProgress() {
    _correctAnswers = 0;
    _totalQuestions = 0;
    _categoryCorrectAnswers.clear();
    _categoryTotalQuestions.clear();
    notifyListeners();
    _saveStoredQuizProgress();
  }

  // loadStoredQuizProgress reads saved scores from the device when the app starts
  // called in main.dart before the home screen shows so progress bars are correct immediately
  Future<void> loadStoredQuizProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final storedCorrectAnswers = prefs.getString(_categoryCorrectAnswersKey);
    final storedTotalQuestions = prefs.getString(_categoryTotalQuestionsKey);

    // decode the saved JSON strings back into Dart maps
    // SharedPreferences can only store strings so we encoded the maps as JSON when saving
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

  // loadCategoryQuestionCounts reads questions.json and fills in the total question counts
  // so the home screen shows "0/5" not "0/0" even before any quiz has been taken
  // rootBundle docs: https://api.flutter.dev/flutter/services/rootBundle.html
  // Assets loading docs: https://docs.flutter.dev/ui/assets/assets-and-images
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
    } catch (e) {} // silently ignore - app still works if this fails, just shows 0/0
  }

  // _saveStoredQuizProgress writes current scores to persistent device storage
  // called every time scores change so nothing is lost if the app closes unexpectedly
  Future<void> _saveStoredQuizProgress() async {
    final prefs = await SharedPreferences.getInstance();
    // jsonEncode turns the maps into JSON strings because SharedPreferences only stores strings
    await prefs.setString(
      _categoryCorrectAnswersKey,
      jsonEncode(_categoryCorrectAnswers),
    );
    await prefs.setString(
      _categoryTotalQuestionsKey,
      jsonEncode(_categoryTotalQuestions),
    );
  }

  // _decodeIntMap converts a JSON string like '{"burns":3,"cuts":1}' back into a Dart Map
  // returns an empty map if the string is null, empty, or malformed
  Map<String, int> _decodeIntMap(String? encoded) {
    if (encoded == null || encoded.isEmpty) {
      return <String, int>{}; // nothing was stored yet - return empty map
    }

    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic>) {
      return <String, int>{}; // corrupted data - return empty map to be safe
    }

    return decoded.map((key, value) => MapEntry(key, value as int));
  }

  // JSON linking made with help from https://www.youtube.com/watch?v=tgvfhWqS39o
  // loadCategories reads ailments.json and builds the list of categories for the home screen
  Future<List<AilmentCategory>> loadCategories() async {
    final String jsonString = await rootBundle.loadString(
      'assets/data/ailments.json',
    );
    final Map<String, dynamic> data = json.decode(jsonString);
    // loop through the "categories" array in the JSON and parse each one into an AilmentCategory
    return (data['categories'] as List)
        .map((c) => AilmentCategory.fromJson(c))
        .toList();
  }
}
