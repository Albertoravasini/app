import 'dart:convert';
import 'package:Just_Learn/models/article.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class ArticlesService {
  final String baseUrl = 'http://localhost:3000';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getRelatedArticles(String videoTitle, String levelId) async {
    try {
      print('ArticlesService - Invio richiesta');
      print('Video Title: $videoTitle');
      print('Level ID: $levelId');

      if (videoTitle.isEmpty || levelId.isEmpty) {
        throw Exception('videoTitle e levelId sono richiesti');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/articles/related'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'videoTitle': videoTitle,
          'levelId': levelId,
        }),
      );

      print('Status code risposta: ${response.statusCode}');
      print('Corpo risposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      
      throw Exception('Errore nel recupero degli articoli');
    } catch (e) {
      print('Errore dettagliato nel servizio articoli: $e');
      rethrow;
    }
  }

  Future<List<Article>> getArticlesForLevel(String levelId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('articles')
          .where('levelId', isEqualTo: levelId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Article.fromFirestore(doc)).toList();
    } catch (e) {
      print('Errore nel recupero degli articoli per il livello: $e');
      return [];
    }
  }
} 