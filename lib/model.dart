class AilmentStep {
  final int step;
  final String instruction;
  final String? imageUrl;

  AilmentStep({
    required this.step,
    required this.instruction,
    this.imageUrl,
  });

   factory AilmentStep.fromJson(Map<String, dynamic> json) {
    return AilmentStep(
      step: json['step'],
      instruction: json['instruction'],
      imageUrl: json['imageUrl'],
    );
  }
}
class AilmentCategory {
  final String id;
  final String icon;
  final List<AilmentTopic> topics;
  final String name;
  final String description;
  final int progress;

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
      topics: (json['topics'] as List).map((topic) => AilmentTopic.fromJson(topic)).toList(),
      name: json['name'],
      description: json['description'],
      progress: json['progress'],
    );
  }
}

class AilmentTopic {
  final List<AilmentStep> steps;
  final String name;
  final String description;
  final String id;
  final String icon;

  AilmentTopic({
    required this.steps,
    required this.name,
    required this.description,
    required this.id,
    required this.icon,
  });

  factory AilmentTopic.fromJson(Map<String, dynamic> json) {
    return AilmentTopic(
      steps: (json['steps'] as List).map((step) => AilmentStep.fromJson(step)).toList(),
      name: json['name'],
      description: json['description'],
      id: json['id'],
      icon: json['icon'],
    );
  }

}