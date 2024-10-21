import 'package:cloud_firestore/cloud_firestore.dart';
import 'level.dart'; // Importa LevelStep da level.dart

class Course {
  final String id;
  final String title;
  final List<Section> sections;
  final String topic;  // Campo 'topic'
  final String subtopic;  // Campo 'subtopic'
  final String? thumbnailUrl; // Aggiungi questo campo

  Course({
    required this.id,
    required this.title,
    required this.sections,
    required this.topic,  // Campo 'topic'
    required this.subtopic,  // Campo 'subtopic'
    this.thumbnailUrl, // Includi questo campo nel costruttore
  });

  factory Course.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Course(
      id: doc.id,
      title: data['title'] ?? '',
      sections: List<Section>.from(data['sections']?.map((section) => Section.fromMap(section)) ?? []),
      topic: data['topic'] ?? '',  // Aggiunto 'topic'
      subtopic: data['subtopic'] ?? '',  // Aggiunto 'subtopic'
      thumbnailUrl: data['thumbnailUrl'], // Assicurati che venga mappato
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'sections': sections.map((section) => section.toMap()).toList(),
      'topic': topic,  // Aggiunto 'topic'
      'subtopic': subtopic,  // Aggiunto 'subtopic'
      'thumbnailUrl': thumbnailUrl, // Includi questo nel mapping
    };
  }
}

class Section {
  final String title;
  final List<LevelStep> steps; // Sostituisci StepItem con LevelStep

  Section({
    required this.title,
    required this.steps,
  });

  factory Section.fromMap(Map<String, dynamic> data) {
    return Section(
      title: data['title'] ?? '',
      steps: List<LevelStep>.from(data['steps']?.map((step) => LevelStep.fromMap(step)) ?? []), // Usa LevelStep
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'steps': steps.map((step) => step.toMap()).toList(),
    };
  }
}