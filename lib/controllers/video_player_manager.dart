import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'dart:collection';

class VideoPlayerManager {
  static final VideoPlayerManager _instance = VideoPlayerManager._internal();
  factory VideoPlayerManager() => _instance;
  VideoPlayerManager._internal();

  BetterPlayerController? _currentController;
  final _disposedControllers = <BetterPlayerController>{};

  BetterPlayerController? get currentController => _currentController;

  void setCurrentController(BetterPlayerController controller) {
    // Dispose previous controller if exists
    if (_currentController != null && !_disposedControllers.contains(_currentController)) {
      _currentController!.dispose();
      _disposedControllers.add(_currentController!);
    }
    _currentController = controller;
  }

  void pause() {
    _currentController?.pause();
  }

  void dispose() {
    if (_currentController != null && !_disposedControllers.contains(_currentController)) {
      _currentController!.dispose();
      _disposedControllers.add(_currentController!);
      _currentController = null;
    }
  }

  void cleanup() {
    dispose();
    _disposedControllers.clear();
  }
}