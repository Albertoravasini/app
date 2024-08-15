import 'package:Just_Learn/widgets/question_card.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/level.dart';
import '../models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/video_service.dart';

class LevelScreen extends StatefulWidget {
  final Level level;
  final VoidCallback onLevelCompleted;

  LevelScreen({required this.level, required this.onLevelCompleted});

  @override
  _LevelScreenState createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  int currentStepIndex = 0;
  bool isAnswered = false;
  bool isCorrect = false;
  double videoProgress = 0.0;
  int checkpoint = 0;
  List<Map<String, dynamic>> subtitles = [];
  String displayedText = '';

  late YoutubePlayerController _youtubeController;
  final ScrollController _scrollController = ScrollController();

  LevelStep get currentStep => widget.level.steps[currentStepIndex];

  @override
  void initState() {
    super.initState();
    _youtubeController = YoutubePlayerController(
      initialVideoId: currentStep.content,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    )..addListener(_videoProgressListener);

    _initializePlayer();
    _fetchVideoText(currentStep.content);
  }

  @override
  void dispose() {
    _youtubeController.removeListener(_videoProgressListener);
    _youtubeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initializePlayer() {
    _youtubeController.addListener(() {
      if (_youtubeController.value.isReady && !_youtubeController.value.hasPlayed) {
        _loadCheckpoint();
      }
    });
  }

  void _videoProgressListener() {
    if (_youtubeController.value.isReady && !_youtubeController.value.isFullScreen) {
      setState(() {
        final position = _youtubeController.value.position;
        final duration = _youtubeController.metadata.duration;
        if (duration.inSeconds > 0) {
          videoProgress = position.inSeconds / duration.inSeconds;
          int newCheckpoint = position.inSeconds;
          if (newCheckpoint > checkpoint) {
            checkpoint = newCheckpoint;
            _saveCheckpoint(checkpoint);
          }

          _updateDisplayedText(position.inSeconds);
        }
      });
    }
  }

  void _updateDisplayedText(int currentTime) {
    final currentWords = subtitles.where((subtitle) {
      final wordTimestamp = subtitle['timestamp'];
      return currentTime >= wordTimestamp;
    }).toList();

    // Mostra tutte le parole fino al timestamp corrente
    setState(() {
      displayedText = currentWords.map((subtitle) => subtitle['word']).join(' ');
    });

    // Scorrimento automatico verso il basso
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  int _parseTimestamp(String timestamp) {
    final parts = timestamp.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final seconds = double.parse(parts[2]);
    return (hours * 3600 + minutes * 60 + seconds).round();
  }

  Future<void> _loadCheckpoint() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        final userModel = UserModel.fromMap(userData);

        final lastCheckpoint = userModel.checkpoints[widget.level.levelNumber.toString()];
        if (lastCheckpoint != null) {
          setState(() {
            checkpoint = lastCheckpoint;
          });

          final position = Duration(seconds: lastCheckpoint);
          _youtubeController.seekTo(position);
          _youtubeController.play();
        }
      }
    }
  }

  Future<void> _saveCheckpoint(int checkpoint) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        final userModel = UserModel.fromMap(userData);

        if (userModel.checkpoints[widget.level.levelNumber.toString()] != checkpoint) {
          userModel.checkpoints[widget.level.levelNumber.toString()] = checkpoint;
          await docRef.update(userModel.toMap());
        }
      }
    }
  }

  Future<void> _fetchVideoText(String videoId) async {
    try {
      final videoUrl = 'https://www.youtube.com/watch?v=$videoId';
      final subtitlesData = await VideoService().fetchVideoText(videoUrl);
      setState(() {
        subtitles = subtitlesData.map<Map<String, dynamic>>((subtitle) => subtitle as Map<String, dynamic>).toList();
      });
    } catch (e) {
      print('Failed to fetch video text: $e');
    }
  }

  void handleAnswer(bool correct) {
    setState(() {
      isAnswered = true;
      isCorrect = correct;
    });
  }

  void nextStep() {
    setState(() {
      if (currentStepIndex < widget.level.steps.length - 1) {
        currentStepIndex++;
        isAnswered = false;
        isCorrect = false;
        if (currentStep.type == 'video') {
          _youtubeController.load(currentStep.content);
          _fetchVideoText(currentStep.content); // Estrai il testo del video per il nuovo step
        }
      } else {
        widget.onLevelCompleted();
        Navigator.pop(context, true); // Notifica il completamento e torna indietro
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false; // Impedisce il ritorno accidentale
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Livello ${widget.level.levelNumber}'),
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Column(
          children: [
            LinearProgressIndicator(
              borderRadius: BorderRadius.circular(10),
              minHeight: 10,
              value: (currentStepIndex + 1) / widget.level.steps.length,
              backgroundColor: Colors.grey[700],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 10),
            Expanded(
              child: Center(
                child: currentStep.type == 'video'
                    ? Column(
                        children: [
                          YoutubePlayer(
                            controller: _youtubeController,
                            showVideoProgressIndicator: true,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                child: Text(
                                  displayedText,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : QuestionCard(step: currentStep, onAnswered: handleAnswer),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () {
                  if (isAnswered || currentStep.type == 'video') {
                    nextStep();
                  }
                },
                child: Container(
                  width: 315,
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 117, vertical: 17),
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(width: 1, color: Colors.white),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Continua',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                                                    fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.48,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}