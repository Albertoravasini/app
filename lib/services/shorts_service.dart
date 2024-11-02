// lib/services/shorts_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ShortsService {
  final String baseUrl;

  ShortsService({required this.baseUrl});

  Future<List<Map<String, dynamic>>> getShortSteps({
    required String? selectedTopic,
    required String? selectedSubtopic,
    required String uid,
    required bool showSavedVideos,
  }) async {
    final url = Uri.parse('$baseUrl/get_short_steps');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'selectedTopic': selectedTopic,
        'selectedSubtopic': selectedSubtopic,
        'uid': uid,
        'showSavedVideos': showSavedVideos,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to load short steps');
      }
    } else {
      throw Exception('Failed to load short steps');
    }
  }
}