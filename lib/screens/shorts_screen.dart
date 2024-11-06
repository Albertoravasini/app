import 'package:Just_Learn/controllers/scroll_physics.dart';
import 'package:Just_Learn/models/course.dart';
import 'package:Just_Learn/screens/course_detail_screen.dart';
import 'package:Just_Learn/services/shorts_service.dart';
import 'package:Just_Learn/widgets/course_question_card.dart';
import 'package:Just_Learn/widgets/video_player_widget.dart';
import 'package:Just_Learn/controllers/shorts_controller.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:Just_Learn/models/level.dart';

class ShortsScreen extends StatefulWidget {
  final String? selectedTopic;
  final String? selectedSubtopic;
  final Function(String) onVideoTitleChange;
  final ValueChanged<int> onCoinsUpdate;  // Aggiungi questo parametro per aggiornare i coins
  final bool showSavedVideos;
  

  const ShortsScreen({
    super.key,
    this.selectedTopic,
    this.selectedSubtopic,
    required this.onVideoTitleChange,
    required this.onCoinsUpdate,  // Parametro richiesto per aggiornare i coins
    this.showSavedVideos = false,
  });

  @override
  _ShortsScreenState createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen> {
  final ShortsController _shortsController = ShortsController();
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
 

@override
  void initState() {
    super.initState();
    _loadAllShortSteps();
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

// Inside _ShortsScreenState

Future<void> _loadAllShortSteps() async {
  if (isLoadingMore) return;
  if (!mounted) return;
  setState(() {
    isLoadingMore = true;
  });

  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    // Handle unauthenticated user
    return;
  }

  try {
    final shortsService = ShortsService(baseUrl: 'http://167.99.131.91:3000');
    final shortStepsWithMetadata = await shortsService.getShortSteps(
      selectedTopic: widget.selectedTopic,
      selectedSubtopic: widget.selectedSubtopic,
      uid: user.uid,
      showSavedVideos: widget.showSavedVideos,
    );

    // Convert the `step` field from Map<String, dynamic> to LevelStep
    final convertedShortStepsWithMetadata = shortStepsWithMetadata.map((item) {
      final stepMap = item['step'] as Map<String, dynamic>;
      final levelStep = LevelStep.fromMap(stepMap);

      return {
        'step': levelStep,
        'level': item['level'] != null ? Level.fromMap(item['level']) : null,
        'showQuestion': item['showQuestion'],
        'isSaved': item['isSaved'],
        'isWatched': item['isWatched'],
      };
    }).toList();

    // Update the state and manage YouTube controllers
    if (mounted) {
      setState(() {
        allShortSteps = convertedShortStepsWithMetadata;
        currentLoadedVideos = allShortSteps.length;
        // Initialize only the first 3 controllers: current, next, and previous (if any)
        _youtubeControllers = List.generate(allShortSteps.length, (index) {
          if (index == 0 || index == 1) {
            // Initialize current and next controllers
            return YoutubePlayerController(
              initialVideoId: (allShortSteps[index]['step'] as LevelStep).content,
              flags: const YoutubePlayerFlags(
                autoPlay: false, // Non avviare automaticamente
                mute: false,
                disableDragSeek: true, // Disabilita il drag seek se non necessario
        hideControls: true, // Nascondi i controlli per migliorare la performance
        hideThumbnail: true, // Nascondi la miniatura per velocizzare il caricamento
              ),
            );
          } else {
            // Placeholder controllers, to be initialized when needed
            return YoutubePlayerController(
              initialVideoId: '',
              flags: const YoutubePlayerFlags(
                autoPlay: false,
                mute: false,
              ),
            );
          }
        });

        // Preload the next video
        if (allShortSteps.length > 1) {
          _preloadNextVideo(1);
        }

        isLoadingMore = false;
      });
    }

    // If there are videos, update the title and mark it as watched
    if (allShortSteps.isNotEmpty && mounted) {
      final firstStep = allShortSteps.first;
      final firstVideoId = (firstStep['step'] as LevelStep).content;
      final firstVideoTitle = firstStep['level'] != null
          ? (firstStep['level'] as Level).title
          : 'Untitled';
      final firstVideoTopic = firstStep['level'] != null
          ? (firstStep['level'] as Level).topic
          : 'General';

      await _shortsController.markVideoAsWatched(firstVideoId, firstVideoTitle, firstVideoTopic);
      widget.onVideoTitleChange(firstVideoTitle); // Update the video title
    }
  } catch (e) {
    print('Error loading short steps: $e');
    setState(() {
      isLoadingMore = false;
    });
  }
}


@override
void _onVideoChanged(int index) {
  // Pausa il video corrente
  _pauseAllVideos();

  // Riproduci il nuovo video
  _youtubeControllers[index].play();

  // Dispose dei controller non necessari
  _disposeUnusedControllers(index);

  // Precarica il video successivo
  _preloadNextVideo(index + 1);
}

void _pauseAllVideos() {
  for (var controller in _youtubeControllers) {
    if (controller.value.isPlaying) {
      controller.pause();
    }
  }
}

void _disposeUnusedControllers(int currentIndex) {
  for (int i = 0; i < _youtubeControllers.length; i++) {
    if (i < currentIndex - 1 || i > currentIndex + 1) {
      if (_youtubeControllers[i].initialVideoId.isNotEmpty) {
        _youtubeControllers[i].dispose();
        _youtubeControllers[i] = YoutubePlayerController(
          initialVideoId: '',
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
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

  // Aggiorna lo stato di like
  await _updateLikeState(currentVideoId);
}

void _preloadNextVideo(int nextIndex) {
  if (nextIndex < allShortSteps.length) {
    final nextStep = allShortSteps[nextIndex];
    final nextVideoId = (nextStep['step'] as LevelStep).content;

    // Verifica se il controller è già stato inizializzato
    if (_youtubeControllers[nextIndex].initialVideoId.isEmpty) {
      final nextController = YoutubePlayerController(
        initialVideoId: nextVideoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false, // Non avviare automaticamente
          mute: false,
        ),
      );

      setState(() {
        _youtubeControllers[nextIndex] = nextController;
      });

      print("Video successivo precaricato con index: $nextIndex, videoId: $nextVideoId");
    }
  }
}

// Modifica _updateLikeState per aggiornare l'intero stato di allShortSteps
Future<void> _updateLikeState(String videoId) async {
  final likeStatus = await _shortsController.getLikeStatus(videoId);
  final likeCountValue = await _shortsController.getLikeCount(videoId);

  // Trova l'indice del video corrente in allShortSteps e aggiorna il suo stato
  final videoIndex = allShortSteps.indexWhere((element) => element['step'].content == videoId);
  if (videoIndex != -1) {
    setState(() {
      allShortSteps[videoIndex]['isLiked'] = likeStatus;
      allShortSteps[videoIndex]['likeCount'] = likeCountValue;
    });
  }
}


  // Metodo per impostare il listener per i like in tempo reale
  void _setupLikeListener(String videoId) {
    final videoDoc = FirebaseFirestore.instance.collection('videos').doc(videoId);

    videoDoc.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final videoData = snapshot.data() as Map<String, dynamic>;
        final likes = videoData['likes'] as int? ?? 0;

        if (mounted) { // Verifica se il widget è ancora montato
          setState(() {
            likeCount = likes;
          });
        }
      }
    });
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

  YoutubePlayerController controller = _youtubeControllers[index];
  bool isLiked = allShortSteps[index]['isLiked'] ?? false;
  int likeCount = allShortSteps[index]['likeCount'] ?? 0;
  bool isSaved = allShortSteps[index]['isSaved'] ?? false;

  final currentStep = allShortSteps[index]['step'] as LevelStep;
  final level = allShortSteps[index]['level'] as Level;
  final videoId = currentStep.content; // Estrai l'ID del video
  
  final steps = level.steps;
  final currentStepIndex = steps.indexOf(currentStep);

  LevelStep? questionStep;
  if (currentStepIndex + 1 < steps.length && steps[currentStepIndex + 1].type == 'question') {
    questionStep = steps[currentStepIndex + 1];
  }

  final step = allShortSteps[index]['step'] as LevelStep;
  final course = allShortSteps[index]['course'];


  return Stack(
    children: [
      // Il lettore video
      VideoPlayerWidget(
        videoId: videoId, // Aggiungi questo parametro
  isLiked: isLiked,
  likeCount: likeCount,
  questionStep: questionStep,
  isSaved: isSaved,
  onShowQuestion: () {
    setState(() {
      if (questionStep != null) {
        allShortSteps[index]['step'] = questionStep;
        allShortSteps[index]['showQuestion'] = true;
      }
    });
  },
  onVideoUnsaved: () {
    // Implementa se necessario
  },
  onCoinsUpdate: widget.onCoinsUpdate,
  topic: allShortSteps[index]['level'].topic,  // Aggiungi il parametro topic qui
),
      
      // Aggiungi il pulsante "Go To Course" se il video è parte di un corso
      if (course != null)
        Positioned(
          bottom: 16, // Posizionato vicino alla parte inferiore
          left: 16,   // Distanza dal bordo sinistro
          right: 16,  // Distanza dal bordo destro
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseDetailScreen(course: course, user: _currentUser!),
                ),
              );
            },
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Color(0xFF181819), // Colore accattivante
                borderRadius: BorderRadius.circular(16), // Bordi arrotondati
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2), // Leggera ombra
                    blurRadius: 8,
                    offset: Offset(0, 4), // Posizione dell'ombra
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 10), // Spazio tra icona e testo
                  Text(
                    'Go To Course',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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