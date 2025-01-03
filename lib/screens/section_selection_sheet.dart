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
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
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
                  ],
                ),
              ),
              
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
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
                ),
              ),
            ],
          ),
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

    // Animazione principale per l'entrata
    final Animation<double> slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        (index * 0.1).clamp(0.0, 1.0),
        ((index * 0.1) + 0.5).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    // Animazione secondaria per lo scaling
    final Animation<double> scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        (index * 0.1).clamp(0.0, 1.0),
        ((index * 0.1) + 0.7).clamp(0.0, 1.0),
        curve: Curves.easeOutBack,
      ),
    );

    // Animazione per la rotazione
    final Animation<double> rotateAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        (index * 0.1).clamp(0.0, 1.0),
        ((index * 0.1) + 0.6).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return GestureDetector(
      onTap: () => _handleSectionSelection(section),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX((1 - rotateAnimation.value) * 0.2)
              ..translate(
                0.0,
                50.0 * (1 - slideAnimation.value),
                0.0,
              ),
            alignment: Alignment.center,
            child: Opacity(
              opacity: slideAnimation.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.6 + (0.4 * scaleAnimation.value),
                child: child,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFF181819),
                borderRadius: BorderRadius.circular(20),
                border: isCompleted 
                  ? Border.all(color: Colors.yellowAccent.withOpacity(0.3), width: 1.5)
                  : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
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
                    _buildProgressBar(currentStep, totalSteps, isCompleted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(int currentStep, int totalSteps, bool isCompleted) {
    // Calcola il progresso esattamente come viene mostrato nel contatore
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

  int _calculateTotalTime(Section section) {
    int totalVideos = section.steps.where((step) => step.type == 'video').length;
    int totalQuestions = section.steps.where((step) => step.type == 'question').length;
    double totalTime = totalVideos * 1 + totalQuestions * 0.5;
    return totalTime.ceil();
  }
} 