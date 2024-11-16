// Crea un nuovo file lib/widgets/page_view_container.dart

import 'package:flutter/material.dart';
import '../screens/Articles_screen.dart';
import '../screens/notes_screen.dart';
import '../widgets/video_player_widget.dart';
import '../models/level.dart';

class PageViewContainer extends StatefulWidget {
  final String videoId;
  final Function(int) onCoinsUpdate;
  final String topic;
  final LevelStep? questionStep;
  final Function(int)? onPageChanged;

  const PageViewContainer({
    Key? key,
    required this.videoId,
    required this.onCoinsUpdate,
    required this.topic,
    this.questionStep,
    this.onPageChanged,
  }) : super(key: key);

  @override
  _PageViewContainerState createState() => _PageViewContainerState();
}

class _PageViewContainerState extends State<PageViewContainer> {
  final PageController _pageController = PageController(initialPage: 1);
  int _currentPage = 1;

  void _navigateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      physics: const PageScrollPhysics(),
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
        widget.onPageChanged?.call(index);
      },
      children: [
        ArticlesWidget(),
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
          onShowArticles: () => _navigateToPage(0),
          onShowNotes: () => _navigateToPage(2),
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