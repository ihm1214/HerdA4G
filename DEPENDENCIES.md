# Dependencies

## Production Dependencies

### [shared_preferences](https://pub.dev/packages/shared_preferences) `^2.0.15`
Persists quiz progress (correct answers and total questions per category) across app restarts using platform key-value storage. Used in `lib/services/primary_service.dart` and `lib/trivia.dart`.

### [flutter_tts](https://pub.dev/packages/flutter_tts) `^4.0.0`
Text-to-speech engine. Powers the "Read Steps Aloud" button in `lib/module.dart` and the `TtsService` singleton in `lib/tts_service.dart`.

### [video_player](https://pub.dev/packages/video_player) `^2.11.1`
Plays local and network video files. Used as a fallback in `lib/module.dart` for non-YouTube video URLs attached to topics.

### [youtube_player_iframe](https://pub.dev/packages/youtube_player_iframe) `^5.2.2`
Embeds YouTube videos inside the app. Used in `lib/module.dart` to display instructional videos linked from `assets/data/ailments.json`.

### [cupertino_icons](https://pub.dev/packages/cupertino_icons) `^1.0.8`
Provides iOS-style icons for the Flutter icon font. Included by default in new Flutter projects.

---

## Dev Dependencies

### [flutter_lints](https://pub.dev/packages/flutter_lints) `^6.0.0`
Recommended Dart lint rules for Flutter projects. Rules are activated via `analysis_options.yaml`. Only affects static analysis — not included in release builds.

### [flutter_test](https://flutter.dev/docs/testing)
Flutter's built-in testing framework. Included automatically by the Flutter SDK.

---

## Locked Versions

Resolved versions are recorded in `pubspec.lock`. Key resolved versions:

| Package | Resolved |
|---|---|
| shared_preferences | 2.5.5 |
| flutter_tts | 4.2.5 |
| video_player | 2.11.1 |
| youtube_player_iframe | 5.2.2 |
| cupertino_icons | 1.0.9 |
| flutter_lints | 6.0.0 |
