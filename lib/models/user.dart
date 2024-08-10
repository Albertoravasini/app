import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final List<String> topics;
  final Map<String, List<VideoWatched>> savedVideosByTopic;
  final Map<String, List<int>> completedLevelsByTopic;
  final Map<String, int> checkpoints;  // Aggiunto
  int consecutiveDays;
  DateTime lastAccess;
  final String role;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.topics,
    required this.savedVideosByTopic,
    required this.completedLevelsByTopic,
    required this.checkpoints,  // Aggiunto
    required this.consecutiveDays,
    required this.lastAccess,
    required this.role,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    var savedVideosFromData = data['savedVideosByTopic'] as Map<String, dynamic>? ?? {};
    Map<String, List<VideoWatched>> savedVideosByTopic = savedVideosFromData.map((topic, videoList) {
      List<VideoWatched> videosWatchedList = (videoList as List).map((videoData) => VideoWatched.fromMap(videoData)).toList();
      return MapEntry(topic, videosWatchedList);
    });

    var completedLevelsFromData = data['completedLevelsByTopic'] as Map<String, dynamic>? ?? {};
    Map<String, List<int>> completedLevelsByTopic = completedLevelsFromData.map((topic, levels) {
      return MapEntry(topic, List<int>.from(levels as List));
    });

    var checkpointsFromData = data['checkpoints'] as Map<String, dynamic>? ?? {};
    Map<String, int> checkpoints = checkpointsFromData.map((level, checkpoint) {
      return MapEntry(level, checkpoint as int);
    });

    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      topics: List<String>.from(data['topics'] ?? []),
      savedVideosByTopic: savedVideosByTopic,
      completedLevelsByTopic: completedLevelsByTopic,
      checkpoints: checkpoints,  // Aggiunto
      consecutiveDays: data['consecutiveDays'] ?? 0,
      lastAccess: data['lastAccess'] != null ? DateTime.parse(data['lastAccess']) : DateTime.now(),
      role: data['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'topics': topics,
      'savedVideosByTopic': savedVideosByTopic.map((topic, videos) => MapEntry(topic, videos.map((video) => video.toMap()).toList())),
      'completedLevelsByTopic': completedLevelsByTopic,
      'checkpoints': checkpoints,  // Aggiunto
      'consecutiveDays': consecutiveDays,
      'lastAccess': lastAccess.toIso8601String(),
      'role': role,
    };
  }
}

class VideoWatched {
  final String videoId;
  final String title;
  final DateTime watchedAt;

  VideoWatched({
    required this.videoId,
    required this.title,
    required this.watchedAt,
  });

  factory VideoWatched.fromMap(Map<String, dynamic> data) {
    return VideoWatched(
      videoId: data['videoId'] ?? '',
      title: data['title'] ?? '',
      watchedAt: DateTime.parse(data['watchedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'title': title,
      'watchedAt': watchedAt.toIso8601String(),
    };
  }
}