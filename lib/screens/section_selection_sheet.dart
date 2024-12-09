import 'package:flutter/material.dart';
import '../models/course.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class _SectionSelectionSheetState extends State<SectionSelectionSheet> {
  Section? _selectedSection;

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.currentSection;
  }

  void _handleSectionSelection(Section section) {
    // Chiudi il bottom sheet
    Navigator.pop(context);
    
    // Aggiorna il currentStep nel database per la nuova sezione
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'currentSteps.${section.title}': 0  // Imposta lo step a 0 per la nuova sezione
      });
    }
    
    // Riavvia il corso con la sezione selezionata
    widget.onSelectSection(section);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lineetta estetica in alto
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
              
              // Titolo del corso
              Text(
                widget.course.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Lista delle sezioni
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: Future.wait(
                    widget.course.sections.map((section) async {
                      final data = await _getCurrentStepForSection(section.title);
                      return {
                        'progress': _calculateTotalProgress(
                          section,
                          data['currentStep'] as int,
                          List<String>.from(data['answeredQuestions']),
                        ),
                        'isCompleted': data['isCompleted'] as bool,
                        'totalSteps': section.steps.length,
                      };
                    })
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: widget.course.sections.length,
                      itemBuilder: (context, index) {
                        final section = widget.course.sections[index];
                        final data = snapshot.data![index];
                        final currentProgress = data['progress'] as int;
                        final isCompleted = data['isCompleted'] as bool;
                        final totalSteps = data['totalSteps'] as int;
                        
                        return GestureDetector(
                          onTap: () => _handleSectionSelection(section),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Color(0xFF181819),
                              borderRadius: BorderRadius.circular(20),
                              border: isCompleted 
                                ? Border.all(color: Colors.yellowAccent.withOpacity(0), width: 1.5)
                                : null,
                            ),
                            child: Stack(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              section.title,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          if (isCompleted)
                                            SvgPicture.asset(
                                              'assets/solar_verified-check-linear.svg',
                                              width: 24,
                                              height: 24,
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 15),
                                      _buildSectionDetails(section),
                                      SizedBox(height: 15),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: _buildProgressBar(
                                          currentProgress,
                                          totalSteps,
                                          isCompleted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Aggiungi questi metodi helper
  Widget _buildProgressBar(int currentStep, int totalSteps, bool isCompleted) {
    double progress = totalSteps > 0 ? currentStep / totalSteps : 0;
    
    return Container(
      width: double.infinity,
      height: 6,
      decoration: BoxDecoration(
        color: Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: isCompleted ? Colors.yellowAccent : Colors.white,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionDetails(Section section) {
    int totalVideos = section.steps.where((step) => step.type == 'video').length;
    int totalQuestions = section.steps.where((step) => step.type == 'question').length;
    int totalTime = _calculateTotalTime(section);

    return Row(
      children: [
        _buildDetailIconText(Icons.timer, '$totalTime minutes'),
        const SizedBox(width: 23),
        _buildDetailIconText(Icons.video_collection, '$totalVideos videos'),
        const SizedBox(width: 23),
        _buildDetailIconText(Icons.quiz, '$totalQuestions questions'),
      ],
    );
  }

  Widget _buildDetailIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.5), size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _getCurrentStepForSection(String sectionTitle) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final currentSteps = userData['currentSteps'] as Map<String, dynamic>? ?? {};
          final answeredQuestions = userData['answeredQuestions'] as Map<String, dynamic>? ?? {};
          final completedSections = List<String>.from(userData['completedSections'] ?? []);
          
          // Recupera il progresso per questa sezione
          final currentStep = currentSteps[sectionTitle] as int? ?? 0;
          final sectionAnswers = answeredQuestions[sectionTitle] as List<dynamic>? ?? [];
          
          return {
            'currentStep': currentStep,
            'answeredQuestions': sectionAnswers,
            'isCompleted': completedSections.contains(sectionTitle),
          };
        }
      } catch (e) {
        print('Error getting section progress: $e');
      }
    }
    return {
      'currentStep': 0,
      'answeredQuestions': [],
      'isCompleted': false,
    };
  }

  int _calculateTotalProgress(Section section, int currentStep, List<String> answeredQuestions) {
    int progress = currentStep;
    
    // Conta gli step di tipo domanda che sono stati completati
    for (var i = 0; i < section.steps.length; i++) {
      if (section.steps[i].type == 'question' && 
          answeredQuestions.contains(section.steps[i].content)) {
        progress++;
      }
    }
    
    return progress;
  }

  int _calculateTotalTime(Section section) {
    int totalVideos = section.steps.where((step) => step.type == 'video').length;
    int totalQuestions = section.steps.where((step) => step.type == 'question').length;
    double totalTime = totalVideos * 1 + totalQuestions * 0.5;
    return totalTime.ceil();
  }
} 