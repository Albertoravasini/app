// Crea un nuovo file lib/widgets/page_view_container.dart

import 'package:Just_Learn/models/course.dart';
import 'package:flutter/material.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import '../screens/Articles_screen.dart';
import '../screens/notes_screen.dart';
import '../widgets/video_player_widget.dart';
import '../models/level.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class PageViewContainer extends StatefulWidget {
  final String videoId;
  final Function(int) onCoinsUpdate;
  final String topic;
  final LevelStep? questionStep;
  final Function(int)? onPageChanged;
  final String videoTitle;
  final Course course;
  final Function(Course?, Section?) onStartCourse;
  final bool isInCourse;

  const PageViewContainer({
    Key? key,
    required this.videoId,
    required this.onCoinsUpdate,
    required this.topic,
    required this.videoTitle,
    required this.course,
    required this.onStartCourse,
    this.questionStep,
    this.onPageChanged,
    this.isInCourse = false,
  }) : super(key: key);

  @override
  _PageViewContainerState createState() => _PageViewContainerState();
}

class _PageViewContainerState extends State<PageViewContainer> {
  final PageController _pageController = PageController(initialPage: 1);
  late YoutubePlayerController _controller;
  String videoTitle = '';

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    )..addListener(() {
      if (_controller.metadata.title != null) {
        setState(() {
          videoTitle = _controller.metadata.title!;
        });
      }
    });
  }

  void _onPageChanged(int page) {
    widget.onPageChanged?.call(page);
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      physics: const PageScrollPhysics(),
      onPageChanged: _onPageChanged,
      children: [
        ArticlesWidget(
          videoTitle: widget.videoTitle,
          levelId: widget.videoId,
        ),
        VideoPlayerWidget(
          videoId: widget.videoId,
          onCoinsUpdate: widget.onCoinsUpdate,
          topic: widget.topic,
          onShowQuestion: () {},
          isLiked: false,
          likeCount: 0,
          isSaved: false,
          questionStep: widget.questionStep,
          onVideoUnsaved: () {},
          onShowArticles: () => _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
          onShowNotes: () => _pageController.animateToPage(
            2,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
          course: widget.course,
          onStartCourse: widget.onStartCourse,
          isInCourse: widget.isInCourse,
        ),
        NotesScreen(),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }
}