import 'package:Just_Learn/models/level.dart';
import 'package:flutter/material.dart';
import '../models/course.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SectionSelectionSheet extends StatefulWidget {
  final Course course;
  final Section? currentSection;
  final Function(Section) onSelectSection;

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

  void _handleSectionSelection(Section section) {
    // Aggiorna il currentStep nel database per la nuova sezione
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'currentSteps.${section.title}': 0
      });
    }
    
    // Chiudi il bottom sheet solo su mobile
    if (!kIsWeb) {
      Navigator.pop(context);
    }
    
    // Riavvia il corso con la sezione selezionata
    widget.onSelectSection(section);
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
    final currentSteps = userData['currentSteps'] as Map<String, dynamic>? ?? {};
    final completedSections = List<String>.from(userData['completedSections'] ?? []);

    return Future.wait(
      widget.course.sections.map((section) async {
        final currentStep = (currentSteps[section.title] ?? 0) + 1;
        final totalSteps = section.steps.length;
        
        // Una sezione è completata se:
        // 1. È nella lista delle sezioni completate
        // 2. OPPURE se l'utente ha raggiunto l'ultimo step
        final isCompleted = completedSections.contains(section.title) || 
                          currentStep >= totalSteps;

        // Se la sezione è completata, mostriamo il progresso come completo
        final displayedProgress = isCompleted ? totalSteps : currentStep;

        return {
          'currentStep': displayedProgress,  // Mostra progresso completo se la sezione è completata
          'totalSteps': totalSteps,
          'isCompleted': isCompleted
        };
      }),
    );
  }

  Widget _buildSectionCard(Section section, Map<String, dynamic> progressData, int index) {
    final currentStep = progressData['currentStep'] as int;
    final totalSteps = progressData['totalSteps'] as int;
    final isCompleted = progressData['isCompleted'] as bool;
    final progress = currentStep / totalSteps;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          childrenPadding: EdgeInsets.only(left: 16, right: 16, bottom: 12),
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
                  Text(
                    '${index + 1}.',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
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
                              '$currentStep/$totalSteps lezioni',
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
                        isCompleted 
                            ? Colors.yellowAccent 
                            : Colors.yellowAccent.withOpacity(0.7),
                      ),
                      minHeight: 3,
                    ),
                  ),
                  if (isCompleted)
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
                final isCurrentStep = stepIndex == currentStep - 1;
                final isStepCompleted = stepIndex < currentStep - 1;
                
                return _buildStepItem(
                  step: step,
                  stepNumber: stepIndex + 1,
                  isCurrentStep: isCurrentStep,
                  isCompleted: isStepCompleted,
                  onTap: () => _handleStepSelection(section, stepIndex),
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
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
            Icon(
              _getStepIcon(step.type, isCompleted),
              color: isCompleted 
                  ? Colors.yellowAccent
                  : Colors.grey[400],
              size: 14,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                _getStepTitle(step),
                style: TextStyle(
                  color: Colors.white.withOpacity(
                    isCurrentStep ? 1 : 0.7,
                  ),
                  fontSize: 14,
                  fontWeight: isCurrentStep 
                      ? FontWeight.w500 
                      : FontWeight.normal,
                ),
              ),
            ),
            if (step.duration != null)
              Text(
                '${step.duration} min',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            if (isCompleted)
              Padding(
                padding: EdgeInsets.only(left: 12),
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
    if (isCompleted) return FontAwesomeIcons.checkCircle;
    
    switch (type) {
      case 'video':
        return FontAwesomeIcons.play;
      case 'question':
        return FontAwesomeIcons.question;
      default:
        return FontAwesomeIcons.circle;
    }
  }

  String _getStepTitle(LevelStep step) {
    switch (step.type) {
      case 'video':
        return step.content ?? 'Video lezione';
      case 'question':
        return 'Quiz';
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
    _handleSectionSelection(section);
    // Implementa la logica per saltare direttamente allo step selezionato
  }

  int _calculateTotalTime(Section section) {
    int totalVideos = section.steps.where((step) => step.type == 'video').length;
    int totalQuestions = section.steps.where((step) => step.type == 'question').length;
    double totalTime = totalVideos * 1 + totalQuestions * 0.5;
    return totalTime.ceil();
  }
} 