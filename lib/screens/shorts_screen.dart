import 'package:Just_Learn/widgets/shorts_question_card.dart';
import 'package:Just_Learn/widgets/video_player_widget.dart';
import 'package:Just_Learn/controllers/shorts_controller.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:Just_Learn/models/level.dart';
import 'package:Just_Learn/screens/share_video_screen.dart'; // Importa la schermata di condivisione

class ShortsScreen extends StatefulWidget {
  final String? selectedTopic;
  final String? selectedSubtopic;
  final Function(String) onVideoTitleChange;
  final bool showSavedVideos;

  const ShortsScreen({
    super.key,
    this.selectedTopic,
    this.selectedSubtopic,
    required this.onVideoTitleChange,
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
  bool showShareScreen = false;
  bool isLoadingMore = false; // Variabile per tenere traccia del caricamento di più video
  int currentLoadedVideos = 0; // Numero di video attualmente caricati
// Aggiungi qui la variabile savedVideos
  List<dynamic> savedVideos = []; // Lista per memorizzare i video salvati dall'utente
  // Aggiunte variabili per tracciare lo stato di like e il conteggio
  bool isLiked = false; // Per tenere traccia dello stato di like corrente
  int likeCount = 0; // Per tenere traccia del conteggio dei like

  @override
  void initState() {
    super.initState();
    _loadAllShortSteps();
  }

 

  Future<void> _loadAllShortSteps() async {
  if (isLoadingMore) return;
  if (!mounted) return; // Verifica se il widget è ancora montato
  setState(() {
    isLoadingMore = true;
  });

  final levelsCollection = FirebaseFirestore.instance.collection('levels');
  Query query = levelsCollection;

  if (widget.selectedTopic != null && widget.selectedTopic != 'Just Learn') {
    query = query.where('topic', isEqualTo: widget.selectedTopic);
  }

  if (widget.selectedSubtopic != null && widget.selectedSubtopic != 'tutti') {
    query = query.where('subtopic', isEqualTo: widget.selectedSubtopic);
  }

  final querySnapshot = await query.orderBy('subtopicOrder').orderBy('levelNumber').get();
  final levels = querySnapshot.docs.map((doc) => Level.fromFirestore(doc)).toList();

  List<LevelStep> shortSteps = levels
      .expand((level) => level.steps.where((step) => step.type == 'video' && step.isShort))
      .toList();

  final user = FirebaseAuth.instance.currentUser;
  List<VideoWatched> allWatchedVideos = [];
  List<LevelStep> unWatchedSteps = [];
  List<LevelStep> watchedSteps = [];
  Set<String> savedVideoIds = {};

  if (user != null) {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      final userModel = UserModel.fromMap(userData);

      savedVideos = userData['SavedVideos'] ?? [];

      // Ottieni gli ID dei video salvati
      savedVideoIds = savedVideos.map((video) => video['videoId'].toString()).toSet();

      // Se showSavedVideos è true, carica solo i video salvati
      if (widget.showSavedVideos) {
        shortSteps = shortSteps.where((step) => savedVideoIds.contains(step.content)).toList();
      } else {
        // Divide i video tra visti e non visti
        if (widget.selectedTopic == 'Just Learn') {
          for (var watchedVideosByTopic in userModel.WatchedVideos.values) {
            allWatchedVideos.addAll(watchedVideosByTopic);
          }
        } else {
          allWatchedVideos = userModel.WatchedVideos[widget.selectedTopic] ?? [];
        }

        final watchedVideoIds = allWatchedVideos.map((video) => video.videoId).toSet();

        unWatchedSteps = shortSteps.where((step) => !watchedVideoIds.contains(step.content)).toList();
        watchedSteps = shortSteps.where((step) => watchedVideoIds.contains(step.content)).toList();

        // Mescola casualmente i video già visti
        watchedSteps.shuffle();
      }
    }
  }

  final List<Map<String, dynamic>> shortStepsWithLevel = [];

  // Aggiungi prima i video non visti
  shortStepsWithLevel.addAll(unWatchedSteps.map((step) {
    final level = levels.firstWhere((l) => l.steps.contains(step));
    return {
      'step': step,
      'level': level,
      'showQuestion': false,
    };
  }).toList());

  // Aggiungi i video visti in ordine casuale
  shortStepsWithLevel.addAll(watchedSteps.map((step) {
    final level = levels.firstWhere((l) => l.steps.contains(step));
    return {
      'step': step,
      'level': level,
      'showQuestion': false,
    };
  }).toList());

  // Se showSavedVideos è true, aggiungi i video salvati alla fine della lista
  if (widget.showSavedVideos && shortStepsWithLevel.isEmpty) {
    shortStepsWithLevel.addAll(shortSteps.map((step) {
      final level = levels.firstWhere((l) => l.steps.contains(step));
      return {
        'step': step,
        'level': level,
        'showQuestion': false,
      };
    }).toList());
  }

  if (mounted) {
    setState(() {
      allShortSteps = shortStepsWithLevel;
      currentLoadedVideos = allShortSteps.length;
      _youtubeControllers = allShortSteps.map((shortStep) {
        final videoId = (shortStep['step'] as LevelStep).content;
        return YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
          ),
        );
      }).toList();
      isLoadingMore = false;
    });
  }

  if (allShortSteps.isNotEmpty && mounted) {
    final firstStep = allShortSteps.first;
    final firstVideoId = (firstStep['step'] as LevelStep).content;
    final firstVideoTitle = (firstStep['level'] as Level).title;
    final firstVideoTopic = (firstStep['level'] as Level).topic;

    await _shortsController.markVideoAsWatched(firstVideoId, firstVideoTitle, firstVideoTopic);
    widget.onVideoTitleChange(firstVideoTitle);
  }
}

  void _onVideoChanged(int index) async {
  if (index >= 0 && index < allShortSteps.length) {
    final currentStep = allShortSteps[index];
    final currentVideoId = currentStep['step'].content;
    final currentVideoTitle = currentStep['level'].title;
    final currentVideoTopic = currentStep['level'].topic;

    // Segna il video come visto
    await _shortsController.markVideoAsWatched(currentVideoId, currentVideoTitle, currentVideoTopic);

    // Aggiorna lo stato di like e passa i dati aggiornati al VideoPlayerWidget
    await _updateLikeState(currentVideoId);

    // Aggiorna il titolo del video corrente
    if (mounted) {
      setState(() {
        selectedChoice = null;
        widget.onVideoTitleChange(currentVideoTitle);
      });
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
      controller.dispose();
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

    return VideoPlayerWidget(
      controller: controller,
      isLiked: isLiked, // Passa lo stato iniziale dei like
      likeCount: likeCount, // Passa il conteggio iniziale dei like
    );
  }

  Widget _buildQuestionCard(LevelStep step) {
    if (step.choices == null || step.choices!.isEmpty) {
      return const Center(
        child: Text(
          'Errore: Domanda non disponibile.',
          style: TextStyle(color: Colors.red, fontSize: 24),
        ),
      );
    }

    return ShortsQuestionCard(
      step: step,
      onAnswered: (bool isCorrect) {
        if (isCorrect) {
          _onContinuePressed(_pageController.page!.toInt());
        } else {
          // Gestisci la risposta errata
        }
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
              onPageChanged: _onVideoChanged,
              itemCount: allShortSteps.length,
              itemBuilder: (context, index) {
                final showQuestion = allShortSteps[index]['showQuestion'] ?? false;

                // Mostra la schermata di condivisione se l'utente ha effettuato uno swipe verso destra
                if (showShareScreen) {
                  return GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      // Rileva lo swipe da destra verso sinistra per tornare indietro
                      if (details.delta.dx < -10 && !hasSwiped) {
                        setState(() {
                          showShareScreen = false; // Nascondi la schermata di condivisione
                        });
                        hasSwiped = true;
                      }
                    },
                    onHorizontalDragEnd: (_) {
                      hasSwiped = false;
                    },
                    child: ShareVideoScreen(
                      videoLink: 'https://www.youtube.com/watch?v=${allShortSteps[index]['step'].content}',
                      onClose: () {
                        // Nascondi la schermata di condivisione quando viene chiusa
                        if (mounted) { // Verifica se il widget è ancora montato
                          setState(() {
                            showShareScreen = false;
                          });
                        }
                      },
                    ),
                  );
                }

                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: (_) {
                    hasSwiped = false;
                  },
                  onHorizontalDragUpdate: (details) {
                    // Gestisci lo swipe orizzontale
                    if (details.delta.dx.abs() > details.delta.dy.abs()) {
                      if (!showQuestion) {
                        // Swipe verso destra per mostrare la schermata di condivisione
                        if (details.delta.dx > 10 && !hasSwiped) {
                          if (mounted) { // Verifica se il widget è ancora montato
                            setState(() {
                              showShareScreen = true;
                            });
                          }
                          hasSwiped = true;
                        }
                        // Swipe verso sinistra per passare al prossimo contenuto
                        else if (details.delta.dx < -10 && !hasSwiped) {
                          _onContinuePressed(index);
                          hasSwiped = true;
                        }
                      } else {
                        // Gestisci lo swipe durante la visualizzazione della domanda
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
                      ? _buildQuestionCard(allShortSteps[index]['step'])
                      : _buildVideoPlayer(index),
                );
              },
            ),
    );
  }
}