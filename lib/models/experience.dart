import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Experience {
  final String title;
  final String company;
  final DateTime startDate;
  final DateTime? endDate;
  final String description;

  Experience({
    required this.title,
    required this.company,
    required this.startDate,
    this.endDate,
    required this.description,
  });

  String get period {
    final start = DateFormat('MMM yyyy').format(startDate);
    final end = endDate != null ? DateFormat('MMM yyyy').format(endDate!) : 'Present';
    return '$start - $end';
  }

  factory Experience.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Experience(
      title: data['title'] ?? '',
      company: data['company'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'company': company,
      'startDate': startDate,
      'endDate': endDate,
      'description': description,
    };
  }
} 