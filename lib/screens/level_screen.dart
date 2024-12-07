// lib/screens/level_screen.dart

import 'package:Just_Learn/models/course.dart';
import 'package:Just_Learn/models/level.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:Just_Learn/widgets/course_question_card.dart';
import 'package:Just_Learn/widgets/video_player_widget.dart';

class LevelScreen extends StatefulWidget {
  final Section section;

  const LevelScreen({super.key, required this.section});

  @override
  _LevelScreenState createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  int _currentStep = 0;
  bool sectionCompleted = false;
  PageController? _pageController;
  LevelStep? currentStepData;
  String currentTitle = ''; // Aggiungi questa variabile

  @override
  void initState() {
    super.initState();
    _loadUserProgress(); // Carica il progresso dell'utente
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  // Carica il progresso dell'utente da Firestore
Future<void> _loadUserProgress() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();

    if (snapshot.exists) {
      final userData = snapshot.data()!;
      // Verifica che 'currentSteps' sia una mappa
      if (userData['currentSteps'] is Map) {
        final currentStepsMap = Map<String, dynamic>.from(userData['currentSteps']);
        setState(() {
          _currentStep = currentStepsMap[widget.section.title]?.toInt() ?? 0;
          sectionCompleted = (userData['completedSections'] ?? []).contains(widget.section.title);
          _pageController = PageController(initialPage: _currentStep);
          currentStepData = widget.section.steps.length > _currentStep
              ? widget.section.steps[_currentStep]
              : null;
          currentTitle = currentStepData?.type == 'video' ? currentStepData!.content : widget.section.title;
          print('Loaded currentStep for ${widget.section.title}: $_currentStep');
        });
      } else {
        setState(() {
          _currentStep = 0;
          sectionCompleted = false;
          _pageController = PageController(initialPage: _currentStep);
          currentStepData = widget.section.steps.isNotEmpty ? widget.section.steps[0] : null;
          currentTitle = currentStepData?.type == 'video' ? currentStepData!.content : widget.section.title;
          print('currentSteps is not a Map. Defaulting to 0.');
        });
      }
    } else {
      setState(() {
        _currentStep = 0;
        sectionCompleted = false;
        _pageController = PageController(initialPage: _currentStep);
        currentStepData = widget.section.steps.isNotEmpty ? widget.section.steps[0] : null;
        currentTitle = currentStepData?.type == 'video' ? currentStepData!.content : widget.section.title;
        print('User document does not exist. Defaulting to step 0.');
      });
    }
  } else {
    setState(() {
      _currentStep = 0;
      sectionCompleted = false;
      _pageController = PageController(initialPage: _currentStep);
      currentStepData = widget.section.steps.isNotEmpty ? widget.section.steps[0] : null;
      currentTitle = currentStepData?.type == 'video' ? currentStepData!.content : widget.section.title;
      print('User not authenticated. Defaulting to step 0.');
    });
  }
}

  // Salva il progresso dell'utente su Firestore
  Future<void> _saveUserProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

      await userDoc.update({
        // Se la sezione è completata, imposta currentStep al numero totale di step
        'currentSteps.${widget.section.title}': sectionCompleted ? widget.section.steps.length : _currentStep,
        if (sectionCompleted)
          'completedSections': FieldValue.arrayUnion([widget.section.title]),
      });
      print('Progress saved: step $_currentStep, sectionCompleted: $sectionCompleted');
    }
  }

  // Gestisce il completamento di uno step
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
        // Sezione completata
        sectionCompleted = true;
        _saveUserProgress();
        // Torna alla CourseDetailScreen e indica che il progresso è stato aggiornato
        Navigator.pop(context, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.section.steps;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: _pageController == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Main content (Video/Questions)
                PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: steps.length,
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                      currentStepData = steps[index];
                      currentTitle = currentStepData?.type == 'video' 
                        ? currentStepData!.content 
                        : widget.section.title;
                      
                      if (_currentStep == steps.length - 1) {
                        sectionCompleted = true;
                      }
                      _saveUserProgress();
                    });
                  },
                  itemBuilder: (context, index) {
                    final step = steps[index];

                    if (step.type == 'video') {
                      final videoId = YoutubePlayer.convertUrlToId(step.content) ?? '';
                      if (videoId.isEmpty) {
                        return const Center(
                          child: Text(
                            'URL video non valido',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }
                     
                    } else if (step.type == 'question') {
                      return CourseQuestionCard(
                        step: step,
                        onAnswered: (isCorrect) {
                          if (isCorrect) {
                            _onCompleteStep();
                          }
                        },
                        onCompleteStep: _onCompleteStep,
                        topic: widget.section.title,
                      );
                    }
                    
                    return const Center(
                      child: Text(
                        'Unknown step type',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),

                // Overlay controls
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      child: Column(
                        children: [
                          // Top row with back button and progress
                          Row(
                            children: [
                              // Back button
                              GestureDetector(
                                onTap: () async {
                                  await _saveUserProgress();
                                  Navigator.pop(context, true);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Progress indicator
                              Expanded(
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Stack(
                                    children: [
                                      AnimatedFractionallySizedBox(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        alignment: Alignment.centerLeft,
                                        widthFactor: (_currentStep + 1) / steps.length,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:  Colors.yellowAccent,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              // Step counter
                              Container(
                                margin: const EdgeInsets.only(left: 16),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${_currentStep + 1}/${steps.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
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