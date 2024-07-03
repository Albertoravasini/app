import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoCard extends StatefulWidget {
  final dynamic video;

  VideoCard({required this.video});

  @override
  _VideoCardState createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  late YoutubePlayerController _controller;
  bool _isControllerReady = false;
  double _currentSliderValue = 0;

  @override
  void initState() {
    super.initState();
    final videoId = widget.video['id'] as String?;
    if (videoId != null) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId!,
        flags: YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
        ),
      )..addListener(_listener);
    }
  }

  void _listener() {
    if (_controller.value.isReady && !_isControllerReady) {
      setState(() {
        _isControllerReady = true;
      });
    }

    if (_controller.value.isPlaying) {
      setState(() {
        _currentSliderValue = _controller.value.position.inSeconds.toDouble();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String abbreviateNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  String timeAgo(DateTime date) {
    final duration = DateTime.now().difference(date);
    if (duration.inDays > 365) {
      return '${(duration.inDays / 365).floor()} years ago';
    } else if (duration.inDays > 30) {
      return '${(duration.inDays / 30).floor()} months ago';
    } else if (duration.inDays > 7) {
      return '${(duration.inDays / 7).floor()} weeks ago';
    } else if (duration.inDays > 0) {
      return '${duration.inDays} days ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hours ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minutes ago';
    } else {
      return 'just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoSnippet = widget.video['snippet'];
    final channelId = videoSnippet['channelId'];
    final channelTitle = videoSnippet['channelTitle'];
    final videoTitle = videoSnippet['title'];
    final thumbnailUrl = videoSnippet['thumbnails']['default']['url'];
    final publishDate = DateTime.parse(videoSnippet['publishedAt']);
    final viewCount = int.parse(widget.video['statistics']['viewCount']);
    final videoDuration = _controller.metadata.duration.inSeconds.toDouble();

    if (_controller == null) {
      return Center(child: Text('Video not available'));
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                onReady: () {
                  setState(() {
                    _isControllerReady = true;
                  });
                  _controller.play();
                },
              ),
            ),
          ),
        ),
        Slider(
          activeColor: Colors.white,
          inactiveColor: Colors.transparent,
          value: _currentSliderValue,
          min: 0,
          max: videoDuration,
          onChanged: (value) {
            setState(() {
              _currentSliderValue = value;
              _controller.seekTo(Duration(seconds: value.toInt()));
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(thumbnailUrl),
                radius: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      videoTitle,
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Text(
                          channelTitle,
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        SizedBox(width: 5),
                        Text(
                          '${abbreviateNumber(viewCount)} views',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        SizedBox(width: 5),
                        Text(
                          timeAgo(publishDate),
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}