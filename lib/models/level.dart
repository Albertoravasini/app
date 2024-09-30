import 'package:cloud_firestore/cloud_firestore.dart';

class Level {
  final String? id; // ID del documento Firestore
  int levelNumber; // Numero del livello (ordine dei livelli all'interno di un subtopic)
  final String topic; // Topic di appartenenza
  String subtopic; // Rimuovi `final` da qui
  final String title; // Titolo del livello
  final List<LevelStep> steps; // Passi del livello
  final int subtopicOrder; // Ordine del subtopic (ordine dei subtopic all'interno di un topic)
  int get numberOfQuestions {
    return steps.where((step) => step.type == 'question').length;
  }

  Level({
    this.id,
    required this.levelNumber,
    required this.topic,
    required this.subtopic, // Può essere modificato ora
    required this.title,
    required this.steps,
    required this.subtopicOrder, 
  });

  factory Level.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Level(
      id: doc.id,
      levelNumber: data['levelNumber'] ?? 0,
      topic: data['topic'] ?? '',
      subtopic: data['subtopic'] ?? '', // Subtopic
      title: data['title'] ?? '',
      steps: List<LevelStep>.from(data['steps']?.map((step) => LevelStep.fromMap(step)) ?? []),
      subtopicOrder: data['subtopicOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
  final List<String>? choices;
  final String? correctAnswer;
  final String? explanation;
  final String? thumbnailUrl;
  final bool isShort;  // Nuovo campo aggiunto
  final String? fullText; // Aggiunto per il testo completo del video

  LevelStep({
    required this.type,
    required this.content,
    this.choices,
    this.correctAnswer,
    this.explanation,
    this.thumbnailUrl,
    this.isShort = false, // Imposta false come valore predefinito
    this.fullText, // Campo opzionale per il testo completo
  });

  factory LevelStep.fromMap(Map<String, dynamic> data) {
    return LevelStep(
      type: data['type'] ?? '',
      content: data['content'] ?? '',
      choices: List<String>.from(data['choices'] ?? []),
      correctAnswer: data['correctAnswer'],
      explanation: data['explanation'],
      thumbnailUrl: data['thumbnailUrl'],
      isShort: data['isShort'] ?? false,  // Recupera il valore dal database
      fullText: data['fullText'], // Recupera il testo completo
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'content': content,
      'choices': choices,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'thumbnailUrl': thumbnailUrl,
      'isShort': isShort,  // Salva il valore nel database
      'fullText': fullText, // Salva il testo completo nel database
    };
  }
}