// lib/controllers/video_controller_manager.dart

import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/material.dart';

class VideoControllerManager {
  // Singleton pattern per gestione globale
  static final VideoControllerManager _instance = VideoControllerManager._internal();
  factory VideoControllerManager() => _instance;
  VideoControllerManager._internal();

  // Cache limitata di controller attivi
  final Map<int, YoutubePlayerController> _activeControllers = {};
  
  // Configurazione
  static const int _maxActiveControllers = 3;
  static const Duration _disposalDelay = Duration(seconds: 2);

  // Stato corrente
  int _currentPlayingIndex = -1;
  bool _isDisposing = false;

  // Ottieni il controller per un indice specifico
  YoutubePlayerController? getController(int index, String videoId) {
    if (_activeControllers.containsKey(index)) {
      return _activeControllers[index];
    }

    // Gestisci i controller esistenti prima di crearne uno nuovo
    _manageControllers(index);
    
    // Crea e configura il nuovo controller
    final controller = _createController(videoId);
    _activeControllers[index] = controller;
    
    return controller;
  }

  // Crea un nuovo controller ottimizzato
  YoutubePlayerController _createController(String videoId) {
    return YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: true,
        disableDragSeek: true,
        enableCaption: false,
        hideControls: true,
        hideThumbnail: true,
        useHybridComposition: true,
      ),
    );
  }

  // Gestisce i controller attivi
  void _manageControllers(int newIndex) {
    // Determina quali indici mantenere attivi
    final Set<int> indicesToKeep = {
      newIndex - 1, // Controller precedente
      newIndex,     // Controller corrente
      newIndex + 1  // Controller successivo
    };

    // Rimuovi i controller non necessari
    _activeControllers.keys
        .where((i) => !indicesToKeep.contains(i))
        .toList()
        .forEach(_disposeController);

    // Aggiorna l'indice corrente
    if (_currentPlayingIndex != newIndex) {
      _updatePlayingState(newIndex);
    }
  }

  // Aggiorna lo stato di riproduzione
  void _updatePlayingState(int newIndex) {
    if (_currentPlayingIndex != -1 && _activeControllers.containsKey(_currentPlayingIndex)) {
      _activeControllers[_currentPlayingIndex]?.pause();
    }
    _currentPlayingIndex = newIndex;
  }

  // Dispose sicuro di un controller
  void _disposeController(int index) async {
    if (_isDisposing) return;
    _isDisposing = true;

    final controller = _activeControllers[index];
    if (controller == null) return;

    try {
      controller.pause();
      await Future.delayed(_disposalDelay);
      
      if (_activeControllers.containsKey(index)) {
        controller.dispose();
        _activeControllers.remove(index);
      }
    } catch (e) {
      debugPrint('Errore durante il dispose del controller: $e');
    } finally {
      _isDisposing = false;
    }
  }

  // Gestisce il cambio di pagina
  void onPageChanged(int newIndex) {
    _manageControllers(newIndex);
  }

  // Pulisci tutti i controller
  Future<void> disposeAll() async {
    for (var controller in _activeControllers.values) {
      controller.dispose();
    }
    _activeControllers.clear();
    _currentPlayingIndex = -1;
  }
}

// Implementazione nel widget
class ShortsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> shortSteps;
  
  const ShortsScreen({
    Key? key,
    required this.shortSteps,
  }) : super(key: key);

  @override
  _ShortsScreenState createState() => _ShortsScreenState();
}

class _ShortsScreenState extends State<ShortsScreen> {
  final VideoControllerManager _controllerManager = VideoControllerManager();
  
  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      itemBuilder: (context, index) {
        final videoId = widget.shortSteps[index]['videoId'];
        return VideoPlayerWidget(
          controller: _controllerManager.getController(index, videoId),
          index: index,
        );
      },
      onPageChanged: (index) {
        _controllerManager.onPageChanged(index);
      },
    );
  }

  @override
  void dispose() {
    _controllerManager.disposeAll();
    super.dispose();
  }
}

// Widget del video player ottimizzato
class VideoPlayerWidget extends StatelessWidget {
  final YoutubePlayerController? controller;
  final int index;

  const VideoPlayerWidget({
    Key? key,
    required this.controller,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return YoutubePlayer(
      controller: controller!,
      showVideoProgressIndicator: true,
      progressIndicatorColor: Colors.red,
      progressColors: const ProgressBarColors(
        playedColor: Colors.red,
        handleColor: Colors.redAccent,
      ),
    );
  }
}