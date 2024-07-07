import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/video_service.dart';
import '../widgets/video_card.dart';
import '../widgets/question_card.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'topic_selection_screen.dart';
import '../styles/colors.dart';

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
  Map<String, List<dynamic>> savedVideos = {};
  bool isSaving = false;
  String? selectedTopic;
  int _selectedIndex = 0;
  PageController _pageController = PageController();
  String? currentVideoId;
  double currentVideoPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _loadViewedVideos();
    _loadSavedVideos();
    _loadCurrentVideoState();
  }

  Future<void> _loadViewedVideos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      viewedVideos = prefs.getStringList('viewedVideos') ?? [];
    });
    await _loadVideos();
  }

  Future<void> _saveViewedVideos() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('viewedVideos', viewedVideos);
  }

  Future<void> _loadSavedVideos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final savedVideosData = data['savedVideosByTopic'] as Map<String, dynamic>? ?? {};
        setState(() {
          savedVideos = savedVideosData.map((topic, videos) {
            return MapEntry(topic, List<dynamic>.from(videos));
          });
        });
      }
    }
  }

  Future<void> _saveVideo(String topic, dynamic video) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        isSaving = true;
      });

      final category = video['snippet']['category'] ?? 'Uncategorized';

      if (!savedVideos.containsKey(category)) {
        savedVideos[category] = [];
      }

      savedVideos[category]!.add(video);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'savedVideosByTopic': savedVideos.map((key, value) => MapEntry(key, value.map((video) => video).toList())),
      });

      setState(() {
        isSaving = false;
        savedVideos = Map.from(savedVideos);
      });
    }
  }

  Future<void> _removeSavedVideo(String topic, dynamic video) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        isSaving = true;
      });

      savedVideos[topic]?.removeWhere((v) => v['id'] == video['id']);
      if (savedVideos[topic]?.isEmpty ?? false) {
        savedVideos.remove(topic);
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'savedVideosByTopic': savedVideos,
      });

      setState(() {
        isSaving = false;
        savedVideos = Map.from(savedVideos);

        if (selectedTopic != null && (savedVideos[selectedTopic]?.isEmpty ?? true)) {
          _clearSelectedTopic();
        }
      });
    }
  }

  Future<void> _loadVideos({bool loadMore = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      List<String> topics = List<String>.from(doc.data()?['topics'] ?? []);
      final List<dynamic> allVideos = [];

      print('Fetching new videos for topics: $topics');
      final response = await videoService.fetchNewVideos(topics, viewedVideos, nextPageToken: loadMore ? nextPageToken : null);
      allVideos.addAll(response['videos']);
      nextPageToken = response['nextPageToken'];

      allVideos.shuffle(Random());
      if (mounted) {
        setState(() {
          videos = allVideos;
          isLoading = false;
        });
        print('Loaded ${allVideos.length} videos.');
      }
    }
  }

  Future<void> _prefetchVideo(int index) async {
    if (index < videos.length) {
      final video = videos[index];
      await videoService.prefetchVideo(video['id'], 'sd');
    }
  }

  void _markVideoAsViewed(String videoId) {
    if (!viewedVideos.contains(videoId) && mounted) {
      setState(() {
        viewedVideos.add(videoId);
      });
      _saveViewedVideos();
      print('Marked video as viewed: $videoId');
    }
  }

  void _toggleTopic(String topic) {
    if (selectedTopic == topic) {
      _clearSelectedTopic();
    } else {
      _selectTopic(topic);
    }
  }

  void _selectTopic(String topic) {
    setState(() {
      selectedTopic = topic;
      videos = savedVideos[selectedTopic] ?? [];
      currentIndex = 0;
    });
  }

  void _clearSelectedTopic() async {
    setState(() {
      selectedTopic = null;
      currentIndex = 0;
      isLoading = true;
    });
    await _loadVideos();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _navigateToTopicSelectionScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TopicSelectionScreen(user: FirebaseAuth.instance.currentUser!),
      ),
    );

    if (result == true) {
      setState(() {
        isLoading = true;
      });
      await _loadVideos();
    }
  }

  Future<void> _saveCurrentVideoState() async {
    final prefs = await SharedPreferences.getInstance();
    if (currentVideoId != null) {
      prefs.setString('currentVideoId', currentVideoId!);
      prefs.setDouble('currentVideoPosition', currentVideoPosition);
    }
  }

  Future<void> _loadCurrentVideoState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentVideoId = prefs.getString('currentVideoId');
      currentVideoPosition = prefs.getDouble('currentVideoPosition') ?? 0.0;
    });
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

    final displayedVideos = selectedTopic != null
        ? savedVideos[selectedTopic] ?? []
        : videos;

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
      body: Stack(
        children: [
          Positioned.fill(
            child: displayedVideos.isEmpty
                ? Center(child: Text('No videos saved', style: TextStyle(color: Colors.white)))
                : PageView.builder(
                  key: ValueKey<String?>(selectedTopic),
                    scrollDirection: Axis.vertical,
                    itemCount: displayedVideos.length,
                    controller: _pageController,
                    onPageChanged: (index) async {
                      if (index == displayedVideos.length - 1 && selectedTopic == null) {
                        await _loadVideos(loadMore: true);
                      } else {
                        if (index > 0) {
                          _markVideoAsViewed(displayedVideos[index - 1]['id']);
                        }
                      }
                      if (mounted) {
                        setState(() {
                          currentIndex = index;
                          showQuestion = false;
                          currentVideoId = displayedVideos[index]['id'];
                          currentVideoPosition = 0.0;
                        });
                        _saveCurrentVideoState();
                      }
                      if (index < displayedVideos.length - 1) {
                        await _prefetchVideo(index + 1);
                      }
                    },
                    itemBuilder: (context, index) {
                      final video = displayedVideos[index];
                                            final topic = video['snippet']['category'] ?? 'Uncategorized';
                      final isChecked = savedVideos[topic]?.any((v) => v['id'] == video['id']) ?? false;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          showQuestion
                              ? QuestionCard(video: video)
                              : VideoCard(
                                  video: video,
                                  isChecked: isChecked,
                                  onCheckChanged: (bool? value) async {
                                    if (value == true) {
                                      await _saveVideo(topic, video);
                                    } else {
                                      await _removeSavedVideo(topic, video);
                                    }
                                    setState(() {});
                                  },
                                  initialPosition: (video['id'] == currentVideoId) ? currentVideoPosition : 0.0,
                                  onVideoPositionChanged: (position) {
                                    if (video['id'] == currentVideoId) {
                                      setState(() {
                                        currentVideoPosition = position;
                                      });
                                      _saveCurrentVideoState();
                                    }
                                  },
                                ),
                        ],
                      );
                    },
                  ),
          ),
          if (savedVideos.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 5.0),
                color: Colors.black,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: savedVideos.keys.map((topic) {
                      final isSelected = selectedTopic == topic;
                      return GestureDetector(
                        onTap: () => _toggleTopic(topic),
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 4.0),
                          padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.black,
                            border: Border.all(color: Colors.white, width: 1),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Text(
                            topic,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (mounted) {
            setState(() {
              showQuestion = !showQuestion;
            });
          }
        },
        child: Icon(showQuestion ? Icons.video_collection : Icons.quiz),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Topics',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            _clearSelectedTopic();
          } else if (index == 1) {
            _navigateToTopicSelectionScreen();
          }
        },
      ),
    );
  }
}