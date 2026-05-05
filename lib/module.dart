import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'model.dart';

// Initialization made with help from Flutter template
class Module extends StatefulWidget {
  final AilmentTopic topic;
  static const bool _showStepImages = false;

  const Module({super.key, required this.topic});

  @override
  State<Module> createState() => _ModuleState();
}

class _ModuleState extends State<Module> {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _tts.setCompletionHandler(() {
      if (!_isSpeaking) return;
      _currentStep++;
      if (_currentStep < widget.topic.steps.length) {
        _speakStep(_currentStep);
      } else {
        setState(() => _isSpeaking = false);
      }
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _speakStep(int index) async {
    final step = widget.topic.steps[index];
    await _tts.speak("Step ${index + 1}. ${step.instruction}");
  }

  Future<void> _toggleSpeech() async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() {
        _isSpeaking = false;
        _currentStep = 0;
      });
    } else {
      setState(() {
        _isSpeaking = true;
        _currentStep = 0;
      });
      await _speakStep(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 250, 183, 178),
        title: Text(widget.topic.name),
      ),
      body: Column(
        children: [
          // ── TTS Button Banner ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _toggleSpeech,
                icon: Icon(
                  _isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_rounded,
                  //adjust volume icon size here
                  size: 30,
                ),
                label: Text(
                  _isSpeaking ? 'Stop Reading' : 'Read Steps Aloud',
                  //adjust font size here
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSpeaking
                      ? const Color.fromARGB(255, 220, 100, 90)
                      : const Color.fromARGB(255, 250, 183, 178),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),
          // ── Steps List ────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.topic.steps.length,
              itemBuilder: (context, index) {
                final step = widget.topic.steps[index];
                return _StepCard(
                  step: step,
                  showImage: Module._showStepImages,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Card UI made with the help of https://www.youtube.com/watch?v=IBgafr0dgpQ
class _StepCard extends StatelessWidget {
  final AilmentStep step;
  final bool showImage;

  const _StepCard({required this.step, required this.showImage});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.blue.shade50,
                  child: Text(
                    '${step.step}',
                    style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                )
              ],
            ),
            if (showImage && step.imageUrl != null && step.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  step.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120,
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: Text(
                        'Image unavailable',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(step.instruction,
                      style: const TextStyle(fontSize: 15, height: 1.5)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}