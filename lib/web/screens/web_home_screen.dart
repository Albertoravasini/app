import 'package:flutter/material.dart';
import '../widgets/web_video_info.dart';
import 'package:Just_Learn/screens/shorts_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class WebHomeScreen extends StatefulWidget {
  @override
  _WebHomeScreenState createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  String? selectedTopic;
  String? selectedSubtopic;
  bool showSavedVideos = false;
  int currentSectionStep = 0;
  int totalSectionSteps = 0;
  bool isInCourse = false;

  void _updateVideoTitle(String title) {}
  void _updateCoins(int newCoins) {}
  void _onPageChanged(int page) {}
  
  void updateSectionProgress(int current, int total, bool inCourse) {
    setState(() {
      currentSectionStep = current;
      totalSectionSteps = total;
      isInCourse = inCourse;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Pannello laterale sinistr
        
        // Video player centrale con aspect ratio 9:16
        Expanded(
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.height * 0.5625, // 9:16 ratio
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: ShortsScreen(
                key: ValueKey('$selectedTopic-$selectedSubtopic-$showSavedVideos'),
                selectedTopic: selectedTopic,
                selectedSubtopic: selectedSubtopic,
                onVideoTitleChange: _updateVideoTitle,
                onCoinsUpdate: _updateCoins,
                showSavedVideos: showSavedVideos,
                onPageChanged: _onPageChanged,
                onSectionProgressUpdate: updateSectionProgress,
              ),
            ),
          ),
        ),
        
        
      ],
    );
  }
}
