import 'package:cloud_firestore/cloud_firestore.dart';

class Level {
  final String? id;
  int levelNumber;
  final String topic;
  String subtopic;
  final String title;
  final List<LevelStep> steps;
  final int subtopicOrder;

  Level({
    this.id,
    required this.levelNumber,
    required this.topic,
    required this.subtopic,
    required this.title,
    required this.steps,
    required this.subtopicOrder,
  });

  // Getter to count the number of questions in steps
  int get numberOfQuestions {
    return steps.where((step) => step.type == 'question').length;
  }

  factory Level.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Level(
      id: doc.id,
      levelNumber: data['levelNumber'] ?? 0,
      topic: data['topic'] ?? '',
      subtopic: data['subtopic'] ?? '',
      title: data['title'] ?? '',
      steps: List<LevelStep>.from(data['steps']?.map((step) => LevelStep.fromMap(step)) ?? []),
      subtopicOrder: data['subtopicOrder'] ?? 0,
    );
  }

  factory Level.fromMap(Map<String, dynamic> data) {
    return Level(
      id: data['id'] as String?,
      levelNumber: data['levelNumber'] ?? 0,
      topic: data['topic'] ?? '',
      subtopic: data['subtopic'] ?? '',
      title: data['title'] ?? '',
      steps: List<LevelStep>.from(
          data['steps']?.map((step) => LevelStep.fromMap(step)) ?? []),
      subtopicOrder: data['subtopicOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'levelNumber': levelNumber,
      'topic': topic,
      'subtopic': subtopic,
      'title': title,
      'steps': steps.map((step) => step.toMap()).toList(),
      'subtopicOrder': subtopicOrder,
    };
  }
}

class LevelStep {
  final String type;
  final String content;
  final String? videoUrl;
  final List<String>? choices;
  final String? correctAnswer;
  final String? explanation;
  final String? thumbnailUrl;
  final bool isShort;
  final String? fullText;
  String? topic;
  final DateTime? createdAt;
  final int? duration;

  LevelStep({
    required this.type,
    required this.content,
    this.videoUrl,
    this.choices,
    this.correctAnswer,
    this.explanation,
    this.thumbnailUrl,
    this.isShort = false,
    this.fullText,
    this.topic,
    this.createdAt,
    this.duration,
  });

  factory LevelStep.fromMap(Map<String, dynamic> data) {
    return LevelStep(
      type: data['type'] ?? '',
      content: data['content'] ?? '',
      videoUrl: data['videoUrl'],
      choices: List<String>.from(data['choices'] ?? []),
      correctAnswer: data['correctAnswer'],
      explanation: data['explanation'],
      thumbnailUrl: data['thumbnailUrl'],
      isShort: data['isShort'] ?? false,
      fullText: data['fullText'],
      topic: data['topic'],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
      duration: data['duration'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'content': content,
      'videoUrl': videoUrl,
      'choices': choices,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'thumbnailUrl': thumbnailUrl,
      'isShort': isShort,
      'fullText': fullText,
      'topic': topic,
      'createdAt': createdAt?.toIso8601String(),
      'duration': duration,
    };
  }

  // Override di == e hashCode
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LevelStep &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          content == other.content &&
          videoUrl == other.videoUrl &&
          isShort == other.isShort;

  @override
  int get hashCode =>
      type.hashCode ^
      content.hashCode ^
      (videoUrl?.hashCode ?? 0) ^
      isShort.hashCode;
}