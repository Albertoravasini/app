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
  double rating;
  int totalRatings;
  String authorId;
  String authorName;
  String? authorProfileUrl;

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
    this.rating = 0.0,
    this.totalRatings = 0,
    required this.authorId,
    required this.authorName,
    this.authorProfileUrl,
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
        (data['sections'] ?? []).asMap().entries.map((entry) {
          // Aggiungiamo l'indice + 1 come sectionNumber
          var sectionData = entry.value as Map<String, dynamic>;
          sectionData['sectionNumber'] = entry.key + 1;
          return Section.fromMap(sectionData);
        }),
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
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown Author',
      authorProfileUrl: data['authorProfileUrl'],
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
      'rating': rating,
      'totalRatings': totalRatings,
      'authorId': authorId,
      'authorName': authorName,
      'authorProfileUrl': authorProfileUrl,
    };
  }
}

class Section {
  String title;
  final List<LevelStep> steps;
  String? imageUrl;
  int sectionNumber;

  Section({
    required this.title,
    required this.steps,
    this.imageUrl,
    required this.sectionNumber,
  });

  factory Section.fromMap(Map<String, dynamic> data) {
    return Section(
      title: data['title'] ?? '',
      steps: List<LevelStep>.from(data['steps']?.map((step) => LevelStep.fromMap(step)) ?? []),
      imageUrl: data['imageUrl'],
      sectionNumber: data['sectionNumber'] ?? 1, // Usa il numero fornito o 1 come default
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'steps': steps.map((step) => step.toMap()).toList(),
      'imageUrl': imageUrl,
      'sectionNumber': sectionNumber,
    };
  }
}