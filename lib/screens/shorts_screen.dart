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
import 'package:Just_Learn/screens/section_selection_sheet.dart';

class ShortsScreen extends StatefulWidget {
  final String? selectedTopic;
  final String? selectedSubtopic;
  final Function(String) onVideoTitleChange;
  final ValueChanged<int> onCoinsUpdate;
  final bool showSavedVideos;
  final Function(String)? onTopicChanged;
  final Function(int) onPageChanged;
  final Function(int, int, bool) onSectionProgressUpdate;

  const ShortsScreen({
    super.key,
    this.selectedTopic,
    this.selectedSubtopic,
    required this.onVideoTitleChange,
    required this.onCoinsUpdate,
    this.showSavedVideos = false,
    this.onTopicChanged,
    required this.onPageChanged,
    required this.onSectionProgressUpdate,
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
  
  bool isInCourseMode = false;
  Section? currentSection;
  int currentStepIndex = 0;
  Course? currentCourse;
  
  @override
  void initState() {
    super.initState();
    // Rimuoviamo il caricamento da qui
    _pageController.addListener(_pageListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Carica i corsi solo se non sono già stati caricati
    if (allShortSteps.isEmpty && !isInCourseMode) {
      _loadCourses();
    }
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
        // Filtra i corsi una sola volta
        _courses = courses.where((course) => 
          course.sections.isNotEmpty && 
          course.sections.first.steps.any((step) => step.type == 'video')
        ).toList();

        // Crea allShortSteps solo se non siamo in modalità corso
        if (!isInCourseMode) {
          allShortSteps = _createShortSteps(_courses);
          _initializeFirstController();
        }
      });
    }
  } catch (e) {
    print('Error loading courses: $e');
  }
}

// Estrai la logica di creazione degli shortSteps in un metodo separato
List<Map<String, dynamic>> _createShortSteps(List<Course> courses) {
  return courses.map((course) {
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
}

void _initializeFirstController() {
  if (allShortSteps.isEmpty) return;
  
  final videoId = (allShortSteps[0]['step'] as LevelStep).content;
  if (_youtubeControllers.isNotEmpty) {
    _youtubeControllers[0].dispose();
  }
  
  _youtubeControllers = [
    YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        disableDragSeek: true,
        hideControls: true,
        hideThumbnail: true,
        forceHD: false,
      ),
    )
  ];
}

void _preloadNextVideo(int index, String videoId) {
  // Precarica in modo leggero solo se necessario
  if (index < _youtubeControllers.length && 
      _youtubeControllers[index].initialVideoId != videoId) {
    _youtubeControllers[index].load(videoId, startAt: 0);
  } else if (index >= _youtubeControllers.length) {
    _youtubeControllers.add(
      YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: true,
          disableDragSeek: true,
          hideControls: true,
          hideThumbnail: true,
          forceHD: false,
        ),
      )
    );
  }
}

void _onVideoChanged(int index) {
  if (!mounted) return;
  
  // Gestisci il video corrente
  if (index < _youtubeControllers.length) {
    _youtubeControllers[index].play();
  } else {
    // Crea un nuovo controller solo se necessario
    final videoId = (allShortSteps[index]['step'] as LevelStep).content;
    _youtubeControllers.add(
      YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          disableDragSeek: true,
          hideControls: true,
          hideThumbnail: true,
          forceHD: false,
        ),
      )
    );
  }

  // Ottimizza la gestione dei controller adiacenti
  _manageAdjacentControllers(index);
  
  // Registra l'evento e gestisci il progresso
  _handleVideoAnalytics(index);
}

void _manageAdjacentControllers(int currentIndex) {
  // Gestisci solo i controller necessari (corrente e adiacenti)
  for (int i = 0; i < _youtubeControllers.length; i++) {
    if (i == currentIndex) {
      // Video corrente: riproduci
      _youtubeControllers[i].play();
    } else if (i == currentIndex + 1) {
      // Prossimo video: precarica in muto
      _youtubeControllers[i].mute();
      _youtubeControllers[i].pause();
    } else if (i == currentIndex - 1) {
      // Video precedente: pausa
      _youtubeControllers[i].pause();
    } else {
      // Altri video: disponi
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

void _handleVideoAnalytics(int index) {
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

  // Gestisci il progresso del corso se necessario
  if (isInCourseMode && currentCourse != null) {
    _handleCourseProgress(index);
  }
}

Future<void> _saveProgress(String sectionTitle, int stepIndex) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      // Aggiorna currentSteps nel documento dell'utente
      await userRef.update({
        'currentSteps.$sectionTitle': stepIndex,
      });
    } catch (e) {
      print('Error saving progress: $e');
    }
  }
}

void _cleanupControllers(int currentIndex) {
  // Mantieni solo i controller necessari (corrente e adiacenti)
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
  // Pulisci tutti i controller in modo efficiente
  for (var controller in _youtubeControllers) {
    if (controller.initialVideoId.isNotEmpty) {
      controller.dispose();
    }
  }
  _pageController.dispose();
  super.dispose();
}

  void _onContinuePressed(int index) {
    if (!hasSwiped && mounted) {
      setState(() {
        hasSwiped = true;
        final currentSteps = allShortSteps[index]['level'].steps;
        final currentStepIndex = currentSteps.indexOf(allShortSteps[index]['step']);

        if (currentStepIndex < currentSteps.length - 1) {
          final nextStep = currentSteps[currentStepIndex + 1];
          allShortSteps[index]['step'] = nextStep;
          allShortSteps[index]['showQuestion'] = nextStep.type == 'question';
          if (nextStep.type == 'question') selectedChoice = null;
        }
      });
    }
  }

  void _onPreviousPressed(int index) {
    if (!hasSwiped && mounted) {
      setState(() {
        hasSwiped = true;
        final currentSteps = allShortSteps[index]['level'].steps;
        final currentStepIndex = currentSteps.indexOf(allShortSteps[index]['step']);

        if (currentStepIndex > 0) {
          final prevStep = currentSteps[currentStepIndex - 1];
          allShortSteps[index]['step'] = prevStep;
          allShortSteps[index]['showQuestion'] = prevStep.type == 'question';
          if (prevStep.type == 'question') selectedChoice = null;
        }
      });
    }
  }
  


  Widget _buildVideoPlayer(int index) {
    if (index >= _youtubeControllers.length) {
      _ensureControllerExists(index);
    }
    
    final currentStep = allShortSteps[index]['step'] as LevelStep;
    
    // Se è uno step di transizione, mostra la schermata nera personalizzata
    if (currentStep.type == 'transition') {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 24),
              Text(
                currentStep.content,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white.withOpacity(0.7),
                size: 48,
              ),
            ],
          ),
        ),
      );
    }
    
    // Altrimenti mostra il video player
    final level = allShortSteps[index]['level'] as Level;
    final course = allShortSteps[index]['course'] as Course;
    final videoId = currentStep.content;
    final videoTitle = level.title;

    return PageViewContainer(
      key: ValueKey('video_$index'),
      videoId: videoId,
      onCoinsUpdate: widget.onCoinsUpdate,
      topic: level.topic,
      questionStep: null,
      onPageChanged: widget.onPageChanged,
      videoTitle: videoTitle,
      course: course,
      onStartCourse: (course, section) => startCourse(course, selectedSection: section),
      isInCourse: isInCourseMode,
      currentSection: currentSection,
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

    // Aggiungi un Container con Center per centrare il CourseQuestionCard
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 80, right: 16, left: 16),
        child: CourseQuestionCard(
          step: step,
          topic: level.topic,
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
        ),
      ),
    );
  }

  Future<void> _markSectionAsCompleted(String sectionTitle) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final userDoc = await userRef.get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final completedSections = List<String>.from(userData['completedSections'] ?? []);
          
          if (!completedSections.contains(sectionTitle)) {
            completedSections.add(sectionTitle);
            await userRef.update({
              'completedSections': completedSections,
            });
          }
        }
      } catch (e) {
        print('Error marking section as completed: $e');
      }
    }
  }

  // Aggiungiamo un metodo dedicato per gestire i cambiamenti di sezione
  void _updateCurrentSection(Section newSection, {bool forceUpdate = false}) {
    if (forceUpdate || currentSection?.title != newSection.title) {
      setState(() {
        currentSection = newSection;
      });
    }
  }

  // Ottimizziamo startCourse
  Future<void> startCourse(Course? course, {Section? selectedSection}) async {
    if (!mounted) return;

    if (course == null) {
      setState(() {
        isInCourseMode = false;
        currentCourse = null;
        currentSection = null;
        currentStepIndex = 0;
      });
      
      widget.onSectionProgressUpdate(0, 0, false);
      await _loadCourses();
      return;
    }

    try {
      setState(() {
        isInCourseMode = true;
        currentCourse = course;
        allShortSteps = _createCourseSteps(course);
      });

      // Gestisci la sezione iniziale
      if (selectedSection != null) {
        _updateCurrentSection(selectedSection, forceUpdate: true);
        final startIndex = _calculateSectionStartIndex(course, selectedSection);
        _pageController.jumpToPage(startIndex);
      } else {
        final lastProgressIndex = await _loadLastProgress(course);
        _pageController.jumpToPage(lastProgressIndex);
      }

      _initializeControllers();
    } catch (e) {
      print('Error starting course: $e');
      // Qui potresti aggiungere una gestione degli errori più sofisticata
    }
  }

  // Nuovo metodo per creare gli step del corso
  List<Map<String, dynamic>> _createCourseSteps(Course course) {
    List<Map<String, dynamic>> steps = [];
    
    for (var section in course.sections) {
      for (var step in section.steps) {
        steps.add({
          'step': step,
          'level': Level(
            id: course.id,
            levelNumber: course.sections.indexOf(section) + 1,
            topic: course.topic,
            subtopic: course.subtopic,
            title: course.title,
            steps: section.steps,
            subtopicOrder: 1,
          ),
          'course': course,
          'section': section, // Aggiungiamo la sezione per riferimento diretto
          'showQuestion': step.type == 'question',
          'isLiked': false,
          'likeCount': 0,
          'isSaved': false,
        });
      }
    }
    return steps;
  }

  // Nuovo metodo per calcolare l'indice di inizio sezione
  int _calculateSectionStartIndex(Course course, Section targetSection) {
    int startIndex = 0;
    for (var section in course.sections) {
      if (section.title == targetSection.title) break;
      startIndex += section.steps.length;
    }
    return startIndex;
  }

  // Ottimizziamo loadLastProgress
  Future<int> _loadLastProgress(Course course) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _updateCurrentSection(course.sections.first, forceUpdate: true);
        return 0;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        _updateCurrentSection(course.sections.first, forceUpdate: true);
        return 0;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final currentSteps = userData['currentSteps'] as Map<String, dynamic>? ?? {};
      
      // Trova l'ultima sezione con progresso
      for (var section in course.sections.reversed) {
        final stepIndex = currentSteps[section.title] as int? ?? -1;
        if (stepIndex >= 0) {
          int globalIndex = _calculateSectionStartIndex(course, section);
          _updateCurrentSection(section, forceUpdate: true);
          return globalIndex + stepIndex;
        }
      }

      // Fallback alla prima sezione
      _updateCurrentSection(course.sections.first, forceUpdate: true);
      return 0;
    } catch (e) {
      print('Error loading progress: $e');
      _updateCurrentSection(course.sections.first, forceUpdate: true);
      return 0;
    }
  }

  // Ottimizziamo handleCourseProgress
  void _handleCourseProgress(int index) {
    if (!mounted || currentCourse == null) return;

    try {
      final currentStep = allShortSteps[index];
      final section = currentStep['section'] as Section; // Usiamo il riferimento diretto
      
      _updateCurrentSection(section);
      
      final stepIndex = section.steps.indexOf(currentStep['step']);
      widget.onSectionProgressUpdate(stepIndex, section.steps.length, true);

      // Gestione asincrona del progresso
      Future.wait([
        _saveProgress(section.title, stepIndex),
        if (stepIndex == section.steps.length - 1) 
          _markSectionAsCompleted(section.title),
      ]).catchError((e) => print('Error updating progress: $e'));
    } catch (e) {
      print('Error handling course progress: $e');
    }
  }

  void exitCourseMode() {
    setState(() {
      isInCourseMode = false;
      currentSection = null;
      currentStepIndex = 0;
      currentCourse = null;
    });
    _loadCourses(); // Ricarica i primi video di ogni corso
  }

  void _initializeControllers() {
    // Disponi i controller esistenti
    for (var controller in _youtubeControllers) {
      if (controller.initialVideoId.isNotEmpty) {
        controller.dispose();
      }
    }

    // Inizializza i nuovi controller
    _youtubeControllers = allShortSteps.map((step) {
      final videoId = (step['step'] as LevelStep).content;
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
  }

  void _handleQuitCourse() {
    if (mounted) {
      setState(() {
        isInCourseMode = false;
        currentCourse = null;
        widget.onSectionProgressUpdate(0, 0, false);
      });
      _loadCourses(); // Ricarica i video normali
      startCourse(null); // Chiama startCourse con null per resettare
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: allShortSteps.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const PageScrollPhysics(),
              itemCount: allShortSteps.length,
              onPageChanged: (index) {
                _onVideoChanged(index);
              },
              itemBuilder: (context, index) {
                _preloadAdjacentPages(index);
                
                final showQuestion = allShortSteps[index]['showQuestion'] ?? false;
                return Container(
                  key: ValueKey('page_$index'),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragStart: (_) => hasSwiped = false,
                    onHorizontalDragUpdate: (details) {
                      if (details.delta.dx.abs() > details.delta.dy.abs()) {
                        if (!showQuestion) {
                          if (details.delta.dx > 10 && !hasSwiped) {
                            setState(() {}); 
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
                  ),
                );
              },
            ),
    );
  }

  void _preloadAdjacentPages(int currentIndex) {
    // Pre-carica il video successivo
    if (currentIndex < allShortSteps.length - 1) {
      final nextStep = allShortSteps[currentIndex + 1]['step'] as LevelStep;
      if (nextStep.type == 'video') {
        _ensureControllerExists(currentIndex + 1);
      }
    }
    
    // Pre-carica il video precedente
    if (currentIndex > 0) {
      final prevStep = allShortSteps[currentIndex - 1]['step'] as LevelStep;
      if (prevStep.type == 'video') {
        _ensureControllerExists(currentIndex - 1);
      }
    }
  }

  void _ensureControllerExists(int index) {
    if (index >= _youtubeControllers.length) {
      final videoId = (allShortSteps[index]['step'] as LevelStep).content;
      _youtubeControllers.add(
        YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: true,
            disableDragSeek: true,
            hideControls: true,
            hideThumbnail: true,
            forceHD: false,
          ),
        ),
      );
    }
  }
}