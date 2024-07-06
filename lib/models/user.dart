class UserModel {
  final String uid;
  final String email;
  final String name;
  final List<String> topics;
  final Map<String, List<VideoWatched>> savedVideosByTopic;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.topics,
    required this.savedVideosByTopic,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    var savedVideosFromData = data['savedVideosByTopic'] as Map<String, dynamic>? ?? {};
    Map<String, List<VideoWatched>> savedVideosByTopic = savedVideosFromData.map((topic, videoList) {
      List<VideoWatched> videosWatchedList = (videoList as List).map((videoData) => VideoWatched.fromMap(videoData)).toList();
      return MapEntry(topic, videosWatchedList);
    });
    return UserModel(
      uid: data['uid'],
      email: data['email'],
      name: data['name'],
      topics: List<String>.from(data['topics']),
      savedVideosByTopic: savedVideosByTopic,
    );
  }

  get videosWatched => null;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'topics': topics,
      'savedVideosByTopic': savedVideosByTopic.map((topic, videos) => MapEntry(topic, videos.map((video) => video.toMap()).toList())),
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
      videoId: data['videoId'],
      title: data['title'],
      watchedAt: DateTime.parse(data['watchedAt']),
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