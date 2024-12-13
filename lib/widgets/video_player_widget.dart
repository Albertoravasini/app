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
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
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

class VideoPlayerWidget extends StatefulWidget {
  final String videoId;
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
  
  const VideoPlayerWidget({
    Key? key,
    required this.videoId,
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
  }) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> with SingleTickerProviderStateMixin {
  late YoutubePlayerController _controller;
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

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
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
  }

  void _videoListener() {
    if (!mounted) return;
    if (_controller.value.isPlaying) {
      final duration = _controller.metadata.duration;
      final position = _controller.value.position;
      if (duration.inMilliseconds > 0) {
        setState(() {
          _progress = position.inMilliseconds / duration.inMilliseconds;
          if (_progress >= 0.96 && !_completionHandled) {
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
        .doc(widget.videoId)
        .get();

    return watchedVideo.exists && watchedVideo.data()?['completed'] == true;
  }

  Future<void> _handleProgressCompletion() async {
    if (_completionHandled) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final watchedVideo = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('watchedVideos')
        .doc(widget.videoId)
        .get();

    if (watchedVideo.exists && watchedVideo.data()?['completed'] == true) {
      _completionHandled = true;
      return;
    }

    _completionHandled = true;

    try {
      await _audioPlayer.play(AssetSource('success_sound.mp3'));
      
      setState(() {
        _showCoinsCompletion = true;
      });
      _animationController.forward(from: 0.0);

      await _addCoinsToUser(5);

      await ShortsController().markVideoAsWatched(
        widget.videoId,
        _controller.metadata.title ?? '',
        widget.topic,
        completed: true,
      );
    } catch (e) {
      print('Error handling video completion: $e');
    }
  }

  Future<void> _addCoinsToUser(int coinsToAdd) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return;

        final userData = UserModel.fromMap(doc.data()!);
        final updatedCoins = userData.coins + coinsToAdd;
        
        transaction.update(docRef, {'coins': updatedCoins});
        widget.onCoinsUpdate(updatedCoins);
      });
    } catch (e) {
      print('Error updating user coins: $e');
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
    final duration = _controller.metadata.duration;
    
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
        YoutubePlayerBuilder(
          player: YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: false,
            aspectRatio: 9/16,
            onReady: () {
              print("Youtube Player è pronto.");
            },
          ),
          builder: (context, player) {
            return Stack(
              children: [
                SizedBox.expand(
                  child: RepaintBoundary(
                    child: ClipRect(
                      child: Transform.scale(
                        scale: 1.21,
                        alignment: Alignment.center,
                        child: player,
                      ),
                    ),
                  ),
                ),
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
                    videoTitle: _controller.metadata.title ?? 'Video senza titolo',
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F1F1F),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: _progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[600],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
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
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    try {
      if (_controller.hasListeners) {
        _controller.removeListener(_videoListener);
      }
      _controller.pause();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _controller.dispose();
        }
      });
    } catch (e) {
      print('Errore durante la dispose: $e');
    }
    super.dispose();
  }
}