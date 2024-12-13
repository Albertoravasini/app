// Crea un nuovo file lib/widgets/page_view_container.dart

import 'package:Just_Learn/models/course.dart';
import 'package:flutter/material.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import '../screens/Articles_screen.dart';
import '../screens/notes_screen.dart';
import '../widgets/video_player_widget.dart';
import '../models/level.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../widgets/course_video/course_info_overlay.dart';
import '../screens/comments_screen.dart';

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
  final Section? currentSection;

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
    this.currentSection,
  }) : super(key: key);

  @override
  _PageViewContainerState createState() => _PageViewContainerState();
}

class _PageViewContainerState extends State<PageViewContainer> {
  final PageController _pageController = PageController(initialPage: 1);
  String videoTitle = '';

  @override
  void initState() {
    super.initState();
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
          course: widget.course,
          onShowArticles: (_) => _pageController.animateToPage(0, duration: Duration(milliseconds: 300), curve: Curves.easeInOut),
          onShowNotes: (_) => _pageController.animateToPage(2, duration: Duration(milliseconds: 300), curve: Curves.easeInOut),
          openComments: (_) => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))
            ),
            builder: (context) => CommentsScreen(videoId: widget.videoId),
          ),
          isInCourse: widget.isInCourse,
          onStartCourse: widget.onStartCourse,
          onCoinsUpdate: widget.onCoinsUpdate,
          topic: widget.topic,
          currentSection: widget.currentSection,
        ),
        NotesScreen(),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}