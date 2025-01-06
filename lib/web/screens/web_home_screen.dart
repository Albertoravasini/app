import 'package:Just_Learn/models/course.dart';
import 'package:Just_Learn/screens/section_selection_sheet.dart';
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
  Course? currentCourse;
  Section? currentSection;
  int currentVideoIndex = 0;
  final GlobalKey<ShortsScreenState> _shortsScreenKey = GlobalKey<ShortsScreenState>();

  @override
  void initState() {
    super.initState();
    if (widget.selectedCourse != null) {
      selectedTopic = widget.selectedCourse!.topic;
      selectedSubtopic = widget.selectedCourse!.subtopic;
      isInCourse = true;
      currentCourse = widget.selectedCourse;
      currentSection = widget.selectedSection;
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
    return Row(
      children: [
        // Section Selection Sheet
        if (currentCourse != null) 
          Container(
            width: 300, // Larghezza fissa per la section sheet
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Colors.grey[800]!,
                  width: 1,
                ),
              ),
            ),
            child: SectionSelectionSheet(
              course: currentCourse!,
              currentSection: currentSection,
              onSelectSection: (section) {
                setState(() {
                  currentSection = section;
                  // Calcola l'indice di inizio della sezione
                  int startIndex = 0;
                  for (var s in currentCourse!.sections) {
                    if (s.title == section.title) break;
                    startIndex += s.steps.length;
                  }
                  currentVideoIndex = startIndex;
                });
                
                // Aggiorna anche il ShortsScreen
                if (_shortsScreenKey.currentState != null) {
                  _shortsScreenKey.currentState!.jumpToPage(currentVideoIndex);
                }
              },
            ),
          ),

        // Video Player e contenuto principale
        Expanded(
          child: Stack(
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
                          key: _shortsScreenKey,
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
          ),
        ),
      ],
    );
  }

  void _updateVideoTitle(String title) {}
  void _updateCoins(int newCoins) {}
  void _onPageChanged(int index) {
    if (!mounted || currentCourse == null) return;
    
    // Trova la sezione corrente in base all'indice
    int stepCount = 0;
    Section? newSection;
    
    for (var section in currentCourse!.sections) {
      if (index < stepCount + section.steps.length) {
        newSection = section;
        break;
      }
      stepCount += section.steps.length;
    }
    
    // Aggiorna lo stato solo se la sezione è cambiata
    if (newSection != null && newSection != currentSection) {
      setState(() {
        currentSection = newSection;
        currentVideoIndex = index;
      });
    }
  }
  
  void updateSectionProgress(int current, int total, bool inCourse) {
    if (!mounted) return;
    
    setState(() {
      currentSectionStep = current;
      totalSectionSteps = total;
      isInCourse = inCourse;
      
      // Se siamo all'ultimo step della sezione, prepara il passaggio alla prossima
      if (current == total - 1 && currentSection != null) {
        int currentSectionIndex = currentCourse?.sections.indexOf(currentSection!) ?? -1;
        if (currentSectionIndex >= 0 && currentSectionIndex < (currentCourse?.sections.length ?? 0) - 1) {
          // Prepara la transizione alla prossima sezione
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted && _shortsScreenKey.currentState != null) {
              Section nextSection = currentCourse!.sections[currentSectionIndex + 1];
              int nextIndex = _calculateSectionStartIndex(nextSection);
              _shortsScreenKey.currentState!.jumpToPage(nextIndex);
            }
          });
        }
      }
    });
  }

  // Metodo helper per calcolare l'indice di inizio di una sezione
  int _calculateSectionStartIndex(Section targetSection) {
    int startIndex = 0;
    for (var section in currentCourse!.sections) {
      if (section.title == targetSection.title) break;
      startIndex += section.steps.length;
    }
    return startIndex;
  }
}
