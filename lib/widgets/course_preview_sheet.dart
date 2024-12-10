import 'package:Just_Learn/models/level.dart';
import 'package:flutter/material.dart';
import '../models/course.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
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
                                    'Creatore del corso',
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
                            'Descrizione',
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
                            'Contenuto del corso',
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
          _buildStat(Icons.people_alt_rounded, '${widget.course.totalRatings}', 'Recensioni'),
          _buildVerticalDivider(),
          _buildStat(Icons.stars_rounded, '${widget.course.cost}', 'Costo'),
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
          _buildInfoSection('Fonti', widget.course.sources),
          const SizedBox(height: 24),
        ],
        if (widget.course.recommendedBooks.isNotEmpty) ...[
          _buildInfoSection('Libri consigliati', widget.course.recommendedBooks),
          const SizedBox(height: 24),
        ],
        if (widget.course.recommendedPodcasts.isNotEmpty) ...[
          _buildInfoSection('Podcast consigliati', widget.course.recommendedPodcasts),
          const SizedBox(height: 24),
        ],
        if (widget.course.recommendedWebsites.isNotEmpty)
          _buildInfoSection('Siti web consigliati', widget.course.recommendedWebsites),
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
} 