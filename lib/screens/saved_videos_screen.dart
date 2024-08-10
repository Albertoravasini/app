import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class SavedVideosScreen extends StatefulWidget {
  final Map<String, List<dynamic>> savedVideos;

  SavedVideosScreen({required this.savedVideos});

  @override
  _SavedVideosScreenState createState() => _SavedVideosScreenState();
}

class _SavedVideosScreenState extends State<SavedVideosScreen> {
  List<dynamic> allSavedVideos = [];

  @override
  void initState() {
    super.initState();
    _fetchSavedVideos();
  }

  void _fetchSavedVideos() async {
    // Fetch saved videos from the database
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          final savedVideos = (userData['savedVideosByTopic'] as Map<String, dynamic>).cast<String, List<dynamic>>();
          setState(() {
            allSavedVideos = savedVideos.values.expand((videos) => videos).toList();
            allSavedVideos.shuffle(); // Shuffle videos to display randomly
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (allSavedVideos.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Video Salvati'),
        ),
        body: Center(
          child: Text('Nessun video salvato disponibile.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Video Salvati'),
      ),
      body: ListView.builder(
        itemCount: allSavedVideos.length,
        itemBuilder: (context, index) {
          final video = allSavedVideos[index];
          return ListTile(
            title: Text(
              video['title'],
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
    final videoId = video['videoId'];
    final videoTitle = video['title'];
    final videoDescription = video['description'];

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