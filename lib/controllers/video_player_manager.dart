import 'package:video_player/video_player.dart';

class VideoPlayerManager {
  static final VideoPlayerManager _instance = VideoPlayerManager._internal();
  factory VideoPlayerManager() => _instance;
  VideoPlayerManager._internal();

  VideoPlayerController? _currentController;
  VideoPlayerController? _previousController;
  
  void setCurrentController(VideoPlayerController controller) {
    if (_currentController == controller) return;  // Evita registrazioni duplicate
    
    // Cleanup del controller precedente
    if (_previousController != null) {
      _previousController!.dispose();
      _previousController = null;
    }
    
    _previousController = _currentController;  // Salva il controller corrente prima di sostituirlo
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

  Future<void> dispose() async {
    await pauseCurrentVideo();
    _previousController?.dispose();
    _currentController?.dispose();
    _previousController = null;
    _currentController = null;
  }
}