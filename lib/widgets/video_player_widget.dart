import 'package:Just_Learn/controllers/shorts_controller.dart';
import 'package:Just_Learn/models/level.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:Just_Learn/screens/comments_screen.dart';
import 'package:audioplayers/audioplayers.dart'; // Importa audioplayers
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/comment_service.dart';
import 'progress_border.dart'; // Importa il ProgressBorder

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

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        forceHD: true,
        showLiveFullscreenButton: false,
        hideThumbnail: true
      ),
    )..addListener(_videoListener);

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
  }

  void _updateProgress() {
    if (_controller.value.isPlaying) {
      final duration = _controller.metadata.duration;
      final position = _controller.value.position;
      if (duration.inMilliseconds > 0) {
        setState(() {
          _progress = position.inMilliseconds / duration.inMilliseconds;

          // Considera completato il video se è oltre il 99%
          if (_progress >= 0.96) {
            _progress = 1.0;
          }
        });

        // Gestisci il completamento della progressione
        if (_progress >= 1.0 && !_completionHandled) {
          _completionHandled = true;
          _handleProgressCompletion();
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
    _animationController.dispose();
    _audioPlayer.dispose();
    _controller.removeListener(_videoListener);
    _controller.removeListener(_updateProgress);
    _controller.dispose(); // Disporre il controller locale
    super.dispose();
  }

  void _videoListener() {
    if (mounted) {
      setState(() {
        // Controlla se il video è in riproduzione o in pausa
        if (_controller.value.isPlaying && !isPlaying) {
          isPlaying = true;
          _logVideoPlayEvent();
        } else if (!_controller.value.isPlaying && isPlaying) {
          isPlaying = false;
          _logVideoPauseEvent();
        }
      });
    }
  }

  void _logVideoPlayEvent() {
    FirebaseAnalytics.instance.logEvent(
      name: 'video_play',
      parameters: {
        'video_id': widget.videoId,
        'video_title': _controller.metadata.title,
        'user_id': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
      },
    );
  }

  void _logVideoPauseEvent() {
    FirebaseAnalytics.instance.logEvent(
      name: 'video_pause',
      parameters: {
        'video_id': widget.videoId,
        'video_title': _controller.metadata.title,
        'user_id': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
      },
    );
  }

void _onQuestionIconTap() {
  _animationController.reverse().then((_) {
    _animationController.forward();
    widget.onShowQuestion();

    // Registra l'evento di clic sul tasto della domanda
    FirebaseAnalytics.instance.logEvent(
      name: 'question_icon_click',
      parameters: {
        'video_id': widget.videoId,
        'user_id': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
      },
    );
  });
}

  // Funzione per aggiornare lo stato del like
  Future<void> _toggleLike() async {
    final videoId = widget.videoId;
    final user = FirebaseAuth.instance.currentUser;

    if (videoId.isNotEmpty && user != null) {
      setState(() {
        isLiked = !isLiked;
        likeCount += isLiked ? 1 : -1;
      });

      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final likedVideos = userData['LikedVideos'] as List<dynamic>? ?? [];

        if (isLiked) {
          likedVideos.add(videoId);
        } else {
          likedVideos.remove(videoId);
        }

        await userDocRef.update({'LikedVideos': likedVideos});

        final videoDocRef = FirebaseFirestore.instance.collection('videos').doc(videoId);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final videoDoc = await transaction.get(videoDocRef);
          if (videoDoc.exists) {
            final videoData = videoDoc.data() as Map<String, dynamic>;
            final likes = videoData['likes'] as int? ?? 0;
            final newLikes = isLiked ? likes + 1 : likes - 1;
            transaction.update(videoDocRef, {'likes': newLikes});
          } else {
            // Se il documento del video non esiste, crealo con il conteggio iniziale
            transaction.set(videoDocRef, {'likes': isLiked ? 1 : 0});
          }
          FirebaseAnalytics.instance.logEvent(
            name: isLiked ? 'video_like' : 'video_unlike',
            parameters: {
              'video_id': widget.videoId,
              'user_id': FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user',
            },
          );
        });
      }
    } else {
      print("Errore: ID video è vuoto o l'utente non è loggato"); // Messaggio di debug
    }
  }

  // Funzione per aprire i commenti
  void _openComments(BuildContext context) {
    final videoId = widget.videoId;
    if (videoId.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
        builder: (context) => CommentsScreen(videoId: videoId),
      );
    } else {
      print("Errore: ID video è vuoto"); // Messaggio di debug
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

          FirebaseAnalytics.instance.logEvent(
            name: 'video_save',
            parameters: {
              'video_id': widget.videoId,
              'user_id': FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user',
            },
          );
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
        FirebaseAnalytics.instance.logEvent(
          name: 'video_unsave',
          parameters: {
            'video_id': widget.videoId,
            'user_id': FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user',
          },
        );
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
          Column(
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
                      right: 5,
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
                          // Bottone like
                          GestureDetector(
                            onTap: _toggleLike,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                return ScaleTransition(scale: animation, child: child);
                              },
                              child: isLiked
                                  ? Icon(
                                      Icons.favorite,
                                      key: ValueKey<int>(1),
                                      color: Colors.red,
                                      size: 40,
                                    )
                                  : Icon(
                                      Icons.favorite_border,
                                      key: ValueKey<int>(2),
                                      color: Colors.white70,
                                      size: 40,
                                    ),
                            ),
                          ),
                          Text(
                            likeCount.toString(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Bottone commenti
                          GestureDetector(
                            onTap: () => _openComments(context),
                            child: Column(
                              children: [
                                SvgPicture.asset(
                                  'assets/comment_icon.svg',
                                  color: Colors.white70,
                                  width: 25,
                                  height: 30,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    '$commentCount',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Bottone per salvare il video
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
                                  'assets/mingcute_bookmark-fill.svg',
                                  color:
                                      isSaved ? Colors.yellow : Colors.white70,
                                  width: 30,
                                  height: 35,
                                ),
                                const SizedBox(height: 5),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Bottone per condividere il video
                          GestureDetector(
                            onTap: () {
                              // Implementa la funzione di condivisione
                              String videoUrl =
                                  'https://www.youtube.com/watch?v=${widget.videoId}';
                              String customMessage = '''
Take a look: $videoUrl

I Found it on JustLearn: https://apps.apple.com/it/app/justlearn/id6508169503

The TikTok for education, but Better ⚡️''';

                              Share.share(customMessage);
                            },
                            child: Column(
                              children: [
                                SvgPicture.asset(
                                  'assets/icona_share.svg',
                                  color: Colors.white70,
                                  width: 30,
                                  height: 35,
                                ),
                                const SizedBox(height: 10),
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
                height: 3, // Altezza della barra di progresso
                width: double.infinity,
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
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
        ],
      );
    },
  );
}
}