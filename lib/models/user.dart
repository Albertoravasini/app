import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final List<String> topics;
  final Map<String, List<VideoWatched>> WatchedVideos;
  final Map<String, List<String>> answeredQuestions;
  int consecutiveDays;
  DateTime lastAccess;
  final String role;
  final List<Notification> notifications; // Aggiungi questo campo

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.topics,
    required this.WatchedVideos,
    required this.answeredQuestions,
    required this.consecutiveDays,
    required this.lastAccess,
    required this.role,
    this.notifications = const [], // Inizializza come lista vuota
  });

  // Aggiungi questo nella classe UserModel, all'interno del factory UserModel.fromMap.
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
  List<Notification> notifications = [];

  try {
    print('Parsing le notifiche...');
    notifications = notificationsFromData.map((notificationData) {
      print('Dati notifica: $notificationData');
      return Notification.fromMap(notificationData);
    }).toList();

    // Rimuovi duplicati in base all'ID della notifica
    final uniqueNotifications = {for (var n in notifications) n.id: n}.values.toList();
    notifications = uniqueNotifications;

  } catch (e) {
    print('Errore durante la conversione delle notifiche: $e');
  }

  print('Notifiche finali: $notifications'); // Debug per vedere le notifiche finali

  return UserModel(
    uid: data['uid'] ?? '',
    email: data['email'] ?? '',
    name: data['name'] ?? '',
    topics: List<String>.from(data['topics'] ?? []),
    WatchedVideos: WatchedVideos,
    answeredQuestions: answeredQuestions,
    consecutiveDays: data['consecutiveDays'] ?? 0,
    lastAccess: data['lastAccess'] != null ? DateTime.parse(data['lastAccess']) : DateTime.now(),
    role: data['role'] ?? 'user',
    notifications: notifications, // Aggiungi questa linea
  );
}

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'topics': topics,
      'WatchedVideos': WatchedVideos.map((topic, videos) => MapEntry(topic, videos.map((video) => video.toMap()).toList())),
      'answeredQuestions': answeredQuestions,
      'consecutiveDays': consecutiveDays,
      'lastAccess': lastAccess.toIso8601String(),
      'role': role,
      'notifications': notifications.map((notification) => notification.toMap()).toList(), // Aggiungi questa linea
    };
  }
}

class Notification {
  final String id;
  final String message;
  bool isRead; // Rimuovi `final` per rendere modificabile questo campo
  final DateTime timestamp;
  final String? videoId;

  Notification({
    required this.id,
    required this.message,
    this.isRead = false, // Puoi modificare questo campo in futuro
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
        : DateTime.parse(data['timestamp']), // Aggiungi questo per gestire il caso in cui sia una stringa
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
class Comment {
  final String commentId;
  final String userId;
  final String username; // Aggiungi questo campo
  final String videoId;
  final String content;
  final DateTime timestamp;
  final int likeCount;
  final List<Comment> replies;

  Comment({
    required this.commentId,
    required this.userId,
    required this.username, // Aggiungi questo campo
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
      username: data['username'] ?? '', // Aggiungi questo campo
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
      'username': username, // Aggiungi questo campo
      'videoId': videoId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'likeCount': likeCount,
      'replies': replies.map((reply) => reply.toMap()).toList(),
    };
  }
}