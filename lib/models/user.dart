class UserModel {
  final String uid;
  final String email;
  final String name;
  final List<String> topics;
  final List<VideoWatched> videosWatched;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.topics,
    required this.videosWatched,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    var videosWatchedFromData = data['videosWatched'] as List<dynamic>? ?? [];
    List<VideoWatched> videosWatchedList = videosWatchedFromData.map((videoData) => VideoWatched.fromMap(videoData)).toList();
    return UserModel(
      uid: data['uid'],
      email: data['email'],
      name: data['name'],
      topics: List<String>.from(data['topics']),
      videosWatched: videosWatchedList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'topics': topics,
      'videosWatched': videosWatched.map((video) => video.toMap()).toList(),
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