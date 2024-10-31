import 'package:flutter/material.dart';
import 'package:Just_Learn/models/course.dart';
import 'package:Just_Learn/models/level.dart';
import 'package:Just_Learn/widgets/course_question_card.dart';
import 'package:Just_Learn/widgets/video_player_widget.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LevelScreen extends StatefulWidget {
  final Section section;

  const LevelScreen({super.key, required this.section});

  @override
  _LevelScreenState createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  int _currentStep = 0;
  bool sectionCompleted = false;
  YoutubePlayerController? _youtubeController;
  PageController? _pageController;
  LevelStep? currentStepData;

  @override
  void initState() {
    super.initState();
    _loadUserProgress(); // Load user progress
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  // Initialize video player if the step is a video
  void _initializePlayer(LevelStep step) {
    if (step.type == 'video' && step.content.isNotEmpty) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: YoutubePlayer.convertUrlToId(step.content)!,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
        ),
      );
    } else {
      _youtubeController?.dispose();
      _youtubeController = null;
    }
  }

  // Load user progress from Firestore
  Future<void> _loadUserProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshot = await userDoc.get();

      if (snapshot.exists) {
        final userData = snapshot.data()!;
        setState(() {
          _currentStep = userData['currentSteps'][widget.section.title] ?? 0;
          sectionCompleted = (userData['completedSections'] ?? []).contains(widget.section.title);
          _pageController = PageController(initialPage: _currentStep);
        });
      } else {
        _pageController = PageController(initialPage: _currentStep);
      }
    } else {
      _pageController = PageController(initialPage: _currentStep);
    }
  }

  // Save user progress to Firestore
  Future<void> _saveUserProgress() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

    await userDoc.update({
      // If section is completed, set currentStep to the total number of steps
      'currentSteps.${widget.section.title}':
          sectionCompleted ? widget.section.steps.length : _currentStep,
      if (sectionCompleted)
        'completedSections': FieldValue.arrayUnion([widget.section.title]),
    });
  }
}

  // Handle completion of a step
  void _onCompleteStep() {
    setState(() {
      if (_currentStep < widget.section.steps.length - 1) {
        _currentStep += 1;
        _pageController?.animateToPage(
          _currentStep,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _saveUserProgress();
      } else {
        // Section completed
        sectionCompleted = true;
        _saveUserProgress();
        // Navigate back to CourseDetailScreen and indicate that progress has been updated
        Navigator.pop(context, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.section.steps;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const SizedBox(height: 30),

          // Custom progress bar with "back" button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Back button
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Container(
                    height: 15,
                    decoration: ShapeDecoration(
                      color: const Color(0xFF181819),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: ((MediaQuery.of(context).size.width - 80) *
                                  (_currentStep + 1) /
                                  steps.length)
                              .clamp(0.0, MediaQuery.of(context).size.width - 80),
                          height: 15,
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 5),

          // Section title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: ShapeDecoration(
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Center(
              child: Text(
                widget.section.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: 0.66,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 5),

          // Main body with vertical PageView
          Expanded(
            child: PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: steps.length,
              controller: _pageController,
              onPageChanged: (index) {
  setState(() {
    _currentStep = index;
    currentStepData = steps[index];
    _initializePlayer(steps[index]);

    // Check if the last step is reached
    if (_currentStep == steps.length - 1) {
      sectionCompleted = true;
    } else {
      sectionCompleted = false;
    }

    _saveUserProgress();
  });
},
              itemBuilder: (context, index) {
                final step = steps[index];

                if (step.type == 'video') {
                  // Return VideoPlayerWidget
                  _initializePlayer(step);
                  if (_youtubeController == null) {
                    return Center(child: CircularProgressIndicator());
                  }
                  return VideoPlayerWidget(
  controller: _youtubeController!,
  onShowQuestion: () {},
  isLiked: false,
  likeCount: 0,
  isSaved: false,
  onCoinsUpdate: (int newCoins) {
    // Aggiungi la logica qui per gestire l'aggiornamento dei coins.
    // Ad esempio, puoi stampare il nuovo numero di coins o aggiornarlo
    print("Coins aggiornati: $newCoins");
  },
  topic: widget.section.title,  // Aggiungi il parametro topic qui
);
                } else if (step.type == 'question') {
                  // Return CourseQuestionCard
                  return CourseQuestionCard(
                    step: step,
                    onAnswered: (isCorrect) {},
                    onCompleteStep: () {},
                    topic: widget.section.title,
                  );
                } else {
                  // Handle other step types if any
                  return Center(
                    child: Text(
                      'Unknown step type',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }
              },
            ),
          ),

          // "Next" button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: SizedBox(
              ),
          ),
        ],
      ),
    );
  }
}