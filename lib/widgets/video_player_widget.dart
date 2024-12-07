import 'package:Just_Learn/controllers/shorts_controller.dart';
import 'package:Just_Learn/models/level.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:Just_Learn/screens/comments_screen.dart';
import 'package:Just_Learn/screens/section_selection_sheet.dart';
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
import 'package:Just_Learn/models/course.dart'; // Aggiungi questa importazione in cima al file

class VideoPlayerWidget extends StatefulWidget {
  final String videoId;
  final bool isLiked;
  final int likeCount;
  final LevelStep? questionStep;
  final Function() onShowQuestion;
  final bool isSaved;
  final VoidCallback? onVideoUnsaved;
  final Function(int) onCoinsUpdate;
  final String topic;
  final Function(String)? onTopicChanged;
  final VoidCallback onShowArticles;
  final VoidCallback onShowNotes;
  final bool isInCourse;
  final Course? course;
  final Section? currentSection;
  final Function(Course?) onStartCourse;

  const VideoPlayerWidget({
    Key? key,
    required this.videoId,
    this.isLiked = false,
    this.likeCount = 0,
    this.questionStep,
    required this.onShowQuestion,
    this.isSaved = false,
    this.onVideoUnsaved,
    required this.onCoinsUpdate,
    required this.topic,
    this.onTopicChanged,
    required this.onShowArticles,
    required this.onShowNotes,
    this.isInCourse = false,
    this.course,
    this.currentSection,
    required this.onStartCourse,
  }) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with SingleTickerProviderStateMixin {
  late YoutubePlayerController _controller;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final CommentService _commentService = CommentService();
  late AudioPlayer _audioPlayer;

  bool isLiked = false;
  bool isSaved = false;
  bool isPlaying = false;
  bool showQuestionIcon = false;
  bool _completionHandled = false;
  bool _showCoinsCompletion = false;
  bool _isDragging = false;
  bool _showArticles = false;
  bool _showNotes = false;

  int likeCount = 0;
  int commentCount = 0;
  double _progress = 0.0;
  double _dragStartX = 0.0;
  
  Duration _initialPosition = Duration.zero;
  Duration _seekOffset = Duration.zero;
  DateTime? _startWatchTime;

  List<String> allTopics = [];

  @override
  void initState() {
    super.initState();
    _initializeController();
    _initializeAnimations();
    _initializeState();
    _loadTopics();
  }

  void _initializeController() {
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
        useHybridComposition: true,
      ),
    )..addListener(_videoListener);
    _controller.load(widget.videoId);
    _controller.addListener(_updateProgress);
  }

  void _initializeAnimations() {
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
  }

  void _initializeState() {
    isLiked = widget.isLiked;
    likeCount = widget.likeCount;
    isSaved = widget.isSaved;
    _audioPlayer = AudioPlayer();
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
    _updateVideoStats('watch_time', _startWatchTime?.difference(DateTime.now()).inSeconds);
    _updateVideoStats('view');
    _cleanupControllers();
    super.dispose();
  }

  void _cleanupControllers() {
    _animationController.dispose();
    _audioPlayer.dispose();
    _controller.removeListener(_videoListener);
    _controller.removeListener(_updateProgress);
    _controller.dispose();
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
        Uri.parse('http://localhost:3000/update_video_stats'),
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

  // Aggiungi questo metodo per gestire l'inizio del corso
  void _handleStartCourse() {
    widget.onStartCourse(widget.course);
  }

  // Aggiungi questo metodo per gestire l'uscita dal corso
  void _handleQuitCourse() {
    widget.onStartCourse(null);
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
              levelId: widget.videoId ?? 'no level id found',
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
                      right: 15,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titolo
                SizedBox(
                  width: 274, // Larghezza fissa per il titolo
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
                // Row per topic e quit button
                Row(
                  children: [
GestureDetector(
  onTap: () {
    if (widget.isInCourse) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SectionSelectionSheet(
          course: widget.course!,
          currentSection: widget.currentSection,
          onSelectSection: (selectedSection) {
            widget.onStartCourse(widget.course);
            Navigator.pop(context);
          },
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => TopicSelectionSheet(
          allTopics: allTopics,
          selectedTopic: widget.topic,
          onSelectTopic: widget.onTopicChanged!,
        ),
      );
    }
  },
  child: FittedBox(
    fit: BoxFit.none,
    child: Container(
      height: 23,
      decoration: ShapeDecoration(
        color: Color(0x93333333),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: Colors.white.withOpacity(0.10000000149011612),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.school,
            color: Colors.white,
            size: 15,
          ),
          SizedBox(width: 4),
          Text(
            widget.isInCourse 
                ? "Section ${widget.currentSection?.sectionNumber ?? 1}" 
                : widget.topic,
            style: TextStyle(
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
),
                    if (widget.isInCourse)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: GestureDetector(
                          onTap: _handleQuitCourse,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: ShapeDecoration(
                              color: Colors.yellowAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Quit',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            bottom: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con profilo e nome (sempre visibile)
                Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      padding: const EdgeInsets.all(2),
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(width: 2, color: Color(0xFFFFC021)),
                          borderRadius: BorderRadius.circular(23),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(21),
                        child: Image.network(
                          "https://picsum.photos/200",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'JustLearn',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                
                // Container del corso (visibile solo quando non si è in corso)
                if (!widget.isInCourse) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.75,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0x93333333).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: const DecorationImage(
                                  image: NetworkImage('https://picsum.photos/47'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Formati gratis e cambia per sempre la tua vita.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Color(0xFFFFFF28),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _handleStartCourse,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: Text(
                                      'Start Course',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontFamily: 'Montserrat',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Icon(
                                      Icons.arrow_forward,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    },
  );
}
}