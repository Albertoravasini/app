import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  final String baseUrl = 'http://167.99.131.91:3000';

  Future<Map<String, String>> getSummary(String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/summarize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': content}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'summary': data['summary']['summary'] ?? 'Riassunto non disponibile',
          'key_learning': data['summary']['key_learning'] ?? 'Nessun punto chiave disponibile'
        };
      } else {
        throw Exception('Errore nel recupero del riassunto');
      }
    } catch (e) {
      print('Errore nel servizio AI: $e');
      throw Exception('Errore nella generazione del riassunto');
    }
  }
} 