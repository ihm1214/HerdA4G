import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'model.dart';
import 'services/primary_service.dart';

// trivia.dart is the quiz screen where users test their first aid knowledge
// it loads questions from questions.json, tracks which ones were answered,
// and saves progress so the quiz can be resumed if the app is closed mid-quiz
// SharedPreferences docs: https://pub.dev/packages/shared_preferences

//TriviaApp structure inspired by : https://api.flutter.dev/flutter/widgets/StatelessWidget-class.html
// TriviaApp is a mini MaterialApp wrapper just for the quiz screen
// it gets its own theme (red color scheme) separate from the main app's pink theme
class TriviaApp extends StatelessWidget {
  final String categoryId;
  final String categoryName;

  const TriviaApp(
      {super.key, required this.categoryId, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'First Aid Trivia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFCC0000), // red seed for the quiz's color palette
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: TriviaScreen(category: categoryId),
    );
  }
}

//Global color scheme inspired by : https://api.flutter.dev/flutter/dart-ui/Color-class.html
// these constants define the quiz screen's color palette so they're easy to reuse everywhere
const Color kRed = Color(0xFFCC0000);
const Color kRedLight = Color(0xFFFFEBEB);   // faint red for backgrounds
const Color kRedDark = Color(0xFF990000);    // darker red for text on light backgrounds
const Color kGreen = Color(0xFF2E7D32);
const Color kGreenLight = Color(0xFFE8F5E9); // faint green for correct answer background
const Color kWhite = Colors.white;
const Color kBackground = Color(0xFFF5F5F5); // light grey page background
const Color kTileDefault = Color(0xFFFAFAFA); // off-white for answer tiles
const Color kBorder = Color(0xFFDDDDDD);
const Color kTextDark = Color(0xFF1A1A1A);   // near-black for main text
const Color kTextMuted = Color(0xFF666666);  // grey for disabled/secondary text

// Screen Setup inspired by: https://api.flutter.dev/flutter/widgets/StatefulWidget-class.html
class TriviaScreen extends StatefulWidget {
  final String category; // e.g. "burns", "cuts" - matches IDs in questions.json

  const TriviaScreen({super.key, required this.category});

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> {
  final FirstAidService _service = FirstAidService(); // the singleton service for saving scores
  int _questionIndex = 0;                              // which question is currently showing
  int? _selectedAnswer;                                // index of the answer the user picked (null = not answered yet)
  final Map<int, int> _selectedAnswersByQuestion = {}; // maps question index → selected answer index
  final Map<int, bool> _questionResults = {};          // maps question index → true/false (correct/wrong)
  List<TriviaQuestion> _questions = [];                // all questions for this category
  bool _loading = true;
  String? _error;

  // SharedPreferences keys for saving quiz session state between app restarts
  // each key includes the category name so different categories don't overwrite each other
  String get _sessionIndexKey => 'trivia_${widget.category}_index';
  String get _sessionResultsKey => 'trivia_${widget.category}_results';
  String get _sessionAnswersKey => 'trivia_${widget.category}_answers';

  // convenience getters to keep the build methods cleaner
  TriviaQuestion get _current => _questions[_questionIndex]; // the question currently on screen
  bool get _answered => _selectedAnswer != null;             // true if user has picked an answer
  bool get _isLast => _questionIndex == _questions.length - 1; // true on the final question

  @override
  void initState() {
    super.initState();
    _loadQuestions(); // load questions from JSON and restore any saved session
  }

  //Loading assets in loadQuestions inspired by: https://docs.flutter.dev/ui/assets/assets-and-images
  // _saveSession writes the current question index and all answers to SharedPreferences
  // called after every answer and navigation so progress survives the app being closed
  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionIndexKey, _questionIndex);
    // encode the maps as JSON strings because SharedPreferences only stores strings/ints/bools
    await prefs.setString(_sessionResultsKey, jsonEncode(_questionResults));
    await prefs.setString(
      _sessionAnswersKey,
      jsonEncode(_selectedAnswersByQuestion),
    );
  }

  // _clearSession wipes the saved session when the quiz is completed
  // this ensures the quiz starts fresh next time but the category score stays saved
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionIndexKey);
    await prefs.remove(_sessionResultsKey);
    await prefs.remove(_sessionAnswersKey);
  }

  // _decodeIntMap converts a JSON string like '{"0":2,"1":3}' back into a Dart Map<int,int>
  // used to restore the selected answers map from SharedPreferences
  Map<int, int> _decodeIntMap(String? encoded) {
    if (encoded == null || encoded.isEmpty) {
      return <int, int>{}; // nothing stored = return empty map
    }

    final decoded = jsonDecode(encoded);
    if (decoded is! Map) {
      return <int, int>{}; // malformed data = return empty map
    }

    // JSON keys are always strings so we convert them back to ints
    return decoded.map<int, int>((key, value) {
      return MapEntry(int.parse(key.toString()), value as int);
    });
  }

  // _decodeBoolMap converts a JSON string like '{"0":true,"1":false}' back into Map<int,bool>
  // used to restore the correct/wrong results map from SharedPreferences
  Map<int, bool> _decodeBoolMap(String? encoded) {
    if (encoded == null || encoded.isEmpty) {
      return <int, bool>{};
    }

    final decoded = jsonDecode(encoded);
    if (decoded is! Map) {
      return <int, bool>{};
    }

    return decoded.map<int, bool>((key, value) {
      return MapEntry(int.parse(key.toString()), value as bool);
    });
  }

  // _syncStoredProgress counts up the correct answers from the session results
  // and saves that count to the service so it shows on the home screen progress bar
  void _syncStoredProgress() {
    // count how many values in _questionResults are true (correct)
    final correctAnswers =
        _questionResults.values.where((value) => value).length;
    _service.setCategoryQuizProgress(
      categoryId: widget.category,
      correctAnswers: correctAnswers,
      totalQuestions: _questions.length,
    );
  }

  // _loadQuestions reads questions.json, finds the right category block,
  // then restores any saved session data from SharedPreferences
  Future<void> _loadQuestions() async {
    try {
      // DefaultAssetBundle is how Flutter loads files from the assets/ folder
      final raw = await DefaultAssetBundle.of(context)
          .loadString('assets/data/questions.json');

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final allCategories = decoded['Questions'] as List<dynamic>;

      // Use firstWhere with orElse to safely find the matching category
      // returns null instead of throwing an exception if the category isn't found
      final categoryBlock = allCategories.firstWhere(
        (e) =>
            (e as Map<String, dynamic>)['id']?.toString().trim() ==
            widget.category.trim(),
        orElse: () => null,
      ) as Map<String, dynamic>?;

      if (categoryBlock == null) {
        // no questions exist for this category - show error instead of crashing
        setState(() {
          _error = 'No questions found for: "${widget.category}"';
          _loading = false;
        });
        return;
      }

      // parse each item in the "items" list into a TriviaQuestion model
      final items = categoryBlock['items'] as List<dynamic>;
      final loaded = items
          .map((e) => TriviaQuestion.fromJson(e as Map<String, dynamic>))
          .toList();

      // read back any previously saved session state from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt(_sessionIndexKey) ?? 0;
      final savedAnswers = _decodeIntMap(prefs.getString(_sessionAnswersKey));
      final savedResults = _decodeBoolMap(prefs.getString(_sessionResultsKey));

      // clamp the saved index so we don't go out of bounds if question count changed
      final restoredIndex =
          loaded.isEmpty ? 0 : savedIndex.clamp(0, loaded.length - 1).toInt();

      setState(() {
        _questions = loaded;
        _questionIndex = restoredIndex;
        // restore the answer selections so previously answered questions stay filled in
        _selectedAnswersByQuestion
          ..clear()
          ..addAll(savedAnswers);
        _questionResults
          ..clear()
          ..addAll(savedResults);
        // restore the selection indicator for whichever question we're resuming on
        _selectedAnswer = _selectedAnswersByQuestion[_questionIndex];
        _loading = false;
      });

      // only sync progress if the saved session actually has answers
      // if savedResults is empty it means no answers were recorded yet,
      // and we don't want to accidentally overwrite a real score with 0
      if (savedResults.isNotEmpty) {
        _syncStoredProgress();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load questions: $e';
        _loading = false;
      });
    }
  }

  // _pickAnswer is called when the user taps one of the four answer tiles
  // it records the selection, marks it correct/wrong, then saves everything
  void _pickAnswer(int index) {
    if (_answered) return; // already answered - don't let them change it
    setState(() {
      _selectedAnswer = index;
      _selectedAnswersByQuestion[_questionIndex] = index; // remember which answer they picked
      // record whether this question was answered correctly (true/false)
      _questionResults[_questionIndex] = index == _current.correctIndex;
    });

    _syncStoredProgress(); // update the home screen progress bar immediately
    _saveSession();        // persist to device storage so it survives app close
  }

  // _goNext moves forward one question and restores that question's previous selection if any
  void _goNext() {
    if (!_isLast) {
      setState(() {
        _questionIndex++;
        // if this question was already answered before, restore the selection so it shows
        _selectedAnswer = _selectedAnswersByQuestion[_questionIndex];
      });

      _saveSession(); // save the new position
    }
  }

  // _goPrev moves back one question and restores the previous answer selection
  void _goPrev() {
    if (_questionIndex > 0) {
      setState(() {
        _questionIndex--;
        _selectedAnswer = _selectedAnswersByQuestion[_questionIndex];
      });

      _saveSession();
    }
  }

//Build
//Scaffolding inspired by: https://api.flutter.dev/flutter/material/Scaffold-class.html
  @override
  Widget build(BuildContext context) {
    // show a loading spinner while questions are being fetched
    if (_loading) {
      return const Scaffold(
        backgroundColor: kBackground,
        body: Center(
          child: CircularProgressIndicator(color: kRed),
        ),
      );
    }

    // show an error screen if questions failed to load
    if (_error != null) {
      return Scaffold(
        backgroundColor: kBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: kRed, size: 48),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kTextDark, fontSize: 15),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _loadQuestions();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kRed,
                    foregroundColor: kWhite,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackground,
      //SafeArea inspired by: https://docs.flutter.dev/ui/adaptive-responsive/safearea-mediaquery
      // SafeArea keeps content away from the phone's notch and home gesture bar
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800), // caps width on tablets/desktops
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  _buildHeader(),      // red header bar with back button and question counter
                  const SizedBox(height: 20),
                  _buildQuestionCard(), // white card showing the question text
                  const SizedBox(height: 16),
                  _buildAnswerGrid(),   // 2x2 or 4-column grid of answer tiles
                  const SizedBox(height: 16),
                  if (_answered) _buildNextButton(), // only shows after an answer is selected
                  const SizedBox(height: 12),
                  _buildNavBar(),       // prev/next buttons and the dot progress indicator
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Header
  // _buildHeader creates the red top bar with a back button, title, and "Q/Total" counter
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: kRed,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: kRed.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // Back Button - pops back to the categories screen
          // rootNavigator: true makes sure it pops the TriviaApp MaterialApp wrapper too
          GestureDetector(
            onTap: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: kWhite, borderRadius: BorderRadius.circular(8)),
              child: const Center(
                child:
                    Icon(Icons.arrow_back_ios_rounded, color: kRed, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 22),
          const Text(
            'First Aid Trivia',
            style: TextStyle(
                color: kWhite,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5),
          ),
          const Spacer(), // pushes the counter pill to the right edge
          // pill showing current question number out of total, like "2 / 5"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kWhite.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_questionIndex + 1} / ${_questions.length}',
              style: const TextStyle(
                  color: kWhite, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Question Block
  // _buildQuestionCard shows the "Q1" badge and the question text in a white card
  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kRed.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Q1", "Q2" etc. badge in the top left of the card
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kRedLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: kRed.withOpacity(0.3)),
            ),
            child: Text(
              'Q${_questionIndex + 1}',
              style: const TextStyle(
                  color: kRedDark, fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ),
          const SizedBox(width: 14),
          // the actual question text, expands to fill remaining width
          Expanded(
            child: Text(
              _current.question,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w600,
                color: kTextDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2 x 2 question layout inspired by: https://api.flutter.dev/flutter/widgets/LayoutBuilder-class.html
  // _buildAnswerGrid arranges the 4 answer tiles in a 2x2 grid on wide screens
  // or a single column on narrow screens
  Widget _buildAnswerGrid() {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 500; // wide enough for 2 columns?
          if (wide) {
            // 2x2 grid layout for tablets/wide phones
            return Column(
              children: [
                Expanded(
                  child: Row(children: [
                    Expanded(child: _buildTile(0)),
                    const SizedBox(width: 14),
                    Expanded(child: _buildTile(1)),
                  ]),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Row(children: [
                    Expanded(child: _buildTile(2)),
                    const SizedBox(width: 14),
                    Expanded(child: _buildTile(3)),
                  ]),
                ),
              ],
            );
          } else {
            // single column layout for narrow phones - all 4 tiles stacked vertically
            return Column(
              children: List.generate(
                4,
                (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: i < 3 ? 14 : 0),
                    child: _buildTile(i),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

//Individual tile build inspired by: https://docs.flutter.dev/cookbook/animation/animated-container
//                               and https://api.flutter.dev/flutter/widgets/AnimatedContainer-class.html
//                               and https://api.flutter.dev/flutter/widgets/GestureDetector-class.html
// _buildTile creates one answer tile (A, B, C, or D)
// the tile's colors change after an answer is submitted to show correct/wrong feedback
  Widget _buildTile(int index) {
    final bool isCorrect = index == _current.correctIndex; // true if this is the right answer
    final bool isSelected = _selectedAnswer == index;       // true if the user picked this one
    const labels = ['A', 'B', 'C', 'D'];

    // default colors for an unanswered tile
    Color bgColor = kTileDefault;
    Color borderColor = kBorder;
    Color textColor = kTextDark;
    Color labelBg = kRedLight;
    Color labelFg = kRedDark;
    IconData? icon;

    // after an answer is picked, update colors to show correct/wrong feedback
    if (_answered) {
      if (isCorrect) {
        // correct answer → go green
        bgColor = kGreenLight;
        borderColor = kGreen;
        textColor = kGreen;
        labelBg = kGreen;
        labelFg = kWhite;
        icon = Icons.check_circle_rounded;
      } else if (isSelected) {
        // wrong answer the user picked → go red
        bgColor = kRedLight;
        borderColor = kRed;
        textColor = kRedDark;
        labelBg = kRed;
        labelFg = kWhite;
        icon = Icons.cancel_rounded;
      } else {
        // other wrong answers that weren't selected → fade out
        borderColor = kBorder.withOpacity(0.5);
        textColor = kTextMuted;
      }
    }

    return GestureDetector(
      onTap: () => _pickAnswer(index), // tapping calls _pickAnswer with this tile's index
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250), // smooth color transition
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
          // add a glow shadow on selected/correct tiles to make them pop
          boxShadow: (isSelected || (_answered && isCorrect))
              ? [
                  BoxShadow(
                      color: borderColor.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              // the A/B/C/D label badge on the left of each tile
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: labelBg, borderRadius: BorderRadius.circular(8)),
                child: Center(
                  child: Text(
                    labels[index],
                    style: TextStyle(
                        color: labelFg,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // the answer text - font size scales down on smaller screens
              Expanded(
                child: Text(
                  _current.answers[index],
                  style: TextStyle(
                    color: textColor,
                    fontSize: MediaQuery.of(context).size.width > 800
                        ? 20
                        : MediaQuery.of(context).size.width > 600
                            ? 15
                            : 10,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
              // check or X icon only shows after an answer is selected
              if (icon != null) ...[
                const SizedBox(width: 8),
                //Animation for switching inspired by: https://api.flutter.dev/flutter/widgets/AnimatedSwitcher-class.html
                // AnimatedSwitcher fades between the old icon and the new icon smoothly
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(icon,
                      key: ValueKey(icon),
                      color: isCorrect ? kGreen : kRed,
                      size: 24),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Next Button inspired by: https://docs.flutter.dev/cookbook/animation/opacity-animation
  //                      and https://api.flutter.dev/flutter/material/ElevatedButton-class.html
  // _buildNextButton shows "Next Question" or "Finished!" depending on whether this is the last question
  // it fades in with AnimatedOpacity after an answer is selected
  Widget _buildNextButton() {
    return AnimatedOpacity(
      opacity: _answered ? 1.0 : 0.0, // fade in when answered, invisible when not
      duration: const Duration(milliseconds: 300),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLast
              ? () async {
                  // on the last question: clear the session and go back
                  // clearSession removes the in-progress save so next open starts fresh
                  await _clearSession();
                  Navigator.of(context, rootNavigator: true).pop();
                }
              : _goNext, // on any other question: just advance
          style: ElevatedButton.styleFrom(
            backgroundColor: _isLast ? kGreen : kRed, // green on the final question
            foregroundColor: kWhite,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: _isLast ? 4 : 0,
            shadowColor: _isLast ? kGreen.withOpacity(0.5) : null,
          ),
          child: Text(
            _isLast ? 'Finished!' : 'Next Question',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // Nav Bar inspired by: https://docs.flutter.dev/cookbook/navigation/navigation-basics
  //                  and https://api.flutter.dev/flutter/widgets/Navigator/pop.html
  //                  and https://docs.flutter.dev/ui/navigation
  // _buildNavBar shows Prev/Next buttons and a row of animated dots showing the current position
  Widget _buildNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavButton(
            icon: Icons.arrow_back_ios_rounded,
            label: 'Prev',
            enabled: _questionIndex > 0, // disabled on the first question
            onTap: _goPrev,
          ),
          // animated dot row - active question gets a wider pill, others get small circles
          Row(
            children: List.generate(_questions.length, (i) {
              final active = i == _questionIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 20 : 8,  // active dot is wider to look like a pill
                height: 8,
                decoration: BoxDecoration(
                  color: active ? kRed : kBorder, // active dot is red, others are grey
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          _NavButton(
            icon: Icons.arrow_forward_ios_rounded,
            label: 'Next',
            enabled: _questionIndex < _questions.length - 1, // disabled on the last question
            onTap: _goNext,
            reversed: true, // puts the icon on the right side of the text
          ),
        ],
      ),
    );
  }
}

// Navigation Buttons inspired by: https://api.flutter.dev/flutter/widgets/StatelessWidget-class.html
//                             and https://api.flutter.dev/flutter/dart-ui/VoidCallback.html
// _NavButton is the reusable Prev/Next button widget used in the nav bar
// it greys out automatically when enabled is false
class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;       // false = greyed out and not tappable
  final VoidCallback onTap;
  final bool reversed;      // if true, puts the icon after the label text (for "Next >")

  const _NavButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.reversed = false,
  });

  @override
  Widget build(BuildContext context) {
    // grey color when disabled, red when enabled
    final color = enabled ? kRed : kTextMuted.withOpacity(0.4);
    final kids = <Widget>[
      if (!reversed) ...[
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6)
      ],
      Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 14)),
      if (reversed) ...[
        const SizedBox(width: 6),
        Icon(icon, color: color, size: 18)
      ],
    ];
    return GestureDetector(
      onTap: enabled ? onTap : null, // null = GestureDetector ignores taps
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          // light red background when enabled, transparent when disabled
          color: enabled ? kRedLight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: enabled ? kRed.withOpacity(0.3) : Colors.transparent),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: kids),
      ),
    );
  }
}
