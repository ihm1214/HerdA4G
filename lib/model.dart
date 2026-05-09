// model.dart was made with the help of https://www.youtube.com/watch?v=iV8CObuvPAE
// used the youtube video for basics then expanded using other tutorials

// This file holds all the "data models" for the app
// basically blueprints that describe what each piece of data looks like
// Dart classes docs: https://dart.dev/language/classes

// AilmentStep = one single step in a first aid guide (like "step 1: wash hands")
class AilmentStep {
  final int step;            // the step number (1, 2, 3...)
  final String instruction;  // what you actually have to do
  final String? imageUrl;    // optional image path (the ? means it can be null/missing)

  AilmentStep({required this.step, required this.instruction, this.imageUrl});

// JSON linking made with help from https://www.youtube.com/watch?v=tgvfhWqS39o
// fromJson is a "factory constructor" - it reads a JSON object and builds one of these
// factory constructors explained: https://dart.dev/language/constructors#factory-constructors
  factory AilmentStep.fromJson(Map<String, dynamic> json) {
    return AilmentStep(
      step: json['step'],
      instruction: json['instruction'],
      imageUrl: json['imageUrl'],
    );
  }
}

// AilmentCategory = one of the big sections on the home screen like "Burns" or "Cuts"
// it contains a list of topics (the smaller modules inside it)
class AilmentCategory {
  final String id;                 // unique identifier used to match quiz questions (like "burns")
  final String icon;               // path to the icon image shown on the home grid
  final List<AilmentTopic> topics; // all the sub-modules inside this category
  final String name;               // display name like "Burns"
  final String description;        // short description shown under the name
  final int progress;              // not really used anymore, progress is tracked in the service

  AilmentCategory({
    required this.id,
    required this.icon,
    required this.topics,
    required this.name,
    required this.description,
    required this.progress,
  });

  factory AilmentCategory.fromJson(Map<String, dynamic> json) {
    return AilmentCategory(
      id: json['id'],
      icon: json['icon'],
      // topics is a nested list in the JSON so we loop through and parse each one
      topics: (json['topics'] as List)
          .map((topic) => AilmentTopic.fromJson(topic))
          .toList(),
      name: json['name'],
      description: json['description'],
      progress: json['progress'],
    );
  }
}

// TriviaQuestion = one multiple-choice question for the quiz
// has the question text, a list of 4 answer choices, and which one is correct
// Dart const constructors: https://dart.dev/language/constructors#constant-constructors
class TriviaQuestion {
  final String question;        // the actual question text shown to the user
  final List<String> answers;   // list of 4 answer choices
  final String correctAnswer;   // the text of the right answer

  const TriviaQuestion({
    required this.question,
    required this.answers,
    required this.correctAnswer,
  });

  // correctIndex figures out which slot in the answers list the correct answer lives at
  // the quiz UI tracks answers by index number, not text, so this conversion is needed
  int get correctIndex => answers.indexOf(correctAnswer);

  factory TriviaQuestion.fromJson(Map<String, dynamic> json) {
    return TriviaQuestion(
      question: json['question'] as String,
      answers: List<String>.from(json['answers'] as List),
      correctAnswer: json['correctAnswer'] as String,
    );
  }
}

// AilmentTopic = one specific module inside a category (like "Minor Burns" inside "Burns")
// it has a list of steps and optionally a video link
class AilmentTopic {
  final List<AilmentStep> steps; // the step-by-step instructions
  final String name;             // display name like "Minor Burns"
  final String description;      // short subtitle shown in the category list
  final String id;               // unique identifier
  final String icon;             // icon image path
  final String? video;           // optional YouTube or direct video URL (can be null)

  AilmentTopic({
    required this.steps,
    required this.name,
    required this.description,
    required this.id,
    required this.icon,
    this.video,
  });

  factory AilmentTopic.fromJson(Map<String, dynamic> json) {
    return AilmentTopic(
      // same nested list pattern as AilmentCategory - loop and parse each step
      steps: (json['steps'] as List)
          .map((step) => AilmentStep.fromJson(step))
          .toList(),
      name: json['name'],
      description: json['description'],
      id: json['id'],
      icon: json['icon'],
      video: json['video'],
    );
  }
}

// CategoryQuizProgress = tracks how many questions someone got right in one category
// used to show the progress bars on the home screen and the settings page
// LinearProgressIndicator needs a value from 0.0 to 1.0, which the progress getter gives us
// LinearProgressIndicator docs: https://api.flutter.dev/flutter/material/LinearProgressIndicator-class.html
class CategoryQuizProgress {
  final String categoryId;    // which category this score belongs to
  final int correctAnswers;   // how many they got right so far
  final int totalQuestions;   // how many questions exist in total

  const CategoryQuizProgress({
    required this.categoryId,
    required this.correctAnswers,
    required this.totalQuestions,
  });

  // progress returns a number between 0.0 and 1.0 for the progress bar
  // guard against dividing by zero if the total hasn't loaded yet
  double get progress =>
      totalQuestions == 0 ? 0 : correctAnswers / totalQuestions;
}
