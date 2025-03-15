import 'package:video_player/video_player.dart';
import 'dart:collection';

class VideoPlayerManager {
  static final VideoPlayerManager _instance = VideoPlayerManager._internal();
  factory VideoPlayerManager() => _instance;
  VideoPlayerManager._internal();

  VideoPlayerController? _currentController;
  final Queue<VideoPlayerController> _controllerCache = Queue();
  static const int _maxCacheSize = 2; // Cache solo 2 controller alla volta
  
  void setCurrentController(VideoPlayerController controller) {
    if (_currentController == controller) return;
    
    // Gestione cache
    if (_controllerCache.length >= _maxCacheSize) {
      final oldController = _controllerCache.removeFirst();
      _disposeControllerSafely(oldController);
    }
    
    // Aggiungi il controller corrente alla cache prima di sostituirlo
    if (_currentController != null) {
      _controllerCache.add(_currentController!);
    }
    
    _currentController = controller;
  }

  Future<void> pauseCurrentVideo() async {
    try {
      if (_currentController?.value.isPlaying ?? false) {
        await _currentController?.pause();
      }
    } catch (e) {
      print('ERROR: VideoPlayerManager - Errore durante la pausa: $e');
    }
  }

  Future<void> preloadVideo(String url) async {
    try {
      // Non precaricare se abbiamo già troppi controller in cache
      if (_controllerCache.length >= _maxCacheSize) return;
      
      final controller = VideoPlayerController.network(
        url,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );
      
      await controller.initialize();
      _controllerCache.add(controller);
      
    } catch (e) {
      print('ERROR: VideoPlayerManager - Errore durante il precaricamento: $e');
    }
  }

  Future<void> _disposeControllerSafely(VideoPlayerController controller) async {
    try {
      if (controller.value.isPlaying) {
        await controller.pause();
      }
      await controller.dispose();
    } catch (e) {
      print('ERROR: VideoPlayerManager - Errore durante la pulizia del controller: $e');
    }
  }

  Future<void> dispose() async {
    await pauseCurrentVideo();
    
    // Pulisci la cache
    while (_controllerCache.isNotEmpty) {
      final controller = _controllerCache.removeFirst();
      await _disposeControllerSafely(controller);
    }
    
    if (_currentController != null) {
      await _disposeControllerSafely(_currentController!);
      _currentController = null;
    }
  }
}