import 'package:Just_Learn/models/course.dart';
import 'package:flutter/material.dart';
import '../widgets/web_video_info.dart';
import 'package:Just_Learn/screens/shorts_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class WebHomeScreen extends StatefulWidget {
  final Course? selectedCourse;
  final Section? selectedSection;

  const WebHomeScreen({
    Key? key,
    this.selectedCourse,
    this.selectedSection,
  }) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    if (widget.selectedCourse != null) {
      selectedTopic = widget.selectedCourse!.topic;
      selectedSubtopic = widget.selectedCourse!.subtopic;
      isInCourse = true;
    }
    
    // Avvia automaticamente il corso se è stato selezionato
    if (widget.selectedCourse != null && widget.selectedSection != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          isInCourse = true;
          currentSectionStep = 0;
          totalSectionSteps = widget.selectedSection!.steps.length;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Container verticale per il video che mantiene il rapporto 9/16
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxHeight * 9) / 16;
                
                return Container(
                  width: width,
                  
                  child: ShortsScreen(
                    key: ValueKey('${widget.selectedCourse?.id ?? ""}-$showSavedVideos'),
                    selectedTopic: selectedTopic,
                    selectedSubtopic: selectedSubtopic,
                    onVideoTitleChange: _updateVideoTitle,
                    onCoinsUpdate: _updateCoins,
                    showSavedVideos: showSavedVideos,
                    onPageChanged: _onPageChanged,
                    onSectionProgressUpdate: updateSectionProgress,
                    initialCourse: widget.selectedCourse,
                    initialSection: widget.selectedSection,
                    isInCourse: isInCourse,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

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
}
