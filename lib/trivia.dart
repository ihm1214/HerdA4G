import 'package:flutter/material.dart';

class TriviaApp extends StatelessWidget {
  const TriviaApp({super.key});

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
      home: const TriviaScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// Data model
//
// When your JSON is ready, replace the placeholder `questions` list below.
// Load your JSON (from assets, network, etc.) and map like:
//
//   final loaded = (jsonDecode(raw) as List)
//       .map((e) => TriviaQuestion.fromJson(e))
//       .toList();
//
// Expected JSON shape:
// [
//   {
//     "question": "...",
//     "answers": ["...", "...", "...", "..."],
//     "correctIndex": 0
//   }
// ]
// ---------------------------------------------------------------------------

class TriviaQuestion {
  final String question;
  final List<String> answers; // always 4 items
  final int correctIndex;     // 0–3

  const TriviaQuestion({
    required this.question,
    required this.answers,
    required this.correctIndex,
  });

  factory TriviaQuestion.fromJson(Map<String, dynamic> json) {
    return TriviaQuestion(
      question: json['question'] as String,
      answers: List<String>.from(json['answers'] as List),
      correctIndex: json['correctIndex'] as int,
    );
  }
}

// ← Replace this list with your JSON-loaded data when ready
final List<TriviaQuestion> questions = [
  const TriviaQuestion(
    question: 'Question',
    answers: ['1', '2', '3', '4'],
    correctIndex: 0,
  ),
];

// ---------------------------------------------------------------------------
// Colors
// ---------------------------------------------------------------------------

const Color kRed         = Color(0xFFCC0000);
const Color kRedLight    = Color(0xFFFFEBEB);
const Color kRedDark     = Color(0xFF990000);
const Color kGreen       = Color(0xFF2E7D32);
const Color kGreenLight  = Color(0xFFE8F5E9);
const Color kWhite       = Colors.white;
const Color kBackground  = Color(0xFFF5F5F5);
const Color kTileDefault = Color(0xFFFAFAFA);
const Color kBorder      = Color(0xFFDDDDDD);
const Color kTextDark    = Color(0xFF1A1A1A);
const Color kTextMuted   = Color(0xFF666666);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class TriviaScreen extends StatefulWidget {
  const TriviaScreen({super.key});

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> {
  int _questionIndex = 0;
  int? _selectedAnswer; // null = unanswered

  TriviaQuestion get _current => questions[_questionIndex];
  bool get _answered => _selectedAnswer != null;

  void _pickAnswer(int index) {
    if (_answered) return;
    setState(() => _selectedAnswer = index);
  }

  void _goNext() {
    if (_questionIndex < questions.length - 1) {
      setState(() { _questionIndex++; _selectedAnswer = null; });
    }
  }

  void _goPrev() {
    if (_questionIndex > 0) {
      setState(() { _questionIndex--; _selectedAnswer = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const SizedBox(height: 20),
                  _buildNavBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

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
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: kWhite, borderRadius: BorderRadius.circular(6)),
            child: const Center(child: Icon(Icons.add, color: kRed, size: 26)),
          ),
          const SizedBox(width: 12),
          const Text(
            'First Aid Trivia',
            style: TextStyle(color: kWhite, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_questionIndex + 1} / ${questions.length}',
              style: const TextStyle(color: kWhite, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ── Question card ─────────────────────────────────────────────────────────

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kRed, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black, blurRadius: 6, offset: const Offset(0, 2)),
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
              border: Border.all(color: kRed),
            ),
            child: Text(
              'Q${_questionIndex + 1}',
              style: const TextStyle(color: kRedDark, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _current.question,
              style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: kTextDark, height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2 × 2 answer grid ────────────────────────────────────────────────────

  Widget _buildAnswerGrid() {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 500;
          if (wide) {
            return Column(
              children: [
                Expanded(
                  child: Row(children: [
                    Expanded(child: _buildTile(0)),
                    const SizedBox(width: 14),
                    Expanded(child: _buildTile(1)),
                  ]),
                ),
                const SizedBox(height: 14),
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
            return Column(
              children: List.generate(4, (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: i < 3 ? 14 : 0),
                  child: _buildTile(i),
                ),
              )),
            );
          }
        },
      ),
    );
  }

  Widget _buildTile(int index) {
    final bool isCorrect  = index == _current.correctIndex;
    final bool isSelected = _selectedAnswer == index;
    const labels = ['1', '2', '3', '4'];

    Color bgColor     = kTileDefault;
    Color borderColor = kBorder;
    Color textColor   = kTextDark;
    Color labelBg     = kRedLight;
    Color labelFg     = kRedDark;
    IconData? icon;

    if (_answered) {
      if (isCorrect) {
        bgColor = kGreenLight; borderColor = kGreen;
        textColor = kGreen;   labelBg = kGreen; labelFg = kWhite;
        icon = Icons.check_circle_rounded;
      } else if (isSelected) {
        bgColor = kRedLight;  borderColor = kRed;
        textColor = kRedDark; labelBg = kRed; labelFg = kWhite;
        icon = Icons.cancel_rounded;
      } else {
        borderColor = kBorder;
        textColor   = kTextMuted;
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
              ? [BoxShadow(color: borderColor, blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 32, height: 32,
                decoration: BoxDecoration(color: labelBg, borderRadius: BorderRadius.circular(8)),
                child: Center(
                  child: Text(
                    labels[index],
                    style: TextStyle(color: labelFg, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _current.answers[index],
                  style: TextStyle(
                    color: textColor, fontSize: 15, fontWeight: FontWeight.w500, height: 1.35,
                  ),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(icon, key: ValueKey(icon), color: isCorrect ? kGreen : kRed, size: 24),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Nav bar ───────────────────────────────────────────────────────────────

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
            onTap: _goPrev,
          ),
          Row(
            children: List.generate(questions.length, (i) {
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
            enabled: _questionIndex < questions.length - 1,
            onTap: _goNext,
            reversed: true,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nav button
// ---------------------------------------------------------------------------

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
    final color = enabled ? kRed : kTextMuted;
    final kids = <Widget>[
      if (!reversed) ...[Icon(icon, color: color, size: 18), const SizedBox(width: 6)],
      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
      if (reversed) ...[const SizedBox(width: 6), Icon(icon, color: color, size: 18)],
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