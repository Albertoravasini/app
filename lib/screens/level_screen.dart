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
      backgroundColor: Colors.black,
      body: _pageController == null
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 30),

                // Barra di progresso personalizzata con pulsante "indietro"
                // Barra di progresso personalizzata con pulsante "indietro"
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 0),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      // Pulsante indietro
      GestureDetector(
        onTap: () async {
          await _saveUserProgress();
          Navigator.pop(context, true);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
          child: FractionallySizedBox(
            widthFactor: (_currentStep + 1) / steps.length,
            alignment: Alignment.centerLeft,
            child: Container(
              height: 15,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  ),
),

                // Titolo della sezione
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  decoration: ShapeDecoration(
                    color: const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.section.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: 0.66,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Corpo principale con PageView verticale
                Expanded(
                  child: PageView.builder(
  scrollDirection: Axis.vertical,
  itemCount: steps.length,
  controller: _pageController,
  onPageChanged: (index) {
    setState(() {
      _currentStep = index;
      currentStepData = steps[index];
      
      // Aggiorna il titolo corrente
      currentTitle = currentStepData?.type == 'video' ? currentStepData!.content : widget.section.title;

      // Controlla se l'ultimo step è stato raggiunto
      if (_currentStep == steps.length - 1) {
        sectionCompleted = true;
      } else {
        sectionCompleted = false;
      }

      _saveUserProgress();
      print('Page changed to $_currentStep');
    });
  },
  itemBuilder: (context, index) {
    final step = steps[index];

    if (step.type == 'video') {
      final videoId = YoutubePlayer.convertUrlToId(step.content) ?? '';
      if (videoId.isEmpty) {
        return Center(
          child: Text(
            'URL video non valido',
            style: TextStyle(color: Colors.white),
          ),
        );
      }
      return VideoPlayerWidget(
        videoId: videoId,
        onShowQuestion: () {},
        onShowArticles: () {},
        onShowNotes: () {},
        isLiked: false,
        likeCount: 0,
        isSaved: false,
        onCoinsUpdate: (int newCoins) {
          // Gestisci l'aggiornamento dei coins
          print("Coins aggiornati: $newCoins");
        },
        topic: widget.section.title,
      );
    } else if (step.type == 'question') {
      // Restituisce CourseQuestionCard
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
    } else {
      // Gestisce altri tipi di step se presenti
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

                // Pulsante "Next" (opzionale, può essere rimosso se non necessario)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 15.0),
                  child: SizedBox(),
                ),
              ],
            ),
    );
  }
}