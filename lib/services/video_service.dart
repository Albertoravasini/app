import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VideoService {
  final String backendUrl = 'http://167.99.131.91:3000';

  final Map<String, List<String>> topicKeywords = {
    'Finanza': ['finanza semplice playlist investiamo', 'channel:investiamo', 'pietro michelangeli','Rip'],
    'Legge': ['Angelo Greco'],
    'Business': [],
    'Crescita Personale': ['valutainment', 'alex homozi'],
    'Storia': ['barbero', 'storia antica', 'storia attuale'],
    'Lingue': ['lezioni francese','inglese', 'joEnglish'],
    'Attualità': ['fanpage', 'Limes rivista italiana di geopolitica', 'valutainment', 'Breaking Italy'],
  };

  Future<Map<String, dynamic>> fetchNewVideos(List<String> topics, List<String> viewedVideos, {String? nextPageToken}) async {
    final List<String> allKeywords = [];
    topics.forEach((topic) {
      allKeywords.addAll(topicKeywords[topic] ?? [topic]);
    });

    final response = await http.post(
      Uri.parse('$backendUrl/new_videos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'keywords': allKeywords, 'viewedVideos': viewedVideos, 'pageToken': nextPageToken, 'topic': topics.join(', ')}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'videos': data['videos'],
        'nextPageToken': data['nextPageToken'],
      };
    } else {
      throw Exception('Failed to load videos');
    }
  }

  Future<void> prefetchVideo(String videoId, String resolution) async {
    print('Prefetching video: $videoId in $resolution resolution');
    final prefs = await SharedPreferences.getInstance();
    final cachedVideos = prefs.getStringList('cachedVideos') ?? [];
    if (!cachedVideos.contains(videoId)) {
      print('Caching video: $videoId');
      cachedVideos.add(videoId);
      await prefs.setStringList('cachedVideos', cachedVideos);
    } else {
      print('Video already cached: $videoId');
    }
  }
}