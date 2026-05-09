# HerdA4G - First Aid Education App

A Flutter-based mobile application that provides quick access to first aid information. Features include categorized ailment guides with step-by-step instructions, text-to-speech readout, embedded video support, and an interactive trivia quiz with persistent progress tracking.

## Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (Dart SDK 3.11.4 or later)
- Android Studio or VS Code with the Flutter extension
- A connected device or emulator

## Setup

1. Clone the repository:
   ```
   git clone https://github.com/your-username/HerdA4G.git
   cd HerdA4G
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Run the app:
   ```
   flutter run
   ```
   Specify a target with `-d chrome`, `-d android`, etc.

4. Build for release:
   ```
   flutter build apk        # Android
   flutter build ios        # iOS (requires macOS and Xcode)
   ```

## Features

- **Category browser** — home screen grid of first aid categories with a live search bar and per-category quiz progress bars
- **Topic modules** — step-by-step instructions with optional images and embedded YouTube or network video
- **Text-to-speech** — read steps aloud with a single tap; stops automatically when all steps finish
- **Trivia quiz** — per-category multiple-choice quiz with answer feedback; progress (correct/total) persists across app restarts
- **Settings** — view overall progress and reset all quiz scores
- **Progress Tracker** — trivia answers are tracked based on correctness and displayed on the home screen

## Project Structure

```
lib/
├── main.dart                  # App entry point, home screen, category grid
├── categories.dart            # Category detail screen with topic list and quiz button
├── module.dart                # Topic detail screen: steps, images, TTS, video
├── trivia.dart                # Quiz screen with session restore and progress sync
├── settings.dart              # Settings screen: progress summary and reset
├── model.dart                 # Data models: AilmentCategory, AilmentTopic, AilmentStep,
│                              #   TriviaQuestion, CategoryQuizProgress
├── tts_service.dart           # Singleton TTS service (flutter_tts wrapper)
└── services/
    └── primary_service.dart   # FirstAidService: state management, SharedPreferences
                               #   persistence, category question count seeding

assets/
├── data/
│   ├── ailments.json          # Category and topic definitions with steps and video URLs
│   └── questions.json         # Per-category multiple-choice quiz questions
└── icons/                     # Category and topic icon images

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| shared_preferences | ^2.0.15 | Quiz progress persistence |
| flutter_tts | ^4.0.0 | Text-to-speech |
| video_player | ^2.11.1 | Local/network video playback |
| youtube_player_iframe | ^5.2.2 | Embedded YouTube playback |

## Data Format

Ailment categories and topics are defined in `assets/data/ailments.json`:

```json
{
  "categories": [
    {
      "id": "cuts",
      "name": "Cuts",
      "icon": "assets/icons/cuts.webp",
      "description": "Basic wound care",
      "topics": [
        {
          "id": "minor",
          "name": "Minor Cuts",
          "description": "Small cuts and scrapes",
          "steps": [
            { "step": 1, "instruction": "Wash your hands before touching the wound." }
          ],
          "video": "https://www.youtube.com/watch?v=..."
        }
      ]
    }
  ]
}
```

Quiz questions are defined in `assets/data/questions.json`, keyed by category ID:

```json
{
  "Questions": [
    {
      "id": "cuts",
      "items": [
        {
          "question": "What is the first step for a minor cut?",
          "answers": ["Apply pressure", "Wash hands", "Use ice", "Call 911"],
          "correctAnswer": "Wash hands"
        }
      ]
    }
  ]
}
```
