import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VideoService {
  final String backendUrl = 'http://localhost:3000';

  final Map<String, List<String>> topicKeywords = {
    'Finanza': ['finanza semplice', 'Investiamo', 'pietro michelangeli','mr Rip','starting finance'],
    'Legge': ['Angelo Greco'],
    'Crescita Personale': ['valutainment', 'alex homozi', 'TEDx Talks'],
    'Storia': ['Alessandro Barbero - La Storia siamo Noi', 'Beginning To Now', 'History Matters'],
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
      final List<dynamic> videos = data['videos'];

      for (var video in videos) {
        final snippet = video['snippet'];
        final title = snippet['title'].toLowerCase();
        final description = snippet['description'].toLowerCase();
        String category = 'Uncategorized';

        for (var topic in topics) {
          final keywords = topicKeywords[topic] ?? [];
          if (keywords.any((keyword) => title.contains(keyword.toLowerCase()) || description.contains(keyword.toLowerCase()))) {
            category = topic;
            break;
          }
        }

        video['snippet']['category'] = category;
      }

      return {
        'videos': videos,
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

  Future<List<dynamic>> fetchVideoText(String videoUrl) async {
    final response = await http.post(
      Uri.parse('$backendUrl/extract_video_text'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'videoUrl': videoUrl}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['subtitles'];
    } else {
      throw Exception('Failed to fetch video text');
    }
  }
}