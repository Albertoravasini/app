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
    int dailyVideosCompleted;
  int dailyQuizFreeUses;
  final bool hasSeenTutorial;
  final String? profileImageUrl;
  final String? username;
  final String? bio;
  final String? coverImageUrl;
  final List<String> followers;
  final List<String> following;
  final List<String> subscriptions;
  final double subscriptionPrice;
  final String subscriptionDescription1;
  final String subscriptionDescription2;
  final String subscriptionDescription3;
  final String? location;

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
    this.dailyVideosCompleted = 0,
    this.dailyQuizFreeUses = 0,
    this.hasSeenTutorial = false,
    this.profileImageUrl,
    this.username,
    this.bio,
    this.coverImageUrl,
    this.followers = const [],
    this.following = const [],
    this.subscriptions = const [],
    this.subscriptionPrice = 9.99,
    this.subscriptionDescription1 = 'Full access to this user\'s content',
    this.subscriptionDescription2 = 'Full access to this user\'s content',
    this.subscriptionDescription3 = 'Full access to this user\'s content',
    this.location,
  }) ;
 

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

    Map<String, int> currentStepsMap = {};
    final currentStepsData = data['currentSteps'] as Map<String, dynamic>? ?? {};
    currentStepsData.forEach((key, value) {
      if (value is int) {
        currentStepsMap[key] = value;
      } else if (value is num) {
        currentStepsMap[key] = value.toInt();
      } else {
        currentStepsMap[key] = 0; // valore di default
      }
    });

    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      topics: List<String>.from(data['topics'] ?? []),
      WatchedVideos: WatchedVideos,
      answeredQuestions: answeredQuestions,
      currentSteps: currentStepsMap,
      completedSections: List<String>.from(data['completedSections'] ?? []), // Carica le sezioni completate
      consecutiveDays: data['consecutiveDays'] ?? 0,
      lastAccess: data['lastAccess'] != null ? DateTime.parse(data['lastAccess']) : DateTime.now(),
      role: data['role'] ?? 'user',
      notifications: notifications,
      coins: data['coins'] ?? 0,  // Assicurati che il campo coins sia nel database
      unlockedCourses: List<String>.from(data['unlockedCourses'] ?? []),
      dailyVideosCompleted: data['dailyVideosCompleted'] ?? 0,
      dailyQuizFreeUses: data['dailyQuizFreeUses'] ?? 0,
      hasSeenTutorial: data['hasSeenTutorial'] ?? false,
      profileImageUrl: data['profileImageUrl'],
      username: data['username'],
      bio: data['bio'],
      coverImageUrl: data['coverImageUrl'],
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      subscriptions: List<String>.from(data['subscriptions'] ?? []),
      subscriptionPrice: (data['subscriptionPrice'] ?? 9.99).toDouble(),
      subscriptionDescription1: data['subscriptionDescription1'] ?? 'Full access to this user\'s content',
      subscriptionDescription2: data['subscriptionDescription2'] ?? 'Full access to this user\'s content',
      subscriptionDescription3: data['subscriptionDescription3'] ?? 'Full access to this user\'s content',
      location: data['location'],
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
      'dailyVideosCompleted': dailyVideosCompleted,
      'dailyQuizFreeUses': dailyQuizFreeUses,
      'hasSeenTutorial': hasSeenTutorial,
      'profileImageUrl': profileImageUrl,
      'username': username,
      'bio': bio,
      'coverImageUrl': coverImageUrl,
      'followers': followers,
      'following': following,
      'subscriptions': subscriptions,
      'subscriptionPrice': subscriptionPrice,
      'subscriptionDescription1': subscriptionDescription1,
      'subscriptionDescription2': subscriptionDescription2,
      'subscriptionDescription3': subscriptionDescription3,
      'location': location,
    };
  }
}

// Modello per la gestione delle notifiche
class Notification {
  final String id;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? videoId;
  final bool isFromTeacher;

  Notification({
    required this.id,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.videoId,
    this.isFromTeacher = false,
  });

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp']?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      videoId: map['videoId'],
      isFromTeacher: map['isFromTeacher'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead,
      'videoId': videoId,
      'isFromTeacher': isFromTeacher,
    };
  }
}

// models/video_watched.dart
class VideoWatched {
  final String videoId;
  final String title;
  final DateTime watchedAt;
  final bool completed;
  final int watchTime;
  final int interactions;

  VideoWatched({
    required this.videoId,
    required this.title,
    required this.watchedAt,
    this.completed = false,
    this.watchTime = 0,
    this.interactions = 0,
  });

  factory VideoWatched.fromMap(Map<String, dynamic> data) {
    return VideoWatched(
      videoId: data['videoId'] ?? '',
      title: data['title'] ?? '',
      watchedAt: DateTime.parse(data['watchedAt'] ?? DateTime.now().toIso8601String()),
      completed: data['completed'] ?? false,
      watchTime: data['watchTime'] ?? 0,
      interactions: data['interactions'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'title': title,
      'watchedAt': watchedAt.toIso8601String(),
      'completed': completed,
      'watchTime': watchTime,
      'interactions': interactions,
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