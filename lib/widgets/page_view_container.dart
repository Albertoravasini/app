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

  const PageViewContainer({
    Key? key,
    required this.videoId,
    required this.onCoinsUpdate,
    required this.topic,
    this.questionStep,
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
    return Stack(
      children: [
        PageView(
          controller: _pageController,
          physics: const PageScrollPhysics(),
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
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
        ),
        // Indicatore di pagina in alto
        Positioned(
          top: MediaQuery.of(context).padding.top + 8.0,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                height: 12,
                width: _currentPage == index ? 32 : 12,
                decoration: BoxDecoration(
                  color: _currentPage == index ? Colors.yellowAccent : Colors.white.withOpacity(0.10000000149011612),
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}