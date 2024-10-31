import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final List<String> topics;
  final Map<String, List<VideoWatched>> WatchedVideos;
  final Map<String, List<String>> answeredQuestions;
  final Map<String, int> currentSteps; // Memorizza lo step corrente per ogni sezione
  final List<String> completedSections; // Memorizza le sezioni completate
  int consecutiveDays;
  DateTime lastAccess;
  final String role;
  final List<Notification> notifications;
  List<String> unlockedCourses; // Remove 'final' to allow updates
  int coins;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.topics,
    required this.WatchedVideos,
    required this.answeredQuestions,
    required this.currentSteps, // Inizializza lo stato dello step corrente
    required this.completedSections, // Inizializza lo stato delle sezioni completate
    required this.consecutiveDays,
    required this.lastAccess,
    required this.role,
    this.notifications = const [],
    this.unlockedCourses = const [],
    required this.coins,
  });

  // Factory per creare un UserModel dai dati Firestore
  factory UserModel.fromMap(Map<String, dynamic> data) {
    var watchedVideosFromData = data['WatchedVideos'] as Map<String, dynamic>? ?? {};
    Map<String, List<VideoWatched>> WatchedVideos = watchedVideosFromData.map((topic, videoList) {
      List<VideoWatched> videosWatchedList = (videoList as List).map((videoData) => VideoWatched.fromMap(videoData)).toList();
      return MapEntry(topic, videosWatchedList);
    });

    var answeredQuestionsFromData = data['answeredQuestions'] as Map<String, dynamic>? ?? {};
    Map<String, List<String>> answeredQuestions = answeredQuestionsFromData.map((level, questions) {
      return MapEntry(level, List<String>.from(questions as List));
    });

    var notificationsFromData = data['notifications'] as List<dynamic>? ?? [];
    List<Notification> notifications = notificationsFromData.map((notificationData) => Notification.fromMap(notificationData)).toList();

    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      topics: List<String>.from(data['topics'] ?? []),
      WatchedVideos: WatchedVideos,
      answeredQuestions: answeredQuestions,
      currentSteps: Map<String, int>.from(data['currentSteps'] ?? {}), // Carica lo step corrente
      completedSections: List<String>.from(data['completedSections'] ?? []), // Carica le sezioni completate
      consecutiveDays: data['consecutiveDays'] ?? 0,
      lastAccess: data['lastAccess'] != null ? DateTime.parse(data['lastAccess']) : DateTime.now(),
      role: data['role'] ?? 'user',
      notifications: notifications,
      coins: data['coins'] ?? 0,  // Assicurati che il campo coins sia nel database
      unlockedCourses: List<String>.from(data['unlockedCourses'] ?? []),
    );
  }

  // Metodo per convertire un UserModel in una mappa compatibile con Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'topics': topics,
      'WatchedVideos': WatchedVideos.map((topic, videos) => MapEntry(topic, videos.map((video) => video.toMap()).toList())),
      'answeredQuestions': answeredQuestions,
      'currentSteps': currentSteps, // Mappa lo step corrente
      'completedSections': completedSections, // Mappa le sezioni completate
      'consecutiveDays': consecutiveDays,
      'lastAccess': lastAccess.toIso8601String(),
      'role': role,
      'notifications': notifications.map((notification) => notification.toMap()).toList(),
      'coins': coins,
      'unlockedCourses': unlockedCourses,
    };
  }
}

// Modello per la gestione delle notifiche
class Notification {
  final String id;
  final String message;
  bool isRead;
  final DateTime timestamp;
  final String? videoId;

  Notification({
    required this.id,
    required this.message,
    this.isRead = false,
    required this.timestamp,
    this.videoId,
  });

  factory Notification.fromMap(Map<String, dynamic> data) {
    return Notification(
      id: data['id'] ?? '',
      message: data['message'] ?? '',
      isRead: data['isRead'] ?? false,
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.parse(data['timestamp']),
      videoId: data['videoId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'isRead': isRead,
      'timestamp': timestamp.toIso8601String(),
      'videoId': videoId,
    };
  }

  @override
  String toString() {
    return 'Notification{id: $id, message: $message, isRead: $isRead, timestamp: $timestamp, videoId: $videoId}';
  }
}

// models/video_watched.dart
class VideoWatched {
  final String videoId;
  final String title;
  final DateTime watchedAt;
  final bool completed;

  VideoWatched({
    required this.videoId,
    required this.title,
    required this.watchedAt,
    this.completed = false,
  });

  factory VideoWatched.fromMap(Map<String, dynamic> data) {
    return VideoWatched(
      videoId: data['videoId'] ?? '',
      title: data['title'] ?? '',
      watchedAt: DateTime.parse(data['watchedAt'] ?? DateTime.now().toIso8601String()),
      completed: data['completed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'title': title,
      'watchedAt': watchedAt.toIso8601String(),
      'completed': completed,
    };
  }
}

// Modello per la gestione dei commenti
class Comment {
  final String commentId;
  final String userId;
  final String username;
  final String videoId;
  final String content;
  final DateTime timestamp;
  final int likeCount;
  final List<Comment> replies;

  Comment({
    required this.commentId,
    required this.userId,
    required this.username,
    required this.videoId,
    required this.content,
    required this.timestamp,
    this.likeCount = 0,
    this.replies = const [],
  });

  factory Comment.fromMap(Map<String, dynamic> data) {
    return Comment(
      commentId: data['commentId'] ?? '',
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      videoId: data['videoId'] ?? '',
      content: data['content'] ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.tryParse(data['timestamp']) ?? DateTime.now(),
      likeCount: data['likeCount'] ?? 0,
      replies: (data['replies'] as List<dynamic>?)
              ?.map((replyData) => Comment.fromMap(replyData))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'userId': userId,
      'username': username,
      'videoId': videoId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'likeCount': likeCount,
      'replies': replies.map((reply) => reply.toMap()).toList(),
    };
  }
}