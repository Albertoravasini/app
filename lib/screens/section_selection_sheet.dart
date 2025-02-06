import 'package:Just_Learn/models/level.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:flutter/material.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import '../models/course.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SectionSelectionSheet extends StatefulWidget {
  final Course course;
  final Section? currentSection;
  final Function(Section, int) onSelectSection;

  const SectionSelectionSheet({
    Key? key,
    required this.course,
    this.currentSection,
    required this.onSelectSection,
  }) : super(key: key);

  @override
  _SectionSelectionSheetState createState() => _SectionSelectionSheetState();
}

class _SectionSelectionSheetState extends State<SectionSelectionSheet> with SingleTickerProviderStateMixin {
  Section? _selectedSection;
  late ScrollController _scrollController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.currentSection;
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleSectionSelection(Section section, int stepIndex) {
    // Aggiorna il currentStep nel database per la nuova sezione
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'currentSteps.${section.title}': stepIndex
      });
    }
    
    // Chiudi il bottom sheet solo su mobile
    if (!kIsWeb) {
      Navigator.pop(context);
    }
    
    // Riavvia il corso con la sezione selezionata
    widget.onSelectSection(section, stepIndex);
  }

  @override
  Widget build(BuildContext context) {
    // Se siamo su web, rimuovi il DraggableScrollableSheet
    if (kIsWeb) {
      return Container(
        color: const Color(0xFF121212),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.course.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: _buildSectionsList(),
            ),
          ],
        ),
      );
    }

    // Su mobile, mantieni il DraggableScrollableSheet
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mostra la lineetta e il titolo solo su mobile
              if (!kIsWeb) _buildMobileHeader(),
              Expanded(
                child: _buildSectionsList(scrollController: scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            widget.course.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsList({ScrollController? scrollController}) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getSectionsProgress(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          controller: scrollController,
          padding: EdgeInsets.zero,
          itemCount: widget.course.sections.length,
          itemBuilder: (context, index) {
            final section = widget.course.sections[index];
            final progressData = snapshot.data![index];
            
            return _buildSectionCard(section, progressData, index);
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getSectionsProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) return [];

    final userData = userDoc.data() as Map<String, dynamic>;
    final userModel = UserModel.fromMap(userData);
    final isPro = userData['isPro'] ?? false;
    
    // Calcola il numero totale di step nel corso
    final totalSteps = widget.course.sections
        .map((s) => s.steps.length)
        .reduce((a, b) => a + b);
    
    // Calcola il punto di blocco (30% del totale)
    final unlockLimit = (totalSteps * 0.3).round();
    var stepCounter = 0;
    
    print('DEBUG: Stato Pro: $isPro');
    print('DEBUG: Totale step corso: $totalSteps');
    print('DEBUG: Limite sblocco (30%): $unlockLimit');

    // Get completedPoints from userData
    final completedPoints = List<String>.from(userData['completedPoints'] ?? []);

    return Future.wait(
      widget.course.sections.map((section) async {
        int completedSteps = 0;
        List<bool> stepsCompleted = [];
        
        // Verifica se questa sezione contiene step oltre il limite del 30%
        bool containsLockedSteps = !isPro && stepCounter + section.steps.length > unlockLimit;
        int lockIndex = containsLockedSteps ? (unlockLimit - stepCounter).clamp(0, section.steps.length) : section.steps.length;
        
        print('DEBUG: Sezione ${section.title} - Start at: $stepCounter, Lock at: $lockIndex');
        
        for (var i = 0; i < section.steps.length; i++) {
          final step = section.steps[i];
          bool isStepCompleted = false;
          bool isStepLocked = !isPro && i >= lockIndex;

          if (!isStepLocked) {
            if (step.type == 'video') {
              final videoId = step.videoUrl ?? step.content;
              isStepCompleted = userModel.WatchedVideos[widget.course.topic]?.any((video) => 
                video.videoId == videoId && 
                video.completed
              ) ?? false;
            } else if (step.type == 'question') {
              isStepCompleted = userModel.answeredQuestions[widget.course.topic]?.contains(step.content) ?? false;
            } else if (step.type == 'points') {
              // Check if the points step is completed in completedPoints array
              isStepCompleted = completedPoints.contains(step.content);
            }
          }

          stepsCompleted.add(isStepCompleted);
          if (isStepCompleted) completedSteps++;
        }

        stepCounter += section.steps.length;

        return {
          'currentStep': completedSteps,
          'totalSteps': section.steps.length,
          'isCompleted': completedSteps == section.steps.length,
          'stepsCompleted': stepsCompleted,
          'lockIndex': lockIndex,
          'containsLockedSteps': containsLockedSteps
        };
      }),
    );
  }

  Widget _buildSectionCard(Section section, Map<String, dynamic> progressData, int index) {
    final completedSteps = progressData['currentStep'] as int;
    final totalSteps = progressData['totalSteps'] as int;
    final isSectionCompleted = progressData['isCompleted'] as bool;
    final stepsCompleted = progressData['stepsCompleted'] as List<bool>;
    final progress = completedSteps / totalSteps;
    final lockIndex = progressData['lockIndex'] as int;
    final containsLockedSteps = progressData['containsLockedSteps'] as bool;
    
    // Calcola il numero totale di step nel corso
    int totalCourseSteps = widget.course.sections.fold(0, (sum, section) => sum + section.steps.length);
    final lockedStepIndex = (totalCourseSteps * 0.3).floor();
    
    // Calcola l'indice globale del primo step di questa sezione
    int globalStartIndex = 0;
    for (var i = 0; i < index; i++) {
      globalStartIndex += widget.course.sections[i].steps.length;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSectionCompleted ? Colors.yellowAccent.withOpacity(0.3) : Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          listTileTheme: ListTileThemeData(
            dense: true,
          ),
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          childrenPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.yellowAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.yellowAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.clock,
                              size: 10,
                              color: Colors.grey[500],
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${_calculateTotalTime(section)} min',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              '$completedSteps/$totalSteps lezioni',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Color(0xFF2D2D2D),
                      valueColor: AlwaysStoppedAnimation(
                        isSectionCompleted 
                            ? Colors.yellowAccent 
                            : Colors.yellowAccent.withOpacity(0.7),
                      ),
                      minHeight: 3,
                    ),
                  ),
                  if (isSectionCompleted)
                    Positioned(
                      right: 0,
                      top: -8,
                      child: Icon(
                        FontAwesomeIcons.check,
                        color: Colors.yellowAccent,
                        size: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: section.steps.length,
              itemBuilder: (context, stepIndex) {
                final step = section.steps[stepIndex];
                final isStepCompleted = stepsCompleted[stepIndex];
                final lockIndex = progressData['lockIndex'] as int;
                final isLocked = progressData['containsLockedSteps'] as bool && stepIndex >= lockIndex;
                
                return _buildStepItem(
                  step: step,
                  stepNumber: stepIndex + 1,
                  isCurrentStep: stepIndex == completedSteps,
                  isCompleted: isStepCompleted,
                  isLocked: isLocked,
                  onTap: () {
                    if (!isLocked) {
                      _handleStepSelection(section, stepIndex);
                    } else {
                      // Naviga direttamente alla schermata di abbonamento
                      if (!kIsWeb) Navigator.pop(context);
                      Navigator.pushNamed(context, '/subscription');
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required LevelStep step,
    required int stepNumber,
    required bool isCurrentStep,
    required bool isCompleted,
    required VoidCallback onTap,
    required bool isLocked,
  }) {
    // Determina il colore base in base allo stato
    final Color baseColor = isLocked 
        ? Colors.grey[600]! 
        : (isCompleted 
            ? Colors.yellowAccent 
            : Colors.white);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isCurrentStep ? Colors.yellowAccent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isCurrentStep 
                    ? Colors.yellowAccent 
                    : Colors.transparent,
              ),
            ),
            SizedBox(width: 16),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isLocked 
                    ? Colors.grey[800]!.withOpacity(0.15)
                    : (isCompleted 
                        ? Colors.yellowAccent.withOpacity(0.15)
                        : Colors.grey[800]!.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLocked 
                        ? Icons.lock
                        : (step.type == 'video' 
                            ? FontAwesomeIcons.play 
                            : step.type == 'points'
                                ? FontAwesomeIcons.circle
                                : FontAwesomeIcons.question),
                    color: baseColor,
                    size: 14,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                _getStepTitle(step),
                style: TextStyle(
                  color: isLocked 
                      ? Colors.white.withOpacity(0.3)
                      : baseColor,
                  fontSize: 14,
                  fontWeight: isCurrentStep 
                      ? FontWeight.w500 
                      : FontWeight.normal,
                  decoration: isLocked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (step.duration != null)
              Text(
                '${step.duration} min',
                style: TextStyle(
                  color: isLocked 
                      ? Colors.grey[700] 
                      : (isCompleted ? Colors.yellowAccent : Colors.grey[500]),
                  fontSize: 12,
                ),
              ),
            if (isCompleted && !isLocked)
              Container(
                margin: EdgeInsets.only(left: 8),
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.yellowAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  FontAwesomeIcons.check,
                  color: Colors.yellowAccent,
                  size: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  IconData _getStepIcon(String type, bool isCompleted) {
    if (type == 'video') {
      return isCompleted ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.play;
    } else if (type == 'question') {
      return isCompleted ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.question;
    } else if (type == 'points') {
      return isCompleted ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.circle;
    }
    return FontAwesomeIcons.circle;
  }

  String _getStepTitle(LevelStep step) {
    switch (step.type) {
      case 'video':
        return step.content ?? 'Video lezione';
      case 'question':
        return 'Quiz';
      case 'points':
        return step.content ?? 'Points';
      default:
        return 'Contenuto';
    }
  }

  String _getStepDuration(LevelStep step) {
    if (step.type == 'video' && step.duration != null) {
      return '${step.duration} min';
    }
    return '';
  }

  void _handleStepSelection(Section section, int stepIndex) {
    // Aggiorna il currentStep nel database per la nuova sezione
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'currentSteps.${section.title}': stepIndex
      });
    }

    int indexForNavigation = stepIndex; // Valore di default: indice locale

    if (kIsWeb) {
      // Calcola l'indice globale per la piattaforma web
      int globalIndex = 0;
      for (var s in widget.course.sections) {
        if (s.title == section.title) {
          globalIndex += stepIndex;
          break;
        }
        globalIndex += s.steps.length;
      }
      indexForNavigation = globalIndex;
    } else {
      // Su mobile, chiudi il bottom sheet prima della navigazione
      Navigator.pop(context);
    }

    // Utilizza l'indice appropriato per la navigazione
    widget.onSelectSection(section, indexForNavigation);

    // Invia l'evento a Posthog
    Posthog().capture(
      eventName: 'step_selected',
      properties: {
        'section': section.title,
        'stepIndex': stepIndex,
        'usedIndex': indexForNavigation,
        'platform': kIsWeb ? 'web' : 'mobile'
      },
    );
  }

  int _calculateTotalTime(Section section) {
    int totalVideos = section.steps.where((step) => step.type == 'video').length;
    int totalQuestions = section.steps.where((step) => step.type == 'question').length;
    double totalTime = totalVideos * 1 + totalQuestions * 0.5;
    return totalTime.ceil();
  }

  Future<bool> _isStepCompleted(LevelStep step) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) return false;

    final userModel = UserModel.fromMap(userDoc.data()!);

    if (step.type == 'video') {
      final videoId = step.videoUrl ?? step.content;
      // Controlla in tutti i topic per i video completati
      final allWatchedVideos = userModel.WatchedVideos.values
          .expand((videos) => videos)
          .toList();
          
      print('\n=== DEBUG VIDEO MATCHING ===');
      print('Section: ${widget.currentSection?.title}');
      print('Step video: $videoId');
      print('Totale video trovati: ${allWatchedVideos.length}');
      
      return allWatchedVideos.any((video) {
        final isMatch = video.videoId.contains(videoId.split('?')[0]) && video.completed;
        if (isMatch) print('Video trovato e completato!');
        return isMatch;
      });
    } else if (step.type == 'question') {
      final answeredQuestions = userModel.answeredQuestions[widget.course.topic] ?? [];
      return answeredQuestions.contains(step.content);
    }

    return false;
  }

  String _extractVideoId(String url) {
    // Estrae il numero dal percorso, es: 1734344379372 da course_videos/1734344379372.mp4
    final regex = RegExp(r'course_videos%2F(\d+)\.mp4');
    final match = regex.firstMatch(url);
    return match?.group(1) ?? url;
  }


} 