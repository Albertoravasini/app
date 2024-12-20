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
  bool _isCommentsVisible = false;

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
        _showComments();
      });
    }
  }

  void _showComments() {
    setState(() => _isCommentsVisible = true);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => WillPopScope(
        onWillPop: () async {
          setState(() => _isCommentsVisible = false);
          return true;
        },
        child: CommentsScreen(videoId: widget.videoId),
      ),
    ).then((_) => setState(() => _isCommentsVisible = false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              AspectRatio(
                aspectRatio: 9 / 16,
                child: YoutubePlayer(
                  controller: _controller,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: Colors.yellowAccent,
                  progressColors: const ProgressBarColors(
                    playedColor: Colors.yellowAccent,
                    handleColor: Colors.yellowAccent,
                  ),
                ),
              ),
              if (!_isCommentsVisible && !widget.autoOpenComments)
                Expanded(
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _showComments,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellowAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.comment),
                          SizedBox(width: 8),
                          Text(
                            'Visualizza commenti',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (widget.autoOpenComments && !_isCommentsVisible)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: _showComments,
                backgroundColor: Colors.yellowAccent,
                child: const Icon(
                  Icons.comment,
                  color: Colors.black,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}