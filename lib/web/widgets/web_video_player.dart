import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:Just_Learn/controllers/video_player_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WebVideoPlayer extends StatefulWidget {
  final VideoPlayerManager videoManager;
  final bool showControls;

  const WebVideoPlayer({
    Key? key,
    required this.videoManager,
    this.showControls = true,
  }) : super(key: key);

  @override
  _WebVideoPlayerState createState() => _WebVideoPlayerState();
}

class _WebVideoPlayerState extends State<WebVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFirstVideo();
  }

  Future<void> _loadFirstVideo() async {
    try {
      // Carica il primo video disponibile da Firestore
      final videoDoc = await FirebaseFirestore.instance
          .collection('levels')
          .where('type', isEqualTo: 'video')
          .limit(1)
          .get();

      if (videoDoc.docs.isNotEmpty) {
        final videoUrl = videoDoc.docs.first.data()['content'] as String;
        await _initializeVideo(videoUrl);
      } else {
        print('Nessun video trovato nel database');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Errore nel caricamento del video: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeVideo(String videoUrl) async {
    try {
      _controller = VideoPlayerController.network(videoUrl);
      
      await _controller.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
        _controller.play();
      }
    } catch (e) {
      print('Errore nell\'inizializzazione del video: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return MouseRegion(
      onEnter: (_) => _showControls(),
      onExit: (_) => _hideControls(),
      child: Stack(
        children: [
          // Video player
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),

          // Controlli minimi che appaiono solo al passaggio del mouse
          if (_isHovering)
            AnimatedOpacity(
              opacity: _isHovering ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _buildMinimalControls(),
            ),
        ],
      ),
    );
  }

  Widget _buildMinimalControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.black26,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isHovering = false;

  void _showControls() {
    setState(() => _isHovering = true);
  }

  void _hideControls() {
    setState(() => _isHovering = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
} 