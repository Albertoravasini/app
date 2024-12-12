import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String userName;
  final double rating;
  final String comment;
  final DateTime date;
  final String? userImage;

  Review({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
    this.userImage,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      userName: data['userName'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      userImage: data['userImage'],
    );
  }
} 