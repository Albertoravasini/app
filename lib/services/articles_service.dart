import 'dart:convert';
import 'package:http/http.dart' as http;

class ArticlesService {
  final String baseUrl = 'http://localhost:3000';

  Future<List<Map<String, dynamic>>> getRelatedArticles(String videoTitle) async {
    try {
      print('Invio richiesta a: $baseUrl/get_related_articles');
      print('Titolo video: $videoTitle');

      final response = await http.post(
        Uri.parse('$baseUrl/get_related_articles'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'videoTitle': videoTitle,
        }),
      );

      print('Status code risposta: ${response.statusCode}');
      print('Corpo risposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final articles = List<Map<String, dynamic>>.from(data['data']);
          print('Articoli recuperati con successo: ${articles.length}');
          return articles;
        }
      }
      
      final errorMessage = jsonDecode(response.body)['message'] ?? 'Errore sconosciuto';
      print('Errore dal server: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      print('Errore dettagliato nel servizio articoli: $e');
      rethrow;
    }
  }
} 