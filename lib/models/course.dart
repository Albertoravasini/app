// lib/models/course.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'level.dart'; // Assicurati che LevelStep sia importato correttamente

class Course {
   String id;
  String title;
  String description;
  int cost;
  bool visible;
  List<Section> sections;
  String topic;
  String subtopic;
  String? thumbnailUrl;
  String? coverImageUrl;

  // Additional fields
  List<String> sources;
  List<String> acknowledgments;
  List<String> recommendedBooks;
  List<String> recommendedPodcasts;
  List<String> recommendedWebsites;

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
    this.coverImageUrl,
    this.sources = const [],
    this.acknowledgments = const [],
    this.recommendedBooks = const [],
    this.recommendedPodcasts = const [],
    this.recommendedWebsites = const [],
  });

  factory Course.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Course.fromMap(data)..id = doc.id;
  }

  // Add the fromMap constructor here
  factory Course.fromMap(Map<String, dynamic> data) {
    return Course(
      id: data['id'] ?? '', // Use empty string as default if ID is not provided
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
      coverImageUrl: data['coverImageUrl'],
      sources: List<String>.from(data['sources'] ?? []),
      acknowledgments: List<String>.from(data['acknowledgments'] ?? []),
      recommendedBooks: List<String>.from(data['recommendedBooks'] ?? []),
      recommendedPodcasts: List<String>.from(data['recommendedPodcasts'] ?? []),
      recommendedWebsites: List<String>.from(data['recommendedWebsites'] ?? []),
    );
  }

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
      'coverImageUrl': coverImageUrl,
      'sources': sources,
      'acknowledgments': acknowledgments,
      'recommendedBooks': recommendedBooks,
      'recommendedPodcasts': recommendedPodcasts,
      'recommendedWebsites': recommendedWebsites,
    };
  }
}

class Section {
  String title;
  final List<LevelStep> steps;
  String? imageUrl;

  Section({
    required this.title,
    required this.steps,
    this.imageUrl,
  });

  factory Section.fromMap(Map<String, dynamic> data) {
    return Section(
      title: data['title'] ?? '',
      steps: List<LevelStep>.from(data['steps']?.map((step) => LevelStep.fromMap(step)) ?? []),
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