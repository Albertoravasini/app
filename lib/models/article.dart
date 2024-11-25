import 'package:cloud_firestore/cloud_firestore.dart';

class Article {
  final String id;
  final String title;
  final String content;
  final String fullContent;
  final String url;
  final String source;
  final String date;
  final String imageUrl;
  final String levelId;
  final DateTime createdAt;

  Article({
    required this.id,
    required this.title,
    required this.content,
    required this.fullContent,
    required this.url,
    required this.source,
    required this.date,
    required this.imageUrl,
    required this.levelId,
    required this.createdAt,
  });

  factory Article.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Article(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      fullContent: data['full_content'] ?? '',
      url: data['url'] ?? '',
      source: data['source'] ?? '',
      date: data['date'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      levelId: data['levelId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'full_content': fullContent,
      'url': url,
      'source': source,
      'date': date,
      'imageUrl': imageUrl,
      'levelId': levelId,
      'createdAt': createdAt,
    };
  }
} 