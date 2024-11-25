import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class AiService {
  final String baseUrl = 'http://167.99.131.91:3000';

  Future<Map<String, String>> getSummary(String content) async {
    try {
      print('Invio richiesta di riassunto...');
      
      if (content.isEmpty) {
        return {
          'summary': 'Nessun contenuto da riassumere',
          'key_learning': 'Nessun punto chiave disponibile'
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/ai/summarize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': content}),
      ).timeout(
        const Duration(seconds: 30),
        
      );

      print('Status code: ${response.statusCode}');
      print('Risposta: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data['success'] == true && data['summary'] != null) {
          final summary = data['summary'] as Map<String, dynamic>;
          return {
            'summary': summary['summary']?.toString() ?? 'Riassunto non disponibile',
            'key_learning': summary['key_learning']?.toString() ?? 'Nessun punto chiave disponibile'
          };
        } else {
          print('Risposta non valida: $data');
          return {
            'summary': 'Errore nella generazione del riassunto',
            'key_learning': 'Riprova più tardi'
          };
        }
      } else {
        print('Errore HTTP: ${response.statusCode}');
        return {
          'summary': 'Errore nella richiesta al server',
          'key_learning': 'Codice errore: ${response.statusCode}'
        };
      }
    } catch (e, stackTrace) {
      print('Errore dettagliato nel servizio AI: $e');
      print('Stack trace: $stackTrace');
      return {
        'summary': 'Si è verificato un errore',
        'key_learning': 'Riprova più tardi'
      };
    }
  }
} 