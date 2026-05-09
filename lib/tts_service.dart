import 'package:flutter_tts/flutter_tts.dart';

// TTS singleton service pattern adapted from https://dart.dev/language/constructors#factory-constructors
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  // Step-by-step speech chaining adapted from https://pub.dev/packages/flutter_tts
  Future<void> speakSteps(List<String> instructions) async {
    await stop();
    _isSpeaking = true;

    for (int i = 0; i < instructions.length; i++) {
      if (!_isSpeaking) break;
      await _tts.speak("Step ${i + 1}. ${instructions[i]}");
      await _tts.awaitSpeakCompletion(true);
    }

    _isSpeaking = false;
  }

  Future<void> stop() async {
    _isSpeaking = false;
    await _tts.stop();
  }
}
