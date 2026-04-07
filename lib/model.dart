class AilmentWriting {
  String name;
  String description;
  String symptoms;
  String treatment;

  AilmentWriting({
    required this.name,
    required this.description,
    required this.symptoms,
    required this.treatment,
  });
}

class Ailment {
  String name;
  String description;
  int progress;

  Ailment({
    required this.name,
    required this.description,
    required this.progress,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'progress': progress,
    };
  }

  factory Ailment.fromMap(Map<String, dynamic> map) {
    return Ailment(
      name: map['name'],
      description: map['description'],
      progress: map['progress'],
    );
  }

  extension AilmentCopy on Ailment
  
}