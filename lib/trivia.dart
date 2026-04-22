import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:a4g/model.dart';
import 'services/primary_service.dart';

class TriviaApp extends StatelessWidget {
  final String categoryId;
  final String categoryName;

  const TriviaApp({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'First Aid Trivia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFCC0000),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: TriviaScreen(categoryId: categoryId, categoryName: categoryName),
    );
  }
}

const Color kRed = Color(0xFFCC0000);
const Color kRedLight = Color(0xFFFFEBEB);
const Color kRedDark = Color(0xFF990000);
const Color kGreen = Color(0xFF2E7D32);
const Color kGreenLight = Color(0xFFE8F5E9);
const Color kWhite = Colors.white;
const Color kBackground = Color(0xFFF5F5F5);
const Color kTileDefault = Color(0xFFFAFAFA);
const Color kBorder = Color(0xFFDDDDDD);
const Color kTextDark = Color(0xFF1A1A1A);
const Color kTextMuted = Color(0xFF666666);

// Screen Setup

class TriviaScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const TriviaScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> {
  final FirstAidService _service = FirstAidService();

  int _questionIndex = 0;
  int? _selectedAnswer;
  List<TriviaQuestion> _questions = [];
  final Map<int, bool> _questionResults = {};
  bool _loading = true;
  String? _error;

  TriviaQuestion get _current => _questions[_questionIndex];
  bool get _answered => _selectedAnswer != null;
  bool get _isLast => _questionIndex == _questions.length - 1;
  int get _correctCount =>
      _questionResults.values.where((isCorrect) => isCorrect).length;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final raw = await DefaultAssetBundle.of(
        context,
      ).loadString('assets/data/ailments.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final loaded = (decoded['Questions'] as List)
          .map((e) => TriviaQuestion.fromJson(e as Map<String, dynamic>))
          .toList();
      _questionResults.clear();
      final existingProgress = _service.getCategoryQuizProgress(
        widget.categoryId,
      );
      final needsInit = existingProgress.totalQuestions == 0;
      final totalQuestions = loaded.length;
      final correctAnswers = needsInit
          ? 0
          : existingProgress.correctAnswers.clamp(0, totalQuestions);

      _service.setCategoryQuizProgress(
        categoryId: widget.categoryId,
        correctAnswers: correctAnswers,
        totalQuestions: totalQuestions,
      );
      setState(() {
        _questions = loaded;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load questions: $e';
        _loading = false;
      });
    }
  }

  void _pickAnswer(int index) {
    if (_answered) return;
    final bool isCorrect = index == _current.correctIndex;
    setState(() {
      _selectedAnswer = index;
      _questionResults[_questionIndex] = isCorrect;
    });
    _service.setCategoryQuizProgress(
      categoryId: widget.categoryId,
      correctAnswers: _correctCount,
      totalQuestions: _questions.length,
    );
  }

  void _goNext() {
    if (!_isLast) {
      setState(() {
        _questionIndex++;
        _selectedAnswer = null;
      });
    }
  }

  void _goPrev() {
    if (_questionIndex > 0) {
      setState(() {
        _questionIndex--;
        _selectedAnswer = null;
      });
    }
  }

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();
  }

  //Build
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: kBackground,
        body: Center(child: CircularProgressIndicator(color: kRed)),
      );
    }

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
                      borderRadius: BorderRadius.circular(10),
                    ),
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildQuestionCard(),
                  const SizedBox(height: 16),
                  _buildAnswerGrid(),
                  const SizedBox(height: 16),
                  if (_answered) _buildNextButton(),
                  const SizedBox(height: 12),
                  _buildNavBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Header

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: kRed,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: kRed, blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: _goBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: kRed,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // First Aid Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(child: Icon(Icons.add, color: kRed, size: 26)),
          ),
          const SizedBox(width: 12),
          const Text(
            'First Aid Trivia',
            style: TextStyle(
              color: kWhite,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Text(
            widget.categoryName,
            style: const TextStyle(
              color: kWhite,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_questionIndex + 1} / ${_questions.length}',
              style: const TextStyle(
                color: kWhite,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Question Block

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
            color: Colors.black,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                color: kRedDark,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _current.question,
              style: const TextStyle(
                fontSize: 18,
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

  // 2 x 2 question grid

  Widget _buildAnswerGrid() {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 500;
          if (wide) {
            return Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildTile(0)),
                      const SizedBox(width: 14),
                      Expanded(child: _buildTile(1)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildTile(2)),
                      const SizedBox(width: 14),
                      Expanded(child: _buildTile(3)),
                    ],
                  ),
                ),
              ],
            );
          } else {
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

  Widget _buildTile(int index) {
    final bool isCorrect = index == _current.correctIndex;
    final bool isSelected = _selectedAnswer == index;
    const labels = ['A', 'B', 'C', 'D'];

    Color bgColor = kTileDefault;
    Color borderColor = kBorder;
    Color textColor = kTextDark;
    Color labelBg = kRedLight;
    Color labelFg = kRedDark;
    IconData? icon;

    if (_answered) {
      if (isCorrect) {
        bgColor = kGreenLight;
        borderColor = kGreen;
        textColor = kGreen;
        labelBg = kGreen;
        labelFg = kWhite;
        icon = Icons.check_circle_rounded;
      } else if (isSelected) {
        bgColor = kRedLight;
        borderColor = kRed;
        textColor = kRedDark;
        labelBg = kRed;
        labelFg = kWhite;
        icon = Icons.cancel_rounded;
      } else {
        borderColor = kBorder.withOpacity(0.5);
        textColor = kTextMuted;
      }
    }

    return GestureDetector(
      onTap: () => _pickAnswer(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: (isSelected || (_answered && isCorrect))
              ? [
                  BoxShadow(
                    color: borderColor,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                //this is where to adjust the answer dimensions
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: labelBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: labelFg,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _current.answers[index],
                  style: TextStyle(
                    color: textColor,
                    fontSize: MediaQuery.of(context).size.width > 800 ? 20 : MediaQuery.of(context).size.width > 600 ? 15 : 10,
                    
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    icon,
                    key: ValueKey(icon),
                    color: isCorrect ? kGreen : kRed,
                    size: 24,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Next Button

  Widget _buildNextButton() {
    return AnimatedOpacity(
      opacity: _answered ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLast ? null : _goNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: kRed,
            foregroundColor: kWhite,
            disabledBackgroundColor: kBorder,
            disabledForegroundColor: kTextMuted,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: Text(
            _isLast ? 'Finished!' : 'Next Question',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  // Nav Bar

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
            enabled: _questionIndex > 0,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TriviaApp(
                  categoryId: widget.categoryId,
                  categoryName: widget.categoryName,
                ),
              ),
            ),
          ),
          Row(
            children: List.generate(_questions.length, (i) {
              final active = i == _questionIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? kRed : kBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          _NavButton(
            icon: Icons.arrow_forward_ios_rounded,
            label: 'Next',
            enabled: _questionIndex < _questions.length - 1,
            onTap: _goNext,
            reversed: true,
          ),
        ],
      ),
    );
  }
}

// Navigation Buttons

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final bool reversed;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.reversed = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? kRed : kTextMuted.withOpacity(0.4);
    final kids = <Widget>[
      if (!reversed) ...[
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
      ],
      Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      if (reversed) ...[
        const SizedBox(width: 6),
        Icon(icon, color: color, size: 18),
      ],
    ];
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? kRedLight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: enabled ? kRed : Colors.transparent),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: kids),
      ),
    );
  }
}
