import 'package:Just_Learn/models/level.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:Just_Learn/screens/home_screen.dart';
import 'package:flutter/material.dart';
import '../models/course.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:Just_Learn/screens/course_screen.dart';
import 'package:Just_Learn/screens/profile_screen.dart';

class CoursePreviewSheet extends StatefulWidget {
  final Course course;

  const CoursePreviewSheet({
    Key? key,
    required this.course,
  }) : super(key: key);

  @override
  State<CoursePreviewSheet> createState() => _CoursePreviewSheetState();
}

class _CoursePreviewSheetState extends State<CoursePreviewSheet> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool isExpanded = false;
  double _scrollOffset = 0;
  String _startButtonText = 'Start Course';

  // Stato del corso con ValueNotifier per aggiornamenti reattivi
  late final ValueNotifier<CourseState> _courseState;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Inizializza subito con locked per mostrare il testo
    _courseState = ValueNotifier<CourseState>(CourseState.locked);
    // Poi verifica lo stato reale
    _checkCourseState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _courseState.dispose();
    super.dispose();
  }

  // Verifica lo stato del corso
  Future<void> _checkCourseState() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _courseState.value = CourseState.error;
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!userDoc.exists) {
        _courseState.value = CourseState.error;
        return;
      }

      final userData = UserModel.fromMap(userDoc.data()!);
      _courseState.value = userData.unlockedCourses.contains(widget.course.id) 
          ? CourseState.unlocked 
          : CourseState.locked;
    } catch (e) {
      _courseState.value = CourseState.error;
    }
  }

  // Gestisce l'acquisto con coins
  Future<void> _unlockWithCoins(UserModel userData) async {
    try {
      if (userData.coins < widget.course.cost) {
        _showError('Insufficient Coins!');
        return;
      }

      // Aggiorna immediatamente l'UI
      _courseState.value = CourseState.unlocked;
      
      // Chiude il bottom sheet delle opzioni
      Navigator.pop(context);

      // Aggiorna il database in background
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userData.uid);
            
        // Aggiorna atomicamente coins e corsi sbloccati
        transaction.update(userRef, {
          'coins': userData.coins - widget.course.cost,
          'unlockedCourses': [...userData.unlockedCourses, widget.course.id],
        });
      });

      _showSuccess('Course unlocked successfully!');
    } catch (e) {
      // In caso di errore, ripristina lo stato precedente
      _courseState.value = CourseState.locked;
      _showError('Error unlocking course');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showStartCourseOptions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    if (!userDoc.exists || !mounted) return;
    
    final userData = UserModel.fromMap(userDoc.data()!);
    final subscriptions = userData.subscriptions ?? [];

    // Se l'utente è iscritto al creatore, il corso è automaticamente sbloccato
    if (subscriptions.contains(widget.course.authorId)) {
      setState(() {
        _courseState.value = CourseState.unlocked;
      });
      _showSuccess('Corso disponibile con la tua subscription');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ValueListenableBuilder<CourseState>(
        valueListenable: _courseState,
        builder: (context, state, child) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state == CourseState.locked) ...[
                  _buildOptionButton(
                    icon: Icons.stars_rounded,
                    title: 'Unlock with ${widget.course.cost} coins',
                    subtitle: 'You have ${userData.coins} coins available',
                    onTap: () => _unlockWithCoins(userData),
                  ),
                  const SizedBox(height: 16),
                  _buildOptionButton(
                    icon: Icons.workspace_premium_rounded,
                    title: 'Premium Subscription',
                    subtitle: 'Access all courses without limits',
                    onTap: () {
                      Navigator.pop(context); // Chiude il bottom sheet delle opzioni
                      Navigator.pop(context); // Torna al profilo
                    },
                  ),
                ] else if (state == CourseState.unlocked) ...[
                  _buildOptionButton(
                    icon: Icons.play_circle_filled,
                    title: 'Start Course',
                    subtitle: 'Course is unlocked',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        scrollController.addListener(() {
          setState(() {
            _scrollOffset = scrollController.offset;
          });
        });

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Immagine di copertina con effetto parallasse
              if (widget.course.coverImageUrl != null)
                Positioned(
                  top: -_scrollOffset * 0.5,
                  left: 0,
                  right: 0,
                  height: 300,
                  child: ShaderMask(
                    shaderCallback: (rect) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black,
                          Colors.transparent,
                        ],
                      ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
                    },
                    blendMode: BlendMode.dstIn,
                    child: Image.network(
                      widget.course.coverImageUrl!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              // Contenuto principale
              CustomScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header con titolo e autore
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Indicatore di trascinamento
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),

                          // Titolo del corso
                          Hero(
                            tag: 'courseTitle${widget.course.id}',
                            child: Text(
                              widget.course.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Informazioni sull'autore
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: widget.course.authorProfileUrl != null
                                    ? NetworkImage(widget.course.authorProfileUrl!)
                                    : null,
                                child: widget.course.authorProfileUrl == null
                                    ? Text(
                                        widget.course.authorName[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.course.authorName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Course Creator',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Statistiche del corso
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _buildCourseStats(),
                    ),
                  ),

                  // Descrizione
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Description',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.course.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Sezioni del corso
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Course Content',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...widget.course.sections.map((section) => 
                            _buildSectionCard(section)),
                        ],
                      ),
                    ),
                  ),

                  // Informazioni aggiuntive
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _buildAdditionalInfo(),
                    ),
                  ),

                  // Spazio finale
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 40),
                  ),
                ],
              ),

              // Pulsante di chiusura
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              // Aggiungiamo il nuovo bottone in fondo
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black,
                        Colors.black.withOpacity(0.9),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 2,
                            child: ValueListenableBuilder<CourseState>(
                              valueListenable: _courseState,
                              builder: (context, state, child) {
                                return Stack(
                                  children: [
                                    // ... resto del contenuto ...
                                    _buildStartButton(state),
                                  ],
                                );
                              },
                            ),
                          ),
                          
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCourseStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(Icons.star_rounded, '${widget.course.rating}', 'Rating'),
          _buildVerticalDivider(),
          _buildStat(Icons.people_alt_rounded, '${widget.course.totalRatings}', 'Reviews'),
          _buildVerticalDivider(),
          _buildStat(Icons.stars_rounded, '${widget.course.cost}', 'Cost'),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.yellowAccent,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(Section section) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getSectionProgress(section),
      builder: (context, snapshot) {
        final isCompleted = snapshot.data?['isCompleted'] ?? false;
        final totalSteps = section.steps.length;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF181819),
            borderRadius: BorderRadius.circular(20),
            border: isCompleted 
              ? Border.all(color: Colors.yellowAccent.withOpacity(0.3), width: 1.5)
              : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.all(20),
              childrenPadding: EdgeInsets.zero,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          section.title,
                          style: const TextStyle(
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
                  const SizedBox(height: 15),
                  _buildSectionDetails(section),
                  const SizedBox(height: 15),
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      children: List.generate(
                        totalSteps,
                        (index) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: isCompleted 
                                ? Colors.yellowAccent
                                : Colors.yellowAccent.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: section.steps.map((step) => _buildStepItem(step)).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionDetails(Section section) {
    int totalVideos = section.steps.where((step) => step.type == 'video').length;
    int totalQuestions = section.steps.where((step) => step.type == 'question').length;
    int totalTime = _calculateTotalTime(section);

    return Row(
      children: [
        _buildDetailIconText(Icons.timer, '$totalTime min'),
        const SizedBox(width: 23),
        _buildDetailIconText(Icons.video_collection, '$totalVideos video'),
        const SizedBox(width: 23),
        _buildDetailIconText(Icons.quiz, '$totalQuestions quiz'),
      ],
    );
  }

  Widget _buildStepItem(LevelStep step) {
    IconData icon;
    Color iconColor;
    
    switch (step.type) {
      case 'video':
        icon = Icons.play_circle_outline_rounded;
        iconColor = Colors.yellowAccent;
        break;
      case 'question':
        icon = Icons.quiz_rounded;
        iconColor = Colors.yellowAccent;
        break;
      default:
        icon = Icons.article_rounded;
        iconColor = Colors.yellowAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step.content,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.5),
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.course.sources.isNotEmpty) ...[
          _buildInfoSection('Sources', widget.course.sources),
          const SizedBox(height: 24),
        ],
        if (widget.course.recommendedBooks.isNotEmpty) ...[
          _buildInfoSection('Recommended Books', widget.course.recommendedBooks),
          const SizedBox(height: 24),
        ],
        if (widget.course.recommendedPodcasts.isNotEmpty) ...[
          _buildInfoSection('Recommended Podcasts', widget.course.recommendedPodcasts),
          const SizedBox(height: 24),
        ],
        if (widget.course.recommendedWebsites.isNotEmpty)
          _buildInfoSection('Recommended Websites', widget.course.recommendedWebsites),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.yellowAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  int _calculateTotalTime(Section section) {
    int totalVideos = section.steps.where((step) => step.type == 'video').length;
    int totalQuestions = section.steps.where((step) => step.type == 'question').length;
    double totalTime = totalVideos * 1 + totalQuestions * 0.5;
    return totalTime.ceil();
  }

  Future<Map<String, dynamic>> _getSectionProgress(Section section) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {'currentStep': 0, 'isCompleted': false};
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      return {'currentStep': 0, 'isCompleted': false};
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    final currentSteps = userData['currentSteps'] as Map<String, dynamic>? ?? {};
    final completedSections = List<String>.from(userData['completedSections'] ?? []);

    final currentStep = (currentSteps[section.title] ?? 0) + 1;
    final isCompleted = completedSections.contains(section.title) || 
                       currentStep >= section.steps.length;

    return {
      'currentStep': isCompleted ? section.steps.length : currentStep,
      'isCompleted': isCompleted,
    };
  }

  Widget _buildStartButton(CourseState state) {
    final buttonConfig = switch (state) {
      CourseState.locked => _ButtonConfig(
          text: 'Unlock Course',
          onPressed: _showStartCourseOptions,
        ),
      CourseState.unlocked => _ButtonConfig(
          text: 'Start Course',
          onPressed: () => Navigator.pop(context),
        ),
      _ => _ButtonConfig(
          text: 'Loading...',
          onPressed: null,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 60,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: buttonConfig.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellowAccent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
          ),
          child: Text(
            buttonConfig.text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.yellowAccent, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// Enums e classi di supporto
enum CourseState { loading, locked, unlocked, error }

class _ButtonConfig {
  final String text;
  final VoidCallback? onPressed;
  
  const _ButtonConfig({required this.text, this.onPressed});
}