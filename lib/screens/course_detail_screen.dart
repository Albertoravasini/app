// lib/screens/course_detail_screen.dart

import 'package:Just_Learn/models/level.dart';
import 'package:Just_Learn/screens/subscription_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/course.dart';
import 'level_screen.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  final UserModel user;

  const CourseDetailScreen({super.key, required this.course, required this.user});

  @override
  _CourseDetailScreenState createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _isCourseUnlocked = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _isCourseUnlocked = widget.user.unlockedCourses.contains(widget.course.id);
    // Registra l'evento di visualizzazione del corso
    FirebaseAnalytics.instance.logEvent(
      name: 'course_view',
      parameters: {
        'course_id': widget.course.id,
        'course_title': widget.course.title,
        'user_id': widget.user.uid,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _isCourseUnlocked = widget.user.unlockedCourses.contains(widget.course.id);

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  _buildVideoThumbnails(),
                  const SizedBox(height: 20),
                  _buildPageIndicators(),
                  const SizedBox(height: 20),
                  _buildSections(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          if (!_isCourseUnlocked) _buildBottomButtons(),
          _buildBackButton(),
          _buildInfoButton(), // Aggiungi il pulsante "i" qui
        ],
      ),
    );
  }

  /// Costruisce i bottoni di sottoscrizione e prezzo
  Widget _buildBottomButtons() {
    if (!_isCourseUnlocked) {
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row per i due bottoni
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildSubscribeButton(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: _buildPriceButton(),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  /// Costruisce il bottone di sottoscrizione
  Widget _buildSubscribeButton() {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.yellowAccent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
        ),
        child: const Text(
          'Subscribe',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
    );
  }

  /// Costruisce il bottone per sbloccare il corso con il prezzo dinamico
  Widget _buildPriceButton() {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: _unlockCourse,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.05),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: Colors.white12,
            width: 2,
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stars_rounded, color: Colors.yellow, size: 25),
            const SizedBox(width: 8),
            Text(
              '${widget.course.cost}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Funzione per sbloccare il corso
  void _unlockCourse() async {
    if (widget.user.coins >= widget.course.cost) {
      int newCoins = widget.user.coins - widget.course.cost;
      List<String> newUnlockedCourses = List.from(widget.user.unlockedCourses)..add(widget.course.id);

      setState(() {
        widget.user.coins = newCoins;
        widget.user.unlockedCourses = newUnlockedCourses;
        _isCourseUnlocked = true;
      });

      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
        'coins': newCoins,
        'unlockedCourses': newUnlockedCourses,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Course unlocked!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not enough coins')),
      );
    }
    // Registra l'evento di sblocco del corso
    FirebaseAnalytics.instance.logEvent(
      name: 'course_unlocked',
      parameters: {
        'course_id': widget.course.id,
        'course_title': widget.course.title,
        'user_id': widget.user.uid,
      },
    );
  }

  /// Funzione per ottenere il currentStep per una sezione
  int _getCurrentStepForSection(String sectionTitle) {
    return widget.user.currentSteps[sectionTitle] ?? 0; // Se non c'è progresso, restituisce 0
  }

  /// Funzione per calcolare il tempo totale per completare una sezione
  int _calculateTotalTime(Section section) {
    int totalVideos = section.steps.where((step) => step.type == 'video').length;
    int totalQuestions = section.steps.where((step) => step.type == 'question').length;

    double totalTime = totalVideos * 1 + totalQuestions * 0.5;
    return totalTime.ceil(); // Arrotonda per eccesso
  }

  /// Costruisce le sezioni del corso
  Widget _buildSections() {
    return Column(
      children: widget.course.sections.map((section) {
        int totalTime = _calculateTotalTime(section);
        int totalVideos = section.steps.where((step) => step.type == 'video').length;
        int totalQuestions = section.steps.where((step) => step.type == 'question').length;

        // Ottieni il currentStep per la sezione dall'utente
        int currentStep = _getCurrentStepForSection(section.title);
        bool isCompleted = currentStep >= section.steps.length;

        // Usa l'icona corretta in base al completamento della sezione
        String iconAsset = isCompleted
            ? 'assets/solar_verified-check-linear.svg'
            : 'assets/ph_arrow-up-bold.svg';

        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: GestureDetector(
            onTap: _isCourseUnlocked
                ? () async {
                    bool? result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LevelScreen(section: section),
                      ),
                    );

                    if (result == true) {
                      // User completed the section or made progress
                      setState(() {
                        // Force re-render to update progress bars
                      });
                    }
                  }
                : null, // Disabilita il clic se non sono stati sbloccati i corsi
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              decoration: ShapeDecoration(
                color: const Color(0xFF181819),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(29),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(section.title, iconAsset),
                  const SizedBox(height: 13),
                  _buildSectionDetails(totalTime, totalVideos, totalQuestions),
                  const SizedBox(height: 13),
                  _buildProgressBar(currentStep, section.steps.length),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Costruisce il titolo della sezione con l'icona accanto
  Widget _buildSectionTitle(String title, String iconAsset) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w800,
              letterSpacing: 0.66,
            ),
          ),
        ),
        SvgPicture.asset(
          iconAsset,
          width: 24,
          height: 24,
        ),
      ],
    );
  }

  /// Costruisce i dettagli della sezione
  Widget _buildSectionDetails(int totalTime, int totalVideos, int totalQuestions) {
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

  /// Costruisce la barra di progresso
  Widget _buildProgressBar(int currentStep, int totalSteps) {
    return Container(
      width: double.infinity,
      height: 6,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: const Color(0xFF434348),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Row(
        children: [
          Container(
            width: currentStep >= totalSteps
                ? MediaQuery.of(context).size.width * 0.9 // Usa la larghezza dinamica
                : (MediaQuery.of(context).size.width * 0.9 * currentStep / totalSteps).clamp(0.0, double.infinity), // Calcola proporzione
            height: 6,
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ],
      ),
    );
  }

  /// Costruisce un elemento con icona e testo
  Widget _buildDetailIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF7D7D7D)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF7D7D7D),
            fontSize: 14,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            letterSpacing: 0.42,
          ),
        ),
      ],
    );
  }
/// Costruisce il pulsante di informazioni (icona "i")
Widget _buildInfoButton() {
  return Positioned(
    top: 30, // Allinea con il back button
    right: 16, // Posiziona sulla destra
    child: GestureDetector(
      onTap: _showCourseDescription,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.info_outline_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    ),
  );
}
  /// Costruisce il pulsante di ritorno
  Widget _buildBackButton() {
    return Positioned(
      top: 30,
      left: 16,
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  /// Costruisce le miniature dei capitoli (se disponibili)
  Widget _buildVideoThumbnails() {
    // Filtra le sezioni che hanno un'immagine
    final List<Section> sectionsWithImages = widget.course.sections
        .where((section) => section.imageUrl != null && section.imageUrl!.isNotEmpty)
        .toList();

    if (sectionsWithImages.isEmpty) {
      return SizedBox.shrink(); // O mostra un placeholder se desiderato
    }

    return Stack(
      children: [
        SizedBox(
          height: 371,
          child: PageView.builder(
            itemCount: sectionsWithImages.length,
            controller: PageController(viewportFraction: 1),
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              return Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(29),
                ),
                child: Image.network(
                  sectionsWithImages[index].imageUrl!,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Mostra la descrizione del corso in una finestra di dialogo
  void _showCourseDescription() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Course Description',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          widget.course.description,
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: Colors.yellowAccent),
            ),
          ),
        ],
      ),
    );
  }

  /// Costruisce gli indicatori di pagina
  Widget _buildPageIndicators() {
    final List<Section> sectionsWithImages = widget.course.sections
        .where((section) => section.imageUrl != null && section.imageUrl!.isNotEmpty)
        .toList();

    if (sectionsWithImages.isEmpty) {
      return SizedBox.shrink(); // O mostra un placeholder se desiderato
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 0), // Usa Padding invece di Positioned
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(sectionsWithImages.length, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            height: 10,
            width: _currentPage == index ? 20 : 10,
            decoration: BoxDecoration(
              color: _currentPage == index ? Colors.white : Colors.white54,
              borderRadius: BorderRadius.circular(5),
            ),
          );
        }),
      ),
    );
  }
}