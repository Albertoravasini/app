import 'package:cloud_firestore/cloud_firestore.dart';
import 'level.dart'; // Importa LevelStep da level.dart

class Course {
  final String id;
  String title;
  String description;
  int cost;
  bool visible;
  List<Section> sections;
  String topic;
  String subtopic;
  String? thumbnailUrl;
  String? coverImageUrl; // Nuovo campo per l'immagine di copertina

  // Costruttore aggiornato
  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.cost,
    required this.visible,
    required this.sections,
    required this.topic,
    required this.subtopic,
    this.thumbnailUrl,
    this.coverImageUrl, // Aggiungi questo campo
  });

  // Aggiornamento del metodo fromFirestore
  factory Course.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Course(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      cost: data['cost'] ?? 0,
      visible: data['visible'] ?? true,
      sections: List<Section>.from(
        data['sections']?.map((section) => Section.fromMap(section)) ?? [],
      ),
      topic: data['topic'] ?? '',
      subtopic: data['subtopic'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      coverImageUrl: data['coverImageUrl'], // Aggiungi questo campo
    );
  }

  // Aggiornamento del metodo toMap
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'cost': cost,
      'visible': visible,
      'sections': sections.map((section) => section.toMap()).toList(),
      'topic': topic,
      'subtopic': subtopic,
      'thumbnailUrl': thumbnailUrl,
      'coverImageUrl': coverImageUrl, // Aggiungi questo campo
    };
  }
}

class Section {
   String title;
  final List<LevelStep> steps; // Sostituisci StepItem con LevelStep
  String? imageUrl; // Aggiungi questo campo

  Section({
    required this.title,
    required this.steps,
    this.imageUrl,
  });

  factory Section.fromMap(Map<String, dynamic> data) {
    return Section(
      title: data['title'] ?? '',
      steps: List<LevelStep>.from(data['steps']?.map((step) => LevelStep.fromMap(step)) ?? []), // Usa LevelStep
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'steps': steps.map((step) => step.toMap()).toList(),
      'imageUrl': imageUrl,
    };
  }
}