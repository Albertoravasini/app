import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/video_service.dart';
import '../widgets/video_card.dart';
import '../widgets/question_card.dart';
import 'dart:math'; // Importazione corretta per Random

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VideoService videoService = VideoService();
  List<String> viewedVideos = [];
  List<dynamic> videos = [];
  int currentIndex = 0;
  bool isLoading = true;
  String? nextPageToken;
  bool showQuestion = false;

  @override
  void initState() {
    super.initState();
    _loadViewedVideos();
  }

  Future<void> _loadViewedVideos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        viewedVideos = List<String>.from(doc.data()?['viewedVideos'] ?? []);
      });
      await _loadVideos();
    }
  }

  Future<void> _saveViewedVideos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'viewedVideos': viewedVideos,
      });
    }
  }

  Future<void> _loadVideos({bool loadMore = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      List<String> topics = List<String>.from(doc.data()?['topics'] ?? []);
      final List<dynamic> allVideos = [];
      for (String topic in topics) {
        final response = await videoService.fetchNewVideos(topic, viewedVideos, nextPageToken: loadMore ? nextPageToken : null);
        allVideos.addAll(response['videos']);
        nextPageToken = response['nextPageToken'];
      }
      // Shuffle the videos to ensure a mix of different topics
      allVideos.shuffle(Random());
      setState(() {
        videos.addAll(allVideos);
        isLoading = false;
      });
    }
  }

  Future<void> _prefetchVideo(int index) async {
    if (index < videos.length) {
      final video = videos[index];
      await videoService.prefetchVideo(video['id'], 'sd');
    }
  }

  void _markVideoAsViewed(String videoId) {
    if (!viewedVideos.contains(videoId)) {
      setState(() {
        viewedVideos.add(videoId);
      });
      _saveViewedVideos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    if (user == null) {
      return Center(child: CircularProgressIndicator());
    }

    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Home Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: videos.length + 1,
        onPageChanged: (index) async {
          if (index == videos.length) {
            await _loadVideos(loadMore: true);
          } else {
            _markVideoAsViewed(videos[index]['id']);
          }
          setState(() {
            currentIndex = index;
            showQuestion = false; // Reset showQuestion when changing page
          });
          if (index < videos.length - 1) {
            await _prefetchVideo(index + 1); // Pre-fetch next video
          }
        },
        itemBuilder: (context, index) {
          if (index == videos.length) {
            return Center(child: CircularProgressIndicator());
          }
          final video = videos[index];
          return showQuestion ? QuestionCard(video: video) : VideoCard(video: video);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            showQuestion = !showQuestion; // Toggle between video and question
          });
        },
        child: Icon(showQuestion ? Icons.video_collection : Icons.quiz),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/topics');
          }
        },
      ),
    );
  }
}