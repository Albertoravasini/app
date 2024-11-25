import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'comments_screen.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final bool autoOpenComments;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    this.autoOpenComments = false,
  });

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );

    if (widget.autoOpenComments) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openComments(context);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => CommentsScreen(videoId: widget.videoId, ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0), // Sfondo bianco
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0), // AppBar bianca
        elevation: 0, // Rimuove l'ombra per un design piatto
        title: const Text(
          '',
          style: TextStyle(
            color: Color.fromARGB(221, 255, 255, 255), // Testo nero/grigio scuro per contrasto
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0), // Padding orizzontale per centrare
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AspectRatio(
              aspectRatio: 9 / 16, // Mantiene il rapporto 9:16
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25), // Bordi arrotondati
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: YoutubePlayer(
                    controller: _controller,
                    showVideoProgressIndicator: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20), // Spazio tra il video e il pulsante
            SizedBox(
              width: MediaQuery.of(context).size.width * 1, // Larghezza del pulsante pari al 70% della larghezza dello schermo
              child: ElevatedButton(
                onPressed: () => _openComments(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(221, 255, 255, 255), // Colore di sfondo del pulsante
                  foregroundColor: const Color.fromARGB(255, 0, 0, 0), // Colore del testo del pulsante
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25), // Bordi arrotondati
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                child: const Text('Open Comments'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}