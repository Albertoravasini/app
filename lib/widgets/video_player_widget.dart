import 'package:Just_Learn/controllers/shorts_controller.dart';
import 'package:Just_Learn/models/level.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:Just_Learn/screens/comments_screen.dart';
import 'package:Just_Learn/screens/topic_selection_sheet.dart';
import 'package:audioplayers/audioplayers.dart'; // Importa aud
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/comment_service.dart';
import '../screens/Articles_screen.dart';
import '../screens/notes_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class VideoPlayerWidget extends StatefulWidget {
  final String videoId; // Ora accetta solo videoId
  final bool isLiked;
  final int likeCount;
  final LevelStep? questionStep; // La domanda associata al video
  final Function() onShowQuestion; // Callback per mostrare la domanda
  final bool isSaved;
  final VoidCallback? onVideoUnsaved; // Callback per notificare quando un video viene rimosso dai salvati
  final Function(int) onCoinsUpdate; // Callback per aggiornare le monete
  final String topic; // Aggiungi questo campo
  final Function(String)? onTopicChanged; // Callback per notificare il cambio di topic
  final VoidCallback onShowArticles;
  final VoidCallback onShowNotes;

  const VideoPlayerWidget({
    Key? key,
    required this.videoId, // Aggiornato
    this.isLiked = false,
    this.likeCount = 0,
    this.questionStep,
    required this.onShowQuestion,
    this.isSaved = false,
    this.onVideoUnsaved,
    required this.onCoinsUpdate, // Richiesto il callback
    required this.topic, // Richiedi questo parametro
    this.onTopicChanged, // Richiedi questo parametro
    required this.onShowArticles,
    required this.onShowNotes,
  }) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with SingleTickerProviderStateMixin {
  late YoutubePlayerController _controller; // Controller locale
  bool isLiked = false;
  int likeCount = 0;
  int commentCount = 0;
  bool showQuestionIcon = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final CommentService _commentService = CommentService();
  late bool isSaved;
  bool isPlaying = false; // Traccia lo stato di riproduzione

  double _progress = 0.0; // Progresso del video (0.0 - 1.0)
  bool _completionHandled = false; // Evita trigger multipli
  bool _showCoinsCompletion = false; // Mostra l'animazione delle monete
  late AudioPlayer _audioPlayer; // Player per l'audio

  // Variabili per il drag
  bool _isDragging = false;
  double _dragStartX = 0.0;
  Duration _initialPosition = Duration.zero;
  Duration _seekOffset = Duration.zero;

  List<String> allTopics = [];

  bool _showArticles = false;
  bool _showNotes = false;

  DateTime? _startWatchTime;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
        forceHD: true,
        showLiveFullscreenButton: false,
        hideThumbnail: true,
        disableDragSeek: true,
        useHybridComposition: true, // Migliora le performance
      ),
    )..addListener(_videoListener);

    // Precarica il video
    _controller.load(widget.videoId);

    isLiked = widget.isLiked;
    likeCount = widget.likeCount;
    isSaved = widget.isSaved; // Inizializziamo lo stato isSaved

    // Inizializza l'AnimationController per l'icona della domanda
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    );
    if (widget.questionStep != null) {
      showQuestionIcon = true;
      _animationController.forward();
    }

    // Inizializza l'AudioPlayer
    _audioPlayer = AudioPlayer();

    // Aggiungi un listener per aggiornare il progresso
    _controller.addListener(_updateProgress);

    _loadTopics();
  }

  Future<void> _loadTopics() async {
    if (!mounted) return; // Verifica se il widget è ancora montato
    
    final topicsSnapshot = await FirebaseFirestore.instance.collection('topics').get();
    if (mounted) { // Verifica nuovamente prima di chiamare setState
      setState(() {
        allTopics = topicsSnapshot.docs.map((doc) => doc.id).toList();
      });
    }
  }

  void _updateProgress() {
    if (_controller.value.isPlaying) {
      final duration = _controller.metadata.duration;
      final position = _controller.value.position;
      if (duration.inMilliseconds > 0) {
        setState(() {
          _progress = position.inMilliseconds / duration.inMilliseconds;

          // Considera completato il video se è oltre il 96%
          if (_progress >= 0.96) {
            _progress = 1.0;
            
            // Se il video è completato e c'è una domanda disponibile
            if (!_completionHandled && widget.questionStep != null) {
              _completionHandled = true;
              widget.onShowQuestion(); // Notifica che è il momento di mostrare la domanda
            }
          }
        });

        // Gestisci il completamento della progressione
        if (_progress >= 1.0 && !_completionHandled) {
          _completionHandled = true;
          _handleProgressCompletion();
          _updateVideoStats('completion');
        }
      }
    }
  }

  Future<bool> _isVideoCompleted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final userModel = UserModel.fromMap(userData);
        final watchedVideos = userModel.WatchedVideos[widget.topic] ?? [];
        final videoWatched = watchedVideos.firstWhere(
          (video) => video.videoId == widget.videoId,
          orElse: () => VideoWatched(
            videoId: '',
            title: '',
            watchedAt: DateTime.now(),
            completed: false,
          ),
        );
        return videoWatched.completed;
      }
    }
    return false;
  }

  Future<void> _handleProgressCompletion() async {
    bool alreadyCompleted = await _isVideoCompleted();
    if (alreadyCompleted) return; // Non aggiungere monete se già completato

    _completionHandled = true;

    // 1. Riproduci il suono di successo
    await _audioPlayer.play(AssetSource('success_sound.mp3'));

    // 2. Mostra l'animazione delle monete
    setState(() {
      _showCoinsCompletion = true;
    });
    _animationController.forward(from: 0.0);

    // 3. Aggiungi 5 monete all'utente
    await _addCoinsToUser(5);

    // 4. Segna il video come completato
    final videoId = widget.videoId;
    final videoTitle = _controller.metadata.title;
    final topic = widget.topic;

    await ShortsController().markVideoAsWatched(videoId, videoTitle, topic, completed: true);
  }

  Future<void> _addCoinsToUser(int coinsToAdd) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        final userModel = UserModel.fromMap(userData);

        userModel.coins += coinsToAdd;

        await docRef.update({'coins': userModel.coins});

        // Aggiorna le monete nell'AppBar tramite il callback
        widget.onCoinsUpdate(userModel.coins);
      }
    }
  }

  @override
  void dispose() {
    // Aggiorna il tempo di visualizzazione e il conteggio visualizzazioni quando il widget viene distrutto
    if (_startWatchTime != null) {
      final watchTime = DateTime.now().difference(_startWatchTime!).inSeconds;
      _updateVideoStats('watch_time', watchTime);
      _updateVideoStats('view');
    }
    
    _animationController.dispose();
    _audioPlayer.dispose();
    _controller.removeListener(_videoListener);
    _controller.removeListener(_updateProgress);
    super.dispose();
  }

  void _videoListener() {
    if (mounted) {
      // Traccia il tempo di visualizzazione solo quando il video viene cambiato
      if (_controller.value.isPlaying) {
        if (_startWatchTime == null) {
          _startWatchTime = DateTime.now();
        }
      }
    }
  }

  Future<void> _updateVideoStats(String action, [int? value]) async {
    try {
      await http.post(
        Uri.parse('http://167.99.131.91:3000/update_video_stats'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'videoId': widget.videoId,
          'userId': FirebaseAuth.instance.currentUser?.uid,
          'action': action,
          'watchTime': value,
        }),
      );
    } catch (e) {
      print('Errore nell\'aggiornamento delle statistiche: $e');
    }
  }

  void _onButtonClick() {
    _updateVideoStats('button_click');
    // ... logica esistente ...
  }

  void _onVideoComplete() {
    _updateVideoStats('completion');
    // ... logica esistente ...
  }

  void _logVideoPlayEvent() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Posthog().capture(
        eventName: 'video_play',
        properties: {
          'video_id': widget.videoId,
          'video_title': _controller.metadata.title,
          'topic': widget.topic,
          'user_id': user.uid,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  void _logVideoPauseEvent() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Posthog().capture(
        eventName: 'video_pause', 
        properties: {
          'video_id': widget.videoId,
          'video_title': _controller.metadata.title,
          'topic': widget.topic,
          'user_id': user.uid,
          'watch_duration': _controller.value.position.inSeconds,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    }
  }

void _onQuestionIconTap() {
  _animationController.reverse().then((_) {
    _animationController.forward();
    widget.onShowQuestion();
    
    // Registra il click del bottone
    _updateVideoStats('button_click');
  });
}

  // Funzione per aprire i commenti
  void _openComments(BuildContext context) {
    final videoId = widget.videoId;
    if (videoId.isNotEmpty) {
      // Registra il click del bottone
      _updateVideoStats('button_click');
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
        builder: (context) => CommentsScreen(videoId: videoId),
      );
    }
  }

  Future<void> _saveVideo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final savedVideos = userData['SavedVideos'] as List<dynamic>? ?? [];
        final videoId = widget.videoId;

        savedVideos.add({
          'videoId': videoId,
          'title': _controller.metadata.title,
          'savedAt': DateTime.now().toIso8601String(),
        });

        await userDocRef.update({'SavedVideos': savedVideos});
        setState(() {
          isSaved = true;

        
        });
      }
    }
  }

  Future<void> _unsaveVideo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final savedVideos = userData['SavedVideos'] as List<dynamic>? ?? [];
        final videoId = widget.videoId;

        savedVideos.removeWhere((video) => video['videoId'] == videoId);

        await userDocRef.update({'SavedVideos': savedVideos});
        setState(() {
          isSaved = false;
        });
        // Notifica al genitore che il video è stato rimosso dai salvati
        widget.onVideoUnsaved?.call();
      
      }
    }
  }

  // Gestione del drag
  void _onHorizontalDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragStartX = details.localPosition.dx;
      _initialPosition = _controller.value.position;
      _seekOffset = Duration.zero;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final deltaX = details.localPosition.dx - _dragStartX;
    // Definisci quanto tempo vuoi saltare per pixel trascinato
    const double seekSecondsPerPixel = 0.05; // 0.05 secondi per pixel

    final seekDuration = Duration(
      milliseconds: (deltaX * seekSecondsPerPixel * 1000).toInt(),
    );

    // Calcola la nuova posizione
    Duration newPosition = _initialPosition + seekDuration;

    // Clamp tra 0 e la durata del video
    final duration = _controller.metadata.duration;
    if (newPosition < Duration.zero) {
      newPosition = Duration.zero;
    } else if (newPosition > duration) {
      newPosition = duration;
    }

    setState(() {
      _seekOffset = newPosition - _initialPosition;
    });

    // Aggiorna la posizione del video
    _controller.seekTo(newPosition);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _seekOffset = Duration.zero;
    });
  }

  void _showTopicSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => TopicSelectionSheet(
        allTopics: allTopics,
        selectedTopic: widget.topic,
        onSelectTopic: (selectedTopic) async {
          // Aggiorna Firebase
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'topics': [selectedTopic],
            });

            // Notifica il cambio di topic al parent
            if (widget.onTopicChanged != null) {
              widget.onTopicChanged!(selectedTopic);
              Navigator.pop(context); // Chiudi il bottom sheet
            }
          }
        },
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return YoutubePlayerBuilder(
    player: YoutubePlayer(
      controller: _controller,
      showVideoProgressIndicator: false,
      aspectRatio: 9/16,
      onReady: () {
        print("Youtube Player è pronto.");
      },
      onEnded: (metaData) {
        if (!_completionHandled) {
          _completionHandled = true;
          _handleProgressCompletion();
        }
      },
    ),
    builder: (context, player) {
      return Stack(
        children: [
          _showArticles 
          ? ArticlesWidget(
              videoTitle: _controller.metadata.title ?? 'Untitled',
            )
          : _showNotes 
          ? NotesScreen(
            
            )
          : Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    // Contenitore per il player con overflow nascosto
                    ClipRect(
                      child: Transform.scale(
                        scale: 1.21,
                        child: IgnorePointer(
                          ignoring: true,
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            child: player,
                          ),
                        ),
                      ),
                    ),
                    // Layer invisibile per tapping e dragging
                    GestureDetector(
                      onTap: () {
                        if (_controller.value.isPlaying) {
                          _controller.pause();
                        } else {
                          _controller.play();
                        }
                      },
                      onHorizontalDragStart: _onHorizontalDragStart,
                      onHorizontalDragUpdate: _onHorizontalDragUpdate,
                      onHorizontalDragEnd: _onHorizontalDragEnd,
                      child: Container(
                        color: Colors.transparent,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    // Bottoni e overlay
                    Positioned(
                      bottom: 5,
                      right: 10,
                      child: Column(
                        children: [
                          // Icona della domanda
                          if (showQuestionIcon && widget.questionStep != null)
                            GestureDetector(
                              onTap: _onQuestionIconTap,
                              child: AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _scaleAnimation.value,
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.stars_rounded,
                                        color: Colors.yellowAccent,
                                        size: 35,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 20),

                          // Preview link
                          GestureDetector(
                            onTap: widget.onShowArticles,
                            child: Column(
                              children: [
                                SvgPicture.asset(
                                  'assets/fluent_preview-link-24-filled.svg',
                                  color: Colors.white70,
                                  width: 30,
                                  height: 30,
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),

                          // Refresh con le proprietà del salvataggio
                          GestureDetector(
                            onTap: () {
                              if (isSaved) {
                                _unsaveVideo();
                              } else {
                                _saveVideo();
                              }
                            },
                            child: Column(
                              children: [
                                SvgPicture.asset(
                                  'assets/heroicons-solid_refresh.svg',
                                  color: isSaved ? Colors.yellow : Colors.white70,
                                  width: 30,
                                  height: 30,
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),

                          // Chat AI con le proprietà dei commenti
                          GestureDetector(
                            onTap: () => _openComments(context),
                            child: Column(
                              children: [
                                SvgPicture.asset(
                                  'assets/ri_chat-ai-line.svg',
                                  color: Colors.white70,
                                  width: 30,
                                  height: 30,
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),

                          // Pen
                          GestureDetector(
                            onTap: widget.onShowNotes,
                            child: Column(
                              children: [
                                Image.asset(
                                  'assets/solar_pen-bold.png',
                                  color: Colors.white70,
                                  width: 30,
                                  height: 30,
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Barra di progresso sotto il video
              Container(
                height: 4,
                width: double.infinity,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1F1F),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(3),
                          bottomRight: Radius.circular(3),
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(3),
                        bottomRight: Radius.circular(3),
                      ),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * _progress,
                        child: Container(
                          color: Colors.yellowAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Overlay per l'animazione delle monete
          if (_showCoinsCompletion)
            Positioned.fill(
              child: Center(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 1.0 - _animationController.value,
                      child: Transform.translate(
                        offset: Offset(0, -150 * _animationController.value),
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    Icons.stars_rounded,
                    size: 100,
                    color: Colors.yellowAccent,
                  ),
                ),
              ),
            ),
          // Overlay per il feedback del seeking
          if (_isDragging)
            Positioned(
              top: 20, // Posiziona in alto
              right: 20, // Posiziona a destra
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5), // Quasi trasparente
                  borderRadius: BorderRadius.circular(10), // Bordi arrotondati
                ),
                child: Text(
                  '${_seekOffset.isNegative ? '-' : '+'} ${_seekOffset.abs().inSeconds} s',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          // Aggiungi questo widget dentro lo Stack esistente, dopo il player video
          Positioned(
            left: 16,
            bottom: 20,
            child: Container(
              width: 274,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      _controller.metadata.title ?? 'Titolo non disponibile',
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.72,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showTopicSelection(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      clipBehavior: Clip.antiAlias,
                      decoration: ShapeDecoration(
                        color: const Color(0x93333333),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 15,
                            height: 15,
                            padding: const EdgeInsets.all(1.25),
                            child: const Icon(
                              Icons.school,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                          const SizedBox(width: 1),
                          Text(
                            widget.topic,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.72,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      );
    },
  );
}
}