# HerdA4G - First Aid Companion App

A Flutter-based mobile application designed to provide quick access to first aid information, including categorized ailment guides, interactive trivia for learning, emergency contact features, and multimedia support (videos and images). Built to help users respond effectively in emergency situations.

## Features

- *Ailment Categories*: Browse organized categories of common first aid scenarios (e.g., bleeding, burns) with detailed guides and visual aids.
- *Interactive Trivia*: Test your knowledge with quiz questions to reinforce first aid skills.
- *Emergency Tools*: Quick access to emergency call features and pressure application guides.
- *Multimedia Support*: Integrated video playback for demonstrations and image assets for visual reference.
- *Settings*: Customizable preferences for text size, image display, and dark mode.
- *Offline Access*: Load and store data locally for use without internet.

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.0 or later recommended).
- Dart SDK (comes with Flutter).
- Android Studio or VS Code with Flutter extensions for development.
- A device or emulator for testing.

### Setup
1. Clone the repository:
   
   git clone https://github.com/your-username/HerdA4G.git
   cd HerdA4G
   

2. Install dependencies:
   
   flutter pub get
   

3. Run the app:
   - For Android: flutter run (ensure an emulator or device is connected).
   - For iOS: flutter run (on macOS with Xcode).
   - For web: flutter run -d chrome.

4. Build for release:
   - Android APK: flutter build apk
   - iOS: flutter build ios (requires Apple Developer account).

## Usage

1. Launch the app on your device.
2. On the home screen, browse ailment categories or start a trivia quiz.
3. Access settings via the app bar to customize your experience.
4. In emergencies, use the emergency button for quick actions.

### Data Structure
- Ailment data is loaded from assets/data/ailments.json.
- Images and icons are stored in assets/images/ and assets/icons/.
- Services handle data loading and preferences (see lib/services/primary_service.dart).

## Project Structure


lib/
├── main.dart              # App entry point and home screen
├── categories.dart        # Category-related widgets
├── model.dart             # Data models (e.g., AilmentCategory)
├── module.dart            # Step-by-step module screen
├── trivia.dart            # Quiz feature
├── services/
│   └── primary_service.dart  # Data loading and preferences
assets/
├── data/                  # JSON data files
├── icons/                 # Icon assets
└── images/                # Image assets

## Contact

For questions or support, reach out to the team at [ihhmoore@wpi.edu] or open an issue on GitHub.