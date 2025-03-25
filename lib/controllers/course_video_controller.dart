import 'package:Just_Learn/controllers/video_player_manager.dart';
import 'package:Just_Learn/models/course.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:Just_Learn/screens/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Just_Learn/services/firebase_service.dart';
import 'package:better_player/better_player.dart';

class CourseVideoController {
  final VideoPlayerManager videoManager;
  final Course? course;
  final Function(Course?, Section?, {int? initialStepIndex}) onStartCourse;
  final Function(bool) onUnlockOptionsChanged;
  final Function(int) onCoinsUpdate;
  final FirebaseService _firebaseService = FirebaseService();
  late BetterPlayerController _controller;
  String? _currentVideoUrl;
  int? _currentSectionIndex;
  bool _isDisposed = false;
  final Map<String, BetterPlayerController> _preloadedControllers = {};
  static const int _preloadDistance = 1;

  CourseVideoController({
    required this.videoManager,
    this.course,
    required this.onStartCourse,
    required this.onUnlockOptionsChanged,
    required this.onCoinsUpdate,
  });

  Future<void> handleStartCourse(BuildContext context) async {
    if (course == null) return;
    
    try {
      final hasSubscription = await _firebaseService.hasSubscription(course!.authorId);
      final hasCourseAccess = await _firebaseService.hasCourseAccess(course!.id);
      
      if (hasSubscription || hasCourseAccess) {
        videoManager.pause();
        onStartCourse(course, null);
      } else {
        onUnlockOptionsChanged(true);
      }
    } catch (e) {
      // Gestione errori
    }
  }

  Future<void> handleUnlockCourse(BuildContext context) async {
    if (course == null) return;
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) throw Exception('User document not found');

        final userData = UserModel.fromMap(doc.data()!);
        if (userData.coins < course!.cost) {
          throw InsufficientCoinsException();
        }

        final updatedCoins = userData.coins - course!.cost;
        transaction.update(docRef, {
          'coins': updatedCoins,
          'unlockedCourses': FieldValue.arrayUnion([course!.id])
        });

        // Aggiorna il contatore delle monete nell'UI
        onCoinsUpdate(updatedCoins);
      });

      videoManager.pause();
      onStartCourse(course, null);
      onUnlockOptionsChanged(false);
      
    } on InsufficientCoinsException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You dont have enough coins'))
      );
    } catch (e) {
      print('Error unlocking course: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred'))
      );
    }
  }

  bool get showUnlockOptions => onUnlockOptionsChanged(true);

  void handleQuitCourse() {
    onStartCourse(null, null);
  }

  Future<void> navigateToAuthorProfile(BuildContext context) async {
    videoManager.pause();
    
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(course?.authorId)
        .get();
    
    if (!userDoc.exists || !context.mounted) return;

    final author = UserModel.fromMap(userDoc.data()!);
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(currentUser: author),
      ),
    );
  }

  Future<bool> hasSubscription(String authorId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final userData = UserModel.fromMap(doc.data()!);
        return userData.subscriptions.contains(authorId);
      }
    }
    return false;
  }

  Future<void> preloadAdjacentVideos(Section section, int currentStepIndex) async {
    // Preload previous video
    if (currentStepIndex > 0) {
      final prevStep = section.steps[currentStepIndex - 1];
      if (prevStep.type == 'video' && prevStep.videoUrl != null) {
        await _preloadVideo(prevStep.videoUrl!, 'prev');
      }
    }

    // Preload next video
    if (currentStepIndex < section.steps.length - 1) {
      final nextStep = section.steps[currentStepIndex + 1];
      if (nextStep.type == 'video' && nextStep.videoUrl != null) {
        await _preloadVideo(nextStep.videoUrl!, 'next');
      }
    }
  }

  Future<void> _preloadVideo(String videoUrl, String position) async {
    if (_preloadedControllers.containsKey(position)) {
      return; // Video already preloaded
    }

    try {
      final controller = BetterPlayerController(
        BetterPlayerConfiguration(
          autoPlay: false,
          fit: BoxFit.cover,
          controlsConfiguration: const BetterPlayerControlsConfiguration(
            enablePlayPause: false,
            enableProgressBar: false,
            enableFullscreen: false,
            enableSkips: false,
            enableOverflowMenu: false,
            enableQualities: false,
            enablePip: false,
            enableRetry: false,
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
      _preloadedControllers[position] = controller;

      // Start buffering but don't play
      controller.setVolume(0);
      controller.play();
      controller.pause();
    } catch (e) {
      print('Error preloading video: $e');
    }
  }

  void _cleanupPreloadedControllers() {
    for (var controller in _preloadedControllers.values) {
      controller.dispose();
    }
    _preloadedControllers.clear();
  }

  Future<void> _initializeVideoPlayer() async {
    if (_currentVideoUrl == null) return;

    try {
      final betterPlayerDataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        _currentVideoUrl!,
        cacheConfiguration: const BetterPlayerCacheConfiguration(
          useCache: true,
          maxCacheSize: 100 * 1024 * 1024,
          maxCacheFileSize: 20 * 1024 * 1024,
          preCacheSize: 10 * 1024 * 1024,
        ),
      );

      if (!_isDisposed) {
        _controller = BetterPlayerController(
          BetterPlayerConfiguration(
            autoPlay: true,
            fit: BoxFit.cover,
            controlsConfiguration: const BetterPlayerControlsConfiguration(
              enablePlayPause: false,
              enableProgressBar: false,
              enableFullscreen: false,
              enableSkips: false,
              enableOverflowMenu: false,
              enableQualities: false,
              enablePip: false,
              enableRetry: false,
            ),
          ),
        );

        await _controller.setupDataSource(betterPlayerDataSource);
        videoManager.setCurrentController(_controller);

        // Preload adjacent videos if we have a current section
        if (course != null && _currentSectionIndex != null) {
          final section = course!.sections[_currentSectionIndex!];
          final currentStepIndex = section.steps.indexWhere(
            (step) => step.videoUrl == _currentVideoUrl
          );
          if (currentStepIndex != -1) {
            await preloadAdjacentVideos(section, currentStepIndex);
          }
        }
      }
    } catch (e) {
      print('ERROR: CourseVideoController - Error initializing video player: $e');
    }
  }

  void dispose() {
    _isDisposed = true;
    _cleanupPreloadedControllers();
    if (_controller != null) {
      _controller.dispose();
    }
  }

  List<String> _getAllVideoUrls() {
    if (course == null) return [];
    
    return course!.sections.expand((section) => 
      section.steps.where((step) => step.type == 'video')
        .map((step) => step.videoUrl)
        .where((url) => url != null)
        .cast<String>()
    ).toList();
  }
} 