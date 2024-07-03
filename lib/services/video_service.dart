import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VideoService {
  final String backendUrl = 'http://localhost:3000';

  final Map<String, List<String>> topicKeywords = {
    'Finanza': ['finanza semplice playlist investiamo', 'channel:investiamo', 'pietro michelangeli','Rip'],
    'Legge': ['Angelo Greco'],
    'Business': [],
    'Crescita Personale': ['valutainment', 'alex homozi'],
    'Storia': ['barbero', 'storia antica', 'storia attuale'],
    'Lingue': ['lezioni francese','inglese', 'joEnglish'],
    'Attualità': ['fanpage', 'Limes rivista italiana di geopolitica', 'valutainment', 'Breaking Italy'],
  };

  Future<Map<String, dynamic>> fetchNewVideos(String topic, List<String> viewedVideos, {String? nextPageToken}) async {
    final keywords = topicKeywords[topic] ?? [topic];
    final List<dynamic> allVideos = [];

    for (String keyword in keywords) {
      final response = await http.post(
        Uri.parse('$backendUrl/new_videos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'keywords': [keyword], 'viewedVideos': viewedVideos, 'pageToken': nextPageToken, 'topic': topic}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        allVideos.addAll(data['videos']);
        nextPageToken = data['nextPageToken'];
      } else {
        throw Exception('Failed to load videos');
      }
    }

    allVideos.shuffle(Random());
    
    return {
      'videos': allVideos,
      'nextPageToken': nextPageToken,
    };
  }

  Future<void> prefetchVideo(String videoId, String resolution) async {
    print('Prefetching video: $videoId in $resolution resolution');
    final prefs = await SharedPreferences.getInstance();
    final cachedVideos = prefs.getStringList('cachedVideos') ?? [];
    if (!cachedVideos.contains(videoId)) {
      cachedVideos.add(videoId);
      await prefs.setStringList('cachedVideos', cachedVideos);
    }
  }

  Future<Map<String, dynamic>> generateQuestion(String summary) async {
    final response = await http.post(
      Uri.parse('$backendUrl/generate_question'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'summary': summary}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to generate question');
    }
  }
}