import 'package:Just_Learn/controllers/scroll_physics.dart';
import 'package:Just_Learn/models/course.dart';
import 'package:Just_Learn/screens/course_detail_screen.dart';
import 'package:Just_Learn/services/shorts_service.dart';
import 'package:Just_Learn/widgets/course_question_card.dart';
import 'package:Just_Learn/widgets/video_player_widget.dart';
import 'package:Just_Learn/controllers/shorts_controller.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:Just_Learn/models/level.dart';
import 'package:Just_Learn/widgets/page_view_container.dart';
import '../services/course_service.dart';

class ShortsScreen extends StatefulWidget {
  final String? selectedTopic;
  final String? selectedSubtopic;
  final Function(String) onVideoTitleChange;
  final ValueChanged<int> onCoinsUpdate;
  final bool showSavedVideos;
  final Function(String)? onTopicChanged;
  final Function(int) onPageChanged;

  const ShortsScreen({
    super.key,
    this.selectedTopic,
    this.selectedSubtopic,
    required this.onVideoTitleChange,
    required this.onCoinsUpdate,
    this.showSavedVideos = false,
    this.onTopicChanged,
    required this.onPageChanged,
  });

  @override
  _ShortsScreenState createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen> {
  final ShortsController _shortsController = ShortsController();
  final CourseService _courseService = CourseService();
  List<Map<String, dynamic>> allShortSteps = [];
  final PageController _pageController = PageController();
  List<YoutubePlayerController> _youtubeControllers = [];
  String? selectedChoice;
  bool hasSwiped = false;
  bool isLoadingMore = false; // Variabile per tenere traccia del caricamento di più video
  int currentLoadedVideos = 0; // Numero di video attualmente caricati
// Aggiungi qui la variabile savedVideos
  List<dynamic> savedVideos = []; // Lista per memorizzare i video salvati dall'utente
  // Aggiunte variabili per tracciare lo stato di like e il conteggio
  bool isLiked = false; // Per tenere traccia dello stato di like corrente
  int likeCount = 0; // Per tenere traccia del conteggio dei like
 UserModel? _currentUser;
 
  List<Course> _courses = [];
  
  @override
  void initState() {
    super.initState();
    _loadCourses();
    _loadCurrentUser();
    _pageController.addListener(_pageListener);
  }

  void _pageListener() {
    final index = _pageController.page?.round() ?? 0;
    _onVideoChanged(index);
  }

 Future<void> _loadCurrentUser() async {
  final firebaseUser = FirebaseAuth.instance.currentUser;

  if (firebaseUser != null) {
    // Ottieni i dati dell'utente da Firestore utilizzando l'UID dell'utente autenticato
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).get();

    if (userDoc.exists) {
      // Mappa i dati dell'utente dal documento Firestore in un UserModel
      final userData = userDoc.data()!;
      final userModel = UserModel.fromMap(userData); // Qui usi il tuo modello personalizzato

      // Aggiorna lo stato con il modello utente caricato
      setState(() {
        _currentUser = userModel; // Assicurati che _currentUser sia di tipo UserModel
      });
    } else {
      print('Errore: Utente non trovato in Firestore.');
    }
  } else {
    print('Errore: Nessun utente autenticato.');
  }
}

Future<void> _loadCourses() async {
  try {
    final courses = await _courseService.getVisibleCourses();
    
    if (mounted) {
      setState(() {
        _courses = courses.where((course) => 
          course.sections.isNotEmpty && 
          course.sections.first.steps.any((step) => step.type == 'video')
        ).toList();

        // Crea gli shorts steps dai primi video di ogni corso
        allShortSteps = _courses.map((course) {
          final firstSection = course.sections.first;
          final firstVideoStep = firstSection.steps.firstWhere(
            (step) => step.type == 'video',
            orElse: () => throw Exception('No video found in course'),
          );

          return {
            'step': firstVideoStep,
            'level': Level(
              id: course.id,
              levelNumber: 1,
              topic: course.topic,
              subtopic: course.subtopic,
              title: course.title,
              steps: firstSection.steps,
              subtopicOrder: 1,
            ),
            'course': course,
            'showQuestion': false,
            'isLiked': false,
            'likeCount': 0,
            'isSaved': false,
          };
        }).toList();

        // Inizializza i controller YouTube per ogni video
        _youtubeControllers = allShortSteps.map((shortStep) {
          final videoId = (shortStep['step'] as LevelStep).content;
          return YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: true,
              disableDragSeek: true,
              hideControls: true,
              hideThumbnail: true,
              forceHD: false,
            ),
          );
        }).toList();

        // Precarica il primo video
        if (_youtubeControllers.isNotEmpty) {
          _youtubeControllers.first.unMute();
          _youtubeControllers.first.play();
        }
      });
    }
  } catch (e) {
    print('Error loading courses: $e');
  }
}

void _preloadNextVideo(int nextIndex) {
  if (nextIndex < allShortSteps.length && nextIndex >= 0) {
    final nextVideoId = (allShortSteps[nextIndex]['step'] as LevelStep).content;
    
    // Verifica se il controller successivo esiste e ha un video diverso
    if (_youtubeControllers[nextIndex].initialVideoId != nextVideoId) {
      // Disponi il vecchio controller se necessario
      if (_youtubeControllers[nextIndex].initialVideoId.isNotEmpty) {
        _youtubeControllers[nextIndex].dispose();
      }
      
      // Crea un nuovo controller per il prossimo video
      _youtubeControllers[nextIndex] = YoutubePlayerController(
        initialVideoId: nextVideoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: true,
          disableDragSeek: true,
          hideControls: true,
          hideThumbnail: true,
          forceHD: false,
        ),
      );
    }
    
    // Avvia il precaricamento
    _youtubeControllers[nextIndex].load(nextVideoId);
  }
}

void _onVideoChanged(int index) {
  // Gestisci il video corrente
  _youtubeControllers[index].unMute();
  _youtubeControllers[index].play();
  
  // Registra l'evento video_play su Posthog
  final videoId = (allShortSteps[index]['step'] as LevelStep).content;
  final videoTitle = (allShortSteps[index]['level'] as Level).title;
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    Posthog().capture(
      eventName: 'video_play',
      properties: {
        'video_id': videoId,
        'video_title': videoTitle,
        'topic': widget.selectedTopic ?? 'General',
        'user_id': user.uid,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
  
  // Precarica il prossimo video
  _preloadNextVideo(index + 1);
  
  // Gestisci i video precedenti e successivi
  if (index > 0) {
    _youtubeControllers[index - 1].pause();
  }
  
  // Pulisci i controller non necessari
  _cleanupControllers(index);
}

void _cleanupControllers(int currentIndex) {
  for (int i = 0; i < _youtubeControllers.length; i++) {
    if (i < currentIndex - 1 || i > currentIndex + 1) {
      if (_youtubeControllers[i].initialVideoId.isNotEmpty) {
        _youtubeControllers[i].dispose();
        _youtubeControllers[i] = YoutubePlayerController(
          initialVideoId: '',
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: true,
          ),
        );
      }
    }
  }
}

Future<void> _handleAsyncOperations(int index) async {
  final currentStep = allShortSteps[index];
  final currentVideoId = (currentStep['step'] as LevelStep).content;
  final currentVideoTitle = (currentStep['level'] as Level).title;
  final currentVideoTopic = (currentStep['level'] as Level).topic;

  // Segna il video come visto
  await _shortsController.markVideoAsWatched(currentVideoId, currentVideoTitle, currentVideoTopic);


}

@override
void dispose() {
  for (var controller in _youtubeControllers) {
    if (controller.initialVideoId.isNotEmpty) {
      controller.dispose();
    }
  }
  _pageController.dispose();
  super.dispose();
}

  void _onContinuePressed(int index) {
    if (!hasSwiped && mounted) { // Verifica se il widget è ancora montato
      setState(() {
        hasSwiped = true;
        final currentSteps = allShortSteps[index]['level'].steps;
        final currentStepIndex = currentSteps.indexOf(allShortSteps[index]['step']);

        if (currentStepIndex < currentSteps.length - 1) {
          allShortSteps[index]['step'] = currentSteps[currentStepIndex + 1];
          if (currentSteps[currentStepIndex + 1].type == 'question') {
            allShortSteps[index]['showQuestion'] = true;
            selectedChoice = null;
          } else {
            allShortSteps[index]['showQuestion'] = false;
          }
        }
      });
    }
  }

  void _onPreviousPressed(int index) {
    if (!hasSwiped && mounted) { // Verifica se il widget è ancora montato
      setState(() {
        hasSwiped = true;
        final currentSteps = allShortSteps[index]['level'].steps;
        final currentStepIndex = currentSteps.indexOf(allShortSteps[index]['step']);

        if (currentStepIndex > 0) {
          allShortSteps[index]['step'] = currentSteps[currentStepIndex - 1];
          if (currentSteps[currentStepIndex - 1].type == 'question') {
            allShortSteps[index]['showQuestion'] = true;
            selectedChoice = null;
          } else {
            allShortSteps[index]['showQuestion'] = false;
          }
        }
      });
    }
  }
  


  Widget _buildVideoPlayer(int index) {
    if (allShortSteps[index]['showQuestion'] == true) {
      return const SizedBox.shrink();
    }

    final currentStep = allShortSteps[index]['step'] as LevelStep;
    final level = allShortSteps[index]['level'] as Level;
    final videoId = currentStep.content;
    final videoTitle = level.title;
    final course = allShortSteps[index]['course'];

    return Stack(
      children: [
        PageViewContainer(
          videoId: videoId,
          onCoinsUpdate: widget.onCoinsUpdate,
          topic: level.topic,
          questionStep: null,
          onPageChanged: widget.onPageChanged,
          videoTitle: videoTitle,
        ),
        
        // Pulsante "Go To Course" se il corso esiste
        
      ],
    );
  }

  Widget _buildQuestionCard(LevelStep step, Level level) {
  if (step.choices == null || step.choices!.isEmpty) {
    return const Center(
      child: Text(
        'Errore: Domanda non disponibile.',
        style: TextStyle(color: Colors.red, fontSize: 24),
      ),
    );
  }

  return CourseQuestionCard(
    step: step,
    topic: level.topic, // Usa il `topic` del livello associato allo step
    onAnswered: (bool isCorrect) async {
      if (isCorrect) {
        _onContinuePressed(_pageController.page!.toInt());

        // Recupera i coins attuali e aggiungi 10
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
          final doc = await docRef.get();
          if (doc.exists) {
            final userData = doc.data() as Map<String, dynamic>;
            final currentCoins = userData['coins'] ?? 0;

            // Aggiorna i coins con l'incremento di 10
            widget.onCoinsUpdate(currentCoins + 0);  // Incrementa i coins di 10
          }
        }
      } else {
        // Gestisci la risposta errata
      }
    },
    onCompleteStep: () {
      // Azioni da fare quando lo step è completato
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: allShortSteps.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const TikTokScrollPhysics(parent: BouncingScrollPhysics()),
              itemCount: allShortSteps.length,
              onPageChanged: (index) {
                _onVideoChanged(index);
              },
              itemBuilder: (context, index) {
                final showQuestion = allShortSteps[index]['showQuestion'] ?? false;
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: (_) => hasSwiped = false,
                  onHorizontalDragUpdate: (details) {
                    if (details.delta.dx.abs() > details.delta.dy.abs()) {
                      if (!showQuestion) {
                        if (details.delta.dx > 10 && !hasSwiped) {
                          setState(() {}); // Aggiornamento minimo
                          hasSwiped = true;
                        }
                      } else {
                        if (details.delta.dx > 10 && !hasSwiped) {
                          _onPreviousPressed(index);
                          hasSwiped = true;
                        } else if (details.delta.dx < -10 && !hasSwiped) {
                          _onContinuePressed(index);
                          hasSwiped = true;
                        }
                      }
                    }
                  },
                  onHorizontalDragEnd: (_) => hasSwiped = false,
                  child: showQuestion
                      ? _buildQuestionCard(allShortSteps[index]['step'], allShortSteps[index]['level'])
                      : _buildVideoPlayer(index),
                );
              },
            ),
    );
  }
}