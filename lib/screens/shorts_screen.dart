import 'package:Just_Learn/controllers/scroll_physics.dart';
import 'package:Just_Learn/models/course.dart';
import 'package:Just_Learn/screens/course_detail_screen.dart';
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

Future<void> _loadAllShortSteps() async {
  if (isLoadingMore) return;
  if (!mounted) return; // Verifica se il widget è ancora montato
  setState(() {
    isLoadingMore = true;
  });

  // Fetch Levels Collection
  final levelsCollection = FirebaseFirestore.instance.collection('levels');
  Query query = levelsCollection;

  if (widget.selectedTopic != null && widget.selectedTopic != 'Just Learn') {
    query = query.where('topic', isEqualTo: widget.selectedTopic);
  }

  if (widget.selectedSubtopic != null && widget.selectedSubtopic != 'tutti') {
    query = query.where('subtopic', isEqualTo: widget.selectedSubtopic);
  }

  // Fetch all levels matching the query
  final querySnapshot = await query.orderBy('subtopicOrder').orderBy('levelNumber').get();
  final levels = querySnapshot.docs.map((doc) => Level.fromFirestore(doc)).toList();

  // Fetch Courses Collection and filter by topic
  final coursesCollection = FirebaseFirestore.instance.collection('courses');
  Query coursesQuery = coursesCollection;

  if (widget.selectedTopic != null && widget.selectedTopic != 'Just Learn') {
    coursesQuery = coursesQuery.where('topic', isEqualTo: widget.selectedTopic);
  }

  final coursesSnapshot = await coursesQuery.get();
  final courses = coursesSnapshot.docs.map((doc) => Course.fromFirestore(doc)).toList();

  // Combine short steps from Levels
  List<LevelStep> shortSteps = levels
      .expand((level) => level.steps.where((step) => step.type == 'video' && step.isShort))
      .toList();

  // Combine steps from course sections
  List<LevelStep> courseShortSteps = courses
      .expand((course) => course.sections
          .expand((section) => section.steps)
          .where((step) => step.type == 'video' && step.isShort))
      .toList();

  // Combine steps from both Levels and Courses
  final combinedShortSteps = [...shortSteps, ...courseShortSteps];

  // Get the current user to check for watched and saved videos
  final user = FirebaseAuth.instance.currentUser;
  List<VideoWatched> allWatchedVideos = [];
  List<LevelStep> unWatchedSteps = [];
  List<LevelStep> watchedSteps = [];
  Set<String> savedVideoIds = {};
  List<dynamic> savedVideos = [];

  if (user != null) {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      final userModel = UserModel.fromMap(userData);

      savedVideos = userData['SavedVideos'] ?? [];
      savedVideoIds = savedVideos.map((video) => video['videoId'].toString()).toSet();

      // Load the watched videos
      if (widget.selectedTopic == 'Just Learn') {
        for (var watchedVideosByTopic in userModel.WatchedVideos.values) {
          allWatchedVideos.addAll(watchedVideosByTopic);
        }
      } else {
        allWatchedVideos = userModel.WatchedVideos[widget.selectedTopic] ?? [];
      }

      final watchedVideoIds = allWatchedVideos.map((video) => video.videoId).toSet();

      // Se è abilitata la visualizzazione dei video salvati, filtra solo i video salvati
      if (widget.showSavedVideos) {
        // Filtra i video salvati per topic
        unWatchedSteps = combinedShortSteps.where((step) => savedVideoIds.contains(step.content)).toList();
      } else {
        // Divide videos into watched and unwatched
        unWatchedSteps = combinedShortSteps.where((step) => !watchedVideoIds.contains(step.content)).toList();
        watchedSteps = combinedShortSteps.where((step) => watchedVideoIds.contains(step.content)).toList();

        // Shuffle unwatched videos so they appear first randomly
        unWatchedSteps.shuffle();

        // Optionally shuffle watched videos as well
        watchedSteps.shuffle();
      }
    }
  }

  final List<Map<String, dynamic>> shortStepsWithMetadata = [];

  // Funzione per aggiungere i metadati e associare eventuali corsi
  void addStepsWithMetadata(List<LevelStep> steps, bool isWatched) {
    for (var step in steps) {
      // Trova il livello corrispondente per questo step
      final level = levels.firstWhere(
        (l) => l.steps.contains(step),
        orElse: () => Level(
          id: null,
          levelNumber: 0,
          topic: 'Unknown Topic',
          subtopic: 'Unknown Subtopic',
          title: 'Unknown Level',
          subtopicOrder: 0,
          steps: [],
        ),
      );

      // Trova se il video è associato a un corso
      Course? associatedCourse;
      for (var course in courses) {
        for (var section in course.sections) {
          if (section.steps.contains(step)) {
            associatedCourse = course;
            break;
          }
        }
        if (associatedCourse != null) break;
      }

      shortStepsWithMetadata.add({
        'step': step,
        'level': level,
        'course': associatedCourse,  // Aggiungi il corso associato (se esiste)
        'showQuestion': false,
        'isSaved': savedVideoIds.contains(step.content),
        'isWatched': isWatched,
      });
    }
  }

  // Aggiungi prima i video non visti
  addStepsWithMetadata(unWatchedSteps, false);

  // Aggiungi i video visti
  addStepsWithMetadata(watchedSteps, true);

  // Se `showSavedVideos` è true e non ci sono video caricati, aggiungi solo i video salvati relativi al topic selezionato
  if (widget.showSavedVideos && shortStepsWithMetadata.isEmpty) {
    unWatchedSteps = combinedShortSteps.where((step) => savedVideoIds.contains(step.content)).toList();
    addStepsWithMetadata(unWatchedSteps, false);
  }

  // Aggiorna lo stato e gestisci i controller di YouTube
  if (mounted) {
    setState(() {
  allShortSteps = shortStepsWithMetadata;
  currentLoadedVideos = allShortSteps.length;
  _youtubeControllers = allShortSteps.map((shortStep) {
    final videoId = (shortStep['step'] as LevelStep).content;
    return YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true, // Il primo video si avvia automaticamente
        mute: false,
      ),
    );
  }).toList();

  // Precarica il secondo video se disponibile
  if (allShortSteps.length > 1) {
    _preloadNextVideo(1);
  }

  isLoadingMore = false;
});
  }

  // Se ci sono video, aggiorna il titolo e segnalo come visto
  if (allShortSteps.isNotEmpty && mounted) {
    final firstStep = allShortSteps.first;
    final firstVideoId = (firstStep['step'] as LevelStep).content;
    final firstVideoTitle = (firstStep['level'] != null) ? (firstStep['level'] as Level).title : 'Untitled';
    final firstVideoTopic = (firstStep['level'] != null) ? (firstStep['level'] as Level).topic : 'General';

    await _shortsController.markVideoAsWatched(firstVideoId, firstVideoTitle, firstVideoTopic);
    widget.onVideoTitleChange(firstVideoTitle); // Aggiorna il titolo del video
  }
}


  void _onVideoChanged(int index) {
  if (index >= 0 && index < allShortSteps.length) {
    // Pausa il video corrente
    final currentIndex = _pageController.page?.toInt();
    if (currentIndex != null && currentIndex >= 0 && currentIndex < _youtubeControllers.length) {
      print("Mettendo in pausa il video con index: $currentIndex");
      _youtubeControllers[currentIndex].pause();
    }

    // Riproduci il nuovo video immediatamente
    print("Riproducendo il video corrente con index: $index, videoId: ${allShortSteps[index]['step'].content}");
    _youtubeControllers[index].play();

    // Aggiorna il titolo del video corrente
    final currentStep = allShortSteps[index];
    final currentVideoTitle = (currentStep['level'] as Level).title;
    widget.onVideoTitleChange(currentVideoTitle);

    // Precarica il video successivo se disponibile
    if (index + 1 < allShortSteps.length) {
      print("Precaricando il video successivo con index: ${index + 1}");
      _preloadNextVideo(index + 1);
    }

    // Esegui le operazioni asincrone in background
    _handleAsyncOperations(index);
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

    // Inizializza solo il controller del prossimo video
    final nextController = YoutubePlayerController(
      initialVideoId: nextVideoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,  // Precarica il video ma non avviarlo automaticamente
        mute: false,     // Mantieni muto per ridurre il consumo di risorse
      ),
    );

    // Aggiungi il controller precaricato alla lista
    setState(() {
      _youtubeControllers[nextIndex] = nextController;
    });

    print("Video successivo precaricato con index: $nextIndex, videoId: $nextVideoId");
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

  final steps = level.steps;
  final currentStepIndex = steps.indexOf(currentStep);

  LevelStep? questionStep;
  if (currentStepIndex + 1 < steps.length && steps[currentStepIndex + 1].type == 'question') {
    questionStep = steps[currentStepIndex + 1];
  }

  // Controlliamo se il video è parte di un corso
  final step = allShortSteps[index]['step'] as LevelStep;
  final course = allShortSteps[index]['course'];

  return Stack(
    children: [
      // Il lettore video
      VideoPlayerWidget(
  controller: controller,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 10), // Spazio tra icona e testo
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
  onPageChanged: _onVideoChanged,
  itemCount: allShortSteps.length,
  itemBuilder: (context, index) {
    final showQuestion = allShortSteps[index]['showQuestion'] ?? false;
    

                return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) {
        hasSwiped = false;
      },
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx.abs() > details.delta.dy.abs()) {
          if (!showQuestion) {
            if (details.delta.dx > 10 && !hasSwiped) {
              if (mounted) {
                setState(() {
                });
              }
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
      onHorizontalDragEnd: (_) {
        hasSwiped = false;
      },
      child: showQuestion
          ? _buildQuestionCard(allShortSteps[index]['step'], allShortSteps[index]['level'])
          : _buildVideoPlayer(index),
    );
  },
)
    );
  }
}