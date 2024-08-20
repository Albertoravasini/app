import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/level.dart';
import 'level_screen.dart';

class ShortsScreen extends StatefulWidget {
  @override
  _ShortsScreenState createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen> {
  List<Map<String, dynamic>> allShortSteps = [];
  PageController _pageController = PageController();
  List<YoutubePlayerController> _youtubeControllers = [];

  @override
  void initState() {
    super.initState();
    _loadAllShortSteps();
  }
  

  Future<void> _loadAllShortSteps() async {
    final levelsCollection = FirebaseFirestore.instance.collection('levels');
    final querySnapshot = await levelsCollection.get();
    final levels = querySnapshot.docs.map((doc) => Level.fromFirestore(doc)).toList();

    final shortSteps = levels.expand((level) => level.steps.where((step) => step.type == 'video' && step.isShort)).toList();

    final shortStepsWithLevel = shortSteps.map((step) {
      final level = levels.firstWhere((l) => l.steps.contains(step));
      return {
        'step': step,
        'level': level,
      };
    }).toList();

    shortStepsWithLevel.shuffle(); 

    _youtubeControllers = shortStepsWithLevel.map((shortStep) {
      final videoId = (shortStep['step'] as LevelStep).content;
      return YoutubePlayerController(
        initialVideoId: videoId,
        flags: YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
        ),
      );
    }).toList();

    setState(() {
      allShortSteps = shortStepsWithLevel;
    });
  }

  @override
  void dispose() {
    for (var controller in _youtubeControllers) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _onContinuePressed(int index) {
    final level = allShortSteps[index]['level'];
    if (level != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LevelScreen(
            level: level,
            initialStepIndex: 1,  // Inizia dallo step due (indice 1)
            onLevelCompleted: () {
              // Puoi gestire il completamento del livello qui
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: allShortSteps.isEmpty
          ? Center(child: CircularProgressIndicator())
          : PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: allShortSteps.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.9,
                            height: MediaQuery.of(context).size.height * 0.8,
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                height: MediaQuery.of(context).size.height,
                                child: AspectRatio(
                                  aspectRatio: 9 / 16,
                                  child: YoutubePlayer(
                                    controller: _youtubeControllers[index],
                                    showVideoProgressIndicator: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: () => _onContinuePressed(index),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          minimumSize: Size(343, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Continua',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}