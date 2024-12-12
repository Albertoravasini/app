import 'package:cloud_firestore/cloud_firestore.dart';

class Certification {
  final String title;
  final String issuer;
  final DateTime date;
  final String? imageUrl;

  Certification({
    required this.title,
    required this.issuer,
    required this.date,
    this.imageUrl,
  });

  factory Certification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Certification(
      title: data['title'] ?? '',
      issuer: data['issuer'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'issuer': issuer,
      'date': date,
      'imageUrl': imageUrl,
    };
  }
} 