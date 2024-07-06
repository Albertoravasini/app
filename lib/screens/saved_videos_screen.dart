import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class SavedVideosScreen extends StatelessWidget {
  final Map<String, List<dynamic>> savedVideos;

  SavedVideosScreen({required this.savedVideos});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> allSavedVideos = savedVideos.values.expand((videos) => videos).toList();

    if (allSavedVideos.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Saved Videos'),
        ),
        body: Center(
          child: Text('No saved videos available.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Videos'),
      ),
      body: ListView.builder(
        itemCount: allSavedVideos.length,
        reverse: true, // Imposta questo a true per mostrare il più recente in alto
        itemBuilder: (context, index) {
          final video = allSavedVideos[index];
          return ListTile(
            title: Text(
              video['snippet']['title'],
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoDetailScreen(video: video),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class VideoDetailScreen extends StatelessWidget {
  final dynamic video;

  VideoDetailScreen({required this.video});

  @override
  Widget build(BuildContext context) {
    final videoId = video['id'];
    final videoTitle = video['snippet']['title'];
    final videoDescription = video['snippet']['description'];

    return Scaffold(
      appBar: AppBar(
        title: Text(videoTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            YoutubePlayer(
              controller: YoutubePlayerController(
                initialVideoId: videoId,
                flags: YoutubePlayerFlags(
                  autoPlay: true,
                  mute: false,
                ),
              ),
              showVideoProgressIndicator: true,
            ),
            SizedBox(height: 20),
            Text(
              videoDescription,
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}