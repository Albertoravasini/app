import 'package:Just_Learn/widgets/progress_bar.dart';
import 'package:Just_Learn/controllers/shorts_controller.dart';
import 'package:Just_Learn/models/level.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:Just_Learn/screens/comments_screen.dart';
import 'package:Just_Learn/screens/section_selection_sheet.dart';
import 'package:Just_Learn/screens/topic_selection_sheet.dart';
import 'package:audioplayers/audioplayers.dart';
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
import 'package:Just_Learn/models/course.dart';
import '../screens/profile_screen.dart';
import '../controllers/follow_controller.dart';
import '../controllers/video_player_manager.dart';
import '../controllers/course_video_controller.dart';
import '../widgets/course_video/course_info_overlay.dart';
import 'package:better_player/better_player.dart';
import 'package:Just_Learn/utils/platform_helper.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final Course? course;
  final bool isInCourse;
  final Function(Course?, Section?, {int? initialStepIndex}) onStartCourse;
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
  late BetterPlayerController _controller;
  late AudioPlayer _audioPlayer;
  bool _showUnlockOptions = false;
  final VideoPlayerManager _videoManager = VideoPlayerManager();
  final Map<String, BetterPlayerController> _adjacentControllers = {};
  static const int _preloadDistance = 1; // Precarica 1 video prima e dopo

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl.isEmpty) {
      print('URL video non valido: ${widget.videoUrl}');
      return;
    }
    
    _audioPlayer = AudioPlayer();
    
    // Initialize controller with minimal configuration
    _controller = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: widget.autoPlay,
        fit: BoxFit.cover,
        aspectRatio: 9/16,
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          enablePlayPause: false,
          enableProgressBar: false,
          enableFullscreen: false,
          enableSkips: false,
          enableOverflowMenu: false,
          enableQualities: false,
          enablePip: false,
          enableRetry: false,
          controlsHideTime: Duration(seconds: 0),
          showControlsOnInitialize: false,
        ),
      ),
    );

    // Start loading immediately
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      final betterPlayerDataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        widget.videoUrl,
        cacheConfiguration: const BetterPlayerCacheConfiguration(
          useCache: true,
          maxCacheSize: 100 * 1024 * 1024, // 100MB
          maxCacheFileSize: 20 * 1024 * 1024, // 20MB
          preCacheSize: 10 * 1024 * 1024, // 10MB
        ),
      );

      await _controller.setupDataSource(betterPlayerDataSource);
      _videoManager.setCurrentController(_controller);
      
      if (mounted) {
        setState(() {});
        widget.onReady?.call(true);
        
        // Preload adjacent videos
        _preloadAdjacentVideos();
      }
    } catch (error) {
      print('Errore inizializzazione video: $error');
      widget.onReady?.call(false);
    }
  }

  Future<void> _preloadAdjacentVideos() async {
    if (widget.course == null) return;

    final currentIndex = widget.currentSection?.steps.indexWhere(
      (step) => step.videoUrl == widget.videoUrl
    ) ?? 0;

    // Preload previous video
    if (currentIndex > 0) {
      final prevStep = widget.currentSection?.steps[currentIndex - 1];
      if (prevStep?.type == 'video' && prevStep?.videoUrl != null) {
        await _initializeAdjacentController(prevStep!.videoUrl!, 'prev');
      }
    }

    // Preload next video
    if (currentIndex < (widget.currentSection?.steps.length ?? 0) - 1) {
      final nextStep = widget.currentSection?.steps[currentIndex + 1];
      if (nextStep?.type == 'video' && nextStep?.videoUrl != null) {
        await _initializeAdjacentController(nextStep!.videoUrl!, 'next');
      }
    }
  }

  Future<void> _initializeAdjacentController(String videoUrl, String position) async {
    if (_adjacentControllers.containsKey(position)) {
      return; // Controller already exists
    }

    try {
      final controller = BetterPlayerController(
        BetterPlayerConfiguration(
          autoPlay: false,
          fit: BoxFit.cover,
          aspectRatio: 9/16,
          controlsConfiguration: const BetterPlayerControlsConfiguration(
            enablePlayPause: false,
            enableProgressBar: false,
            enableFullscreen: false,
            enableSkips: false,
            enableOverflowMenu: false,
            enableQualities: false,
            enablePip: false,
            enableRetry: false,
            controlsHideTime: Duration(seconds: 0),
            showControlsOnInitialize: false,
          ),
        ),
      );

      final betterPlayerDataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        videoUrl,
        cacheConfiguration: const BetterPlayerCacheConfiguration(
          useCache: true,
          maxCacheSize: 100 * 1024 * 1024,
          maxCacheFileSize: 20 * 1024 * 1024,
          preCacheSize: 10 * 1024 * 1024,
        ),
      );

      await controller.setupDataSource(betterPlayerDataSource);
      _adjacentControllers[position] = controller;

      // Start buffering but don't play
      controller.setVolume(0);
      controller.play();
      controller.pause();
    } catch (error) {
      print('Error preloading adjacent video: $error');
    }
  }

  void _cleanupAdjacentControllers() {
    for (var controller in _adjacentControllers.values) {
      controller.dispose();
    }
    _adjacentControllers.clear();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    setState(() {
      _showUnlockOptions = true;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    // This method is now empty as the _showUnlockOptions flag is set directly
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    setState(() {
      _showUnlockOptions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: VideoPlayerWidget - videoTitle: ${widget.videoTitle}');
    
    return Stack(
      children: [
        PlatformHelper.isWeb 
        ? Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 9/16,
                child: _controller.videoPlayerController != null
                    ? BetterPlayer(controller: _controller)
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
          )
        : _controller.videoPlayerController != null
            ? Center(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: AspectRatio(
                    aspectRatio: 9/16,
                    child: BetterPlayer(controller: _controller),
                  ),
                ),
              )
            : const Center(child: CircularProgressIndicator()),

        GestureDetector(
          onTap: () {
            if (_controller.isPlaying() == true) {
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
          ),
        
        if (_showUnlockOptions)
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
                'Unlock Options',
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
      if (_controller.isPlaying() == true) {
        await _controller.pause();
        print('DEBUG: WillPop callback - Video in pausa');
      }
      return true;
    });
  }

  @override
  void dispose() {
    print('DEBUG: Disposing VideoPlayerWidget');
    Future.microtask(() async {
      try {
        if (_controller.isPlaying() == true) {
          await _controller.pause();
        }
        _controller.dispose();
        _cleanupAdjacentControllers();
      } catch (e) {
        print('Error during controller cleanup: $e');
      }
    });
    
    _audioPlayer.dispose();
    super.dispose();
  }
}