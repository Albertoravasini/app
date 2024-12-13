import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPlayerManager {
  static final VideoPlayerManager _instance = VideoPlayerManager._internal();
  factory VideoPlayerManager() => _instance;
  VideoPlayerManager._internal();

  YoutubePlayerController? _currentController;
  final Map<String, YoutubePlayerController> _controllerCache = {};
  
  Future<YoutubePlayerController> getControllerForVideo(String videoId) async {
    if (_controllerCache.containsKey(videoId)) {
      final controller = _controllerCache[videoId]!;
      if (controller.metadata.videoId != videoId) {
         controller.load(videoId);
      }
      return controller;
    }

    if (_controllerCache.length > 2) {
      final oldestVideoId = _controllerCache.keys.first;
      await prepareControllerForDisposal(oldestVideoId);
    }

    final controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        enableCaption: false,
        controlsVisibleAtStart: false,
        hideControls: true,
        hideThumbnail: true,
        disableDragSeek: true,
        useHybridComposition: true,
      ),
    );

    _controllerCache[videoId] = controller;
    return controller;
  }

  Future<void> prepareControllerForDisposal(String videoId) async {
    if (_controllerCache.containsKey(videoId)) {
      final controller = _controllerCache[videoId]!;
      try {
         controller.pause();
        if (_currentController != controller) {
           controller.dispose();
          _controllerCache.remove(videoId);
        }
      } catch (e) {
        print('Errore durante la dispose del controller: $e');
      }
    }
  }

  void setCurrentController(YoutubePlayerController controller) {
    if (_currentController != controller) {
      pauseCurrentVideo();
      _currentController = controller;
    }
  }

  Future<void> pauseCurrentVideo() async {
    try {
       _currentController?.pause();
    } catch (e) {
      print('Errore durante la pausa del video: $e');
    }
  }

  Future<void> playCurrentVideo() async {
    try {
       _currentController?.play();
    } catch (e) {
      print('Errore durante la riproduzione del video: $e');
    }
  }

  Future<void> dispose() async {
    try {
      for (var controller in _controllerCache.values) {
         controller.pause();
         controller.dispose();
      }
      _controllerCache.clear();
      _currentController = null;
    } catch (e) {
      print('Errore durante la dispose generale: $e');
    }
  }

  bool isPlaying() {
    return _currentController?.value.isPlaying ?? false;
  }

  Duration? getCurrentPosition() {
    return _currentController?.value.position;
  }

  Duration? getTotalDuration() {
    return _currentController?.metadata.duration;
  }
} 