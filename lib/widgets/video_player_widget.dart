import 'package:Just_Learn/widgets/progress_bar.dart';
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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/comment_service.dart';
import '../screens/Articles_screen.dart';
import '../screens/notes_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:Just_Learn/models/course.dart'; // Aggiungi questa importazione in cima al file
import '../screens/profile_screen.dart';
import '../controllers/follow_controller.dart';
import '../controllers/video_player_manager.dart';
import '../controllers/course_video_controller.dart';
import '../widgets/course_video/course_info_overlay.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final Course? course;
  final bool isInCourse;
  final Function(Course?, Section?) onStartCourse;
  final bool autoPlay;
  final Function(bool)? onReady;
  final Function(int) onCoinsUpdate;
  final Section? currentSection;
  final String topic;
  final Function(bool) onShowArticles;
  final Function(bool) onShowNotes;
  final Function(bool) openComments;
  final String? videoTitle;
  
  const VideoPlayerWidget({
    Key? key,
    required this.videoUrl,
    this.course,
    this.isInCourse = false,
    required this.onStartCourse,
    this.autoPlay = true,
    this.onReady,
    required this.onCoinsUpdate,
    this.currentSection,
    required this.topic,
    required this.onShowArticles,
    required this.onShowNotes,
    required this.openComments,
    this.videoTitle,
  }) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _animationController;
  late AudioPlayer _audioPlayer;
  bool _completionHandled = false;
  bool _showCoinsCompletion = false;
  double _progress = 0.0;
  bool _isDragging = false;
  double _dragStartX = 0.0;
  Duration _initialPosition = Duration.zero;
  Duration _seekOffset = Duration.zero;
  bool _showUnlockOptions = false;
  final VideoPlayerManager _videoManager = VideoPlayerManager();

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl.isEmpty) {
      print('URL video non valido: ${widget.videoUrl}');
      return;
    }
    
    print('Inizializzazione video con URL: ${widget.videoUrl}');
    _audioPlayer = AudioPlayer();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.addListener(_videoListener);
          print('DEBUG: Registrazione controller nel VideoPlayerManager');
          _videoManager.setCurrentController(_controller);
          if (widget.autoPlay) {
            _controller.play();
          }
        }
      }).catchError((error) {
        print('Errore inizializzazione video: $error');
      });
  }

  void _videoListener() {
    if (!mounted) return;
    if (_controller.value.isPlaying) {
      final duration = _controller.value.duration;
      final position = _controller.value.position;
      if (duration.inMilliseconds > 0) {
        setState(() {
          _progress = position.inMilliseconds / duration.inMilliseconds;
          if (_progress >= 0.99 && !_completionHandled) {
            _handleProgressCompletion();
          }
        });
      }
    }
  }

  Future<bool> _isVideoCompleted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final watchedVideo = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('watchedVideos')
        .doc(widget.videoUrl)
        .get();

    return watchedVideo.exists && watchedVideo.data()?['completed'] == true;
  }

  Future<void> _handleProgressCompletion() async {
    if (_completionHandled) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Genera un ID sicuro usando un hash dell'URL
      final videoId = widget.videoUrl.hashCode.toString();

      // Verifica se il video è già stato completato
      final watchedVideo = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('watchedVideos')
          .doc(videoId)
          .get();

      if (watchedVideo.exists && watchedVideo.data()?['completed'] == true) {
        _completionHandled = true;
        return;
      }

      _completionHandled = true;

      // Riproduci il suono di successo
      try {
        await _audioPlayer.play(AssetSource('success_sound.mp3'));
      } catch (audioError) {
        print('Errore riproduzione audio: $audioError');
      }
      
      if (mounted) {
        setState(() {
          _showCoinsCompletion = true;
        });
        _animationController.forward(from: 0.0);
      }

      // Aggiorna i coins
      await _addCoinsToUser(5);

      // Marca il video come visto
      if (mounted) {
        await ShortsController().markVideoAsWatched(
          videoId,
          widget.videoTitle ?? '',
          widget.topic,
          completed: true,
        );
      }
    } catch (e) {
      print('Errore durante il completamento del video: $e');
      _completionHandled = true; // Previene ulteriori tentativi
    }
  }

  Future<void> _addCoinsToUser(int coinsToAdd) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    
    try {
      // Prima ottieni il documento corrente
      final doc = await docRef.get();
      if (!doc.exists) return;

      // Calcola i nuovi coins
      final currentCoins = doc.data()?['coins'] ?? 0;
      final updatedCoins = currentCoins + coinsToAdd;
      
      // Aggiorna il documento
      await docRef.update({'coins': updatedCoins});
      
      // Notifica il widget padre del nuovo valore
      if (mounted) {
        widget.onCoinsUpdate(updatedCoins);
      }

      print('Coins aggiornati: $updatedCoins'); // Debug

    } catch (e) {
      print('Errore aggiornamento coins: $e');
    }
  }

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
    const double seekSecondsPerPixel = 0.05;
    final seekDuration = Duration(
      milliseconds: (deltaX * seekSecondsPerPixel * 1000).toInt(),
    );
    Duration newPosition = _initialPosition + seekDuration;
    final duration = _controller.value.duration;
    
    if (newPosition < Duration.zero) {
      newPosition = Duration.zero;
    } else if (newPosition > duration) {
      newPosition = duration;
    }

    setState(() {
      _seekOffset = newPosition - _initialPosition;
    });
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
    return Stack(
      children: [
        _controller.value.isInitialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : Center(child: CircularProgressIndicator()),
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
        if (widget.course != null)
          CourseInfoOverlay(
            course: widget.course,
            isInCourse: widget.isInCourse,
            onShowArticles: widget.onShowArticles,
            onShowNotes: widget.onShowNotes,
            openComments: widget.openComments,
            videoTitle: widget.videoTitle ?? 'Video senza titolo',
            controller: CourseVideoController(
              videoManager: VideoPlayerManager(),
              course: widget.course,
              onStartCourse: widget.onStartCourse,
              onUnlockOptionsChanged: (show) => setState(() => _showUnlockOptions = show),
              onCoinsUpdate: widget.onCoinsUpdate,
            ),
            currentSection: widget.currentSection,
            topic: widget.topic,
            onCoinsUpdate: widget.onCoinsUpdate,
          ),
        
        // Progress bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 4,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1F1F),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: _progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Seek indicator
        if (_isDragging)
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_seekOffset.isNegative ? '-' : '+'} ${_seekOffset.abs().inSeconds} s',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    ModalRoute.of(context)?.addScopedWillPopCallback(() async {
      print('DEBUG: WillPop callback - Tentativo di pausa video');
      if (_controller.value.isPlaying) {
        await _controller.pause();
        print('DEBUG: WillPop callback - Video in pausa');
      }
      return true;
    });
  }

  @override
  void dispose() {
    print('DEBUG: Disposing VideoPlayerWidget');
    _controller.pause();
    _controller.dispose();
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}