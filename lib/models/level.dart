import 'package:cloud_firestore/cloud_firestore.dart';

class Level {
  final int levelNumber;
  final String topic;
  final String subtopic;
  final String title;
  final List<LevelStep> steps;

  Level({
    required this.levelNumber,
    required this.topic,
    required this.subtopic,
    required this.title,
    required this.steps,
  });

  factory Level.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Level(
      levelNumber: data['levelNumber'] ?? 0,
      topic: data['topic'] ?? '',
      subtopic: data['subtopic'] ?? '',
      title: data['title'] ?? '',
      steps: List<LevelStep>.from(data['steps']?.map((step) => LevelStep.fromMap(step)) ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'levelNumber': levelNumber,
      'topic': topic,
      'subtopic': subtopic,
      'title': title,
      'steps': steps.map((step) => step.toMap()).toList(),
    };
  }
}

class LevelStep {
  final String type;
  final String content;
  final List<String>? choices;
  final String? correctAnswer;
  final String? explanation;
  final String? thumbnailUrl;

  LevelStep({
    required this.type,
    required this.content,
    this.choices,
    this.correctAnswer,
    this.explanation,
    this.thumbnailUrl,
  });

  factory LevelStep.fromMap(Map<String, dynamic> data) {
    return LevelStep(
      type: data['type'] ?? '',
      content: data['content'] ?? '',
      choices: List<String>.from(data['choices'] ?? []),
      correctAnswer: data['correctAnswer'],
      explanation: data['explanation'], // Aggiungi spiegazione qui
      thumbnailUrl: data['thumbnailUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'content': content,
      'choices': choices,
      'correctAnswer': correctAnswer,
      'explanation': explanation, // Aggiungi spiegazione qui
      'thumbnailUrl': thumbnailUrl,
    };
  }
}