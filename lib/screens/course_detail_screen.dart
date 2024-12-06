// lib/screens/course_detail_screen.dart


import 'package:Just_Learn/screens/course_info_dialog.dart';
import 'package:Just_Learn/screens/subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import '../models/course.dart';
import 'level_screen.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:flutter/services.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  final UserModel user;

  const CourseDetailScreen({super.key, required this.course, required this.user});

  @override
  _CourseDetailScreenState createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> with SingleTickerProviderStateMixin {
  bool _isCourseUnlocked = false;
  int _currentPage = 0;
  late UserModel _currentUser;

  // Aggiungi controller per l'animazione
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Aggiungi queste variabili
  double _userRating = 0;
  bool _hasRated = false;
  bool _isRatingExpanded = false;
  late Animation<double> _ratingAnimation;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _isCourseUnlocked = _currentUser.unlockedCourses.contains(widget.course.id);
    
    // Inizializza l'animazione
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut)
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
    
    // Traccia la visualizzazione della schermata dettaglio corso
    Posthog().screen(
      screenName: 'Course Detail Screen',
      properties: {
        'course_id': widget.course.id,
        'course_title': widget.course.title,
        'course_topic': widget.course.topic,
        'is_unlocked': _isCourseUnlocked,
      },
    );
    
    _ratingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.3, 0.8, curve: Curves.elasticOut),
      ),
    );
    
    _expandAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    
    _checkUserRating();
  }

  Future<void> _checkUserRating() async {
    final ratingDoc = await FirebaseFirestore.instance
        .collection('courseRatings')
        .doc('${widget.course.id}_${_currentUser.uid}')
        .get();
        
    if (ratingDoc.exists) {
      setState(() {
        _userRating = ratingDoc.data()?['rating'] ?? 0;
        _hasRated = true;
      });
    }
  }

  Future<void> _submitRating(double rating) async {
    try {
      await FirebaseFirestore.instance
          .collection('courseRatings')
          .doc('${widget.course.id}_${_currentUser.uid}')
          .set({
        'courseId': widget.course.id,
        'userId': _currentUser.uid,
        'rating': rating,
        'timestamp': FieldValue.serverTimestamp(),
      });

      final courseRef = FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.course.id);
          
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final courseDoc = await transaction.get(courseRef);
        final currentRating = courseDoc.data()?['rating'] ?? 0.0;
        final currentTotalRatings = courseDoc.data()?['totalRatings'] ?? 0;
        
        final newTotalRatings = _hasRated ? currentTotalRatings : currentTotalRatings + 1;
        final newRating = ((currentRating * currentTotalRatings) + (rating - _userRating)) / newTotalRatings;
        
        transaction.update(courseRef, {
          'rating': newRating,
          'totalRatings': newTotalRatings,
        });
      });

      setState(() {
        _userRating = rating;
        _hasRated = true;
        _isRatingExpanded = false;
      });
      
      HapticFeedback.lightImpact();
      
    } catch (e) {
      setState(() => _isRatingExpanded = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Verifica se tutte le sezioni precedenti sono completate
  bool _arePreviousSectionsCompleted(int currentIndex) {
    for (int i = 0; i < currentIndex; i++) {
      String previousSectionTitle = widget.course.sections[i].title;
      int currentStep = _getCurrentStepForSection(previousSectionTitle);
      int totalSteps = widget.course.sections[i].steps.length;
      if (currentStep < totalSteps) {
        return false;
      }
    }
    return true;
  }

  // Funzione per ricaricare i dati utente da Firestore
  Future<void> _reloadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userSnapshot.exists) {
        setState(() {
          _currentUser = UserModel.fromMap(userSnapshot.data()!);
          _isCourseUnlocked = _currentUser.unlockedCourses.contains(widget.course.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _isCourseUnlocked = _currentUser.unlockedCourses.contains(widget.course.id);

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
                  _buildSections(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          if (!_isCourseUnlocked) _buildBottomButtons(),
          _buildBackButton(),
          _buildInfoButton(),
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
          // Traccia il click sul pulsante subscribe
          Posthog().capture(
            eventName: 'subscription_button_clicked',
            properties: {
              'from_course_id': widget.course.id,
              'from_course_title': widget.course.title,
            },
          );
          
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
            const Icon(Icons.stars_rounded, color: Colors.yellowAccent, size: 25),
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
    if (_currentUser.coins >= widget.course.cost) {
      // Traccia lo sblocco del corso con coins
      Posthog().capture(
        eventName: 'course_unlocked_with_coins',
        properties: {
          'course_id': widget.course.id,
          'course_title': widget.course.title,
          'cost': widget.course.cost,
          'user_remaining_coins': _currentUser.coins - widget.course.cost,
        },
      );
      
      int newCoins = _currentUser.coins - widget.course.cost;
      List<String> newUnlockedCourses = List.from(_currentUser.unlockedCourses)..add(widget.course.id);

      setState(() {
        _currentUser.coins = newCoins;
        _currentUser.unlockedCourses = newUnlockedCourses;
        _isCourseUnlocked = true;
      });

      await FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).update({
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
    
  }

  /// Funzione per ottenere il currentStep per una sezione
  int _getCurrentStepForSection(String sectionTitle) {
    return _currentUser.currentSteps[sectionTitle] ?? 0; // Se non c'è progresso, restituisce 0
  }

  /// Funzione per calcolare il tempo totale per completare una sezione
  int _calculateTotalTime(Section section) {
    int totalVideos = section.steps.where((step) => step.type == 'video').length;
    int totalQuestions = section.steps.where((step) => step.type == 'question').length;

    double totalTime = totalVideos * 1 + totalQuestions * 0.5;
    return totalTime.ceil(); // Arrotonda per eccesso
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
              fontSize: 18,
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
/// Costruisce la barra di progresso
Widget _buildProgressBar(int currentStep, int totalSteps) {
  bool isCompleted = currentStep >= totalSteps; // Determina se la sezione è completata

  return Container(
    width: double.infinity,
    height: 6,
    clipBehavior: Clip.antiAlias,
    decoration: ShapeDecoration(
      color: const Color(0xFF434348),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    child: FractionallySizedBox(
      widthFactor: currentStep / totalSteps, // Proporzione basata sugli step completati
      alignment: Alignment.centerLeft,
      child: Container(
        height: 6,
        decoration: ShapeDecoration(
          color: isCompleted ? Colors.yellowAccent : Colors.white, // Colore dinamico
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
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
      top: 30,
      right: 16,
      child: Stack(
        children: [
          // Container per gestire il tap fuori dall'area di rating
          if (_isRatingExpanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() => _isRatingExpanded = false);
                },
                child: Container(
                  color: Colors.transparent,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                ),
              ),
            ),
          Row(
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    height: _isRatingExpanded ? 250 : 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(23),
                    ),
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        // Stelle animate
                        AnimatedOpacity(
                          duration: Duration(milliseconds: 200),
                          opacity: _isRatingExpanded ? 1.0 : 0.0,
                          child: GestureDetector(
                            onVerticalDragUpdate: (details) {
                              final RenderBox box = context.findRenderObject() as RenderBox;
                              final pos = box.globalToLocal(details.globalPosition);
                              final rating = 5 - ((pos.dy - 50) / 40).clamp(0, 4).floor();
                              if (rating != _userRating) {
                                setState(() => _userRating = rating.toDouble());
                                HapticFeedback.selectionClick();
                              }
                            },
                            onVerticalDragEnd: (_) => _submitRating(_userRating),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return AnimatedScale(
                                  duration: Duration(milliseconds: 200),
                                  scale: 5 - index <= _userRating ? 1.2 : 1.0,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Icon(
                                      5 - index <= _userRating 
                                        ? Icons.star_rounded 
                                        : Icons.star_outline_rounded,
                                      color: 5 - index <= _userRating 
                                        ? Colors.yellowAccent 
                                        : Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                        // Icona stella principale
                        if (!_isRatingExpanded)
                          GestureDetector(
                            onTap: () {
                              setState(() => _isRatingExpanded = true);
                              HapticFeedback.lightImpact();
                            },
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  _hasRated 
                                    ? Icons.star_rounded 
                                    : Icons.star_outline_rounded,
                                  color: _hasRated 
                                    ? Colors.yellowAccent 
                                    : Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(width: 8),
              GestureDetector(
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
            ],
          ),
        ],
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
          // Traccia il click sul pulsante back
          Posthog().capture(
            eventName: 'course_detail_back_clicked',
            properties: {
              'course_id': widget.course.id,
              'course_title': widget.course.title,
            },
          );
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
    final List<Section> sectionsWithImages = widget.course.sections
        .where((section) => section.imageUrl != null && section.imageUrl!.isNotEmpty)
        .toList();

    if (sectionsWithImages.isEmpty) {
      return SizedBox.shrink();
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
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: _buildPageIndicators(),
        ),
      ],
    );
  }

  /// Mostra la descrizione del corso in una finestra di dialogo
  void _showCourseDescription() {
    // Traccia il click sul pulsante info
    Posthog().capture(
      eventName: 'course_info_clicked',
      properties: {
        'course_id': widget.course.id,
        'course_title': widget.course.title,
      },
    );
    
    showDialog(
      context: context,
      builder: (context) => CourseInfoDialog(course: widget.course),
    );
  }

  /// Costruisce gli indicatori di pagina
  Widget _buildPageIndicators() {
    final List<Section> sectionsWithImages = widget.course.sections
        .where((section) => section.imageUrl != null && section.imageUrl!.isNotEmpty)
        .toList();

    if (sectionsWithImages.isEmpty) {
      return SizedBox.shrink();
    }

    return Row(
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
    );
  }

  /// Costruisce le barre di progresso delle sezioni
/// Costruisce le barre di progresso delle sezioni
Widget _buildSections() {
  return AnimatedBuilder(
    animation: _animationController,
    builder: (context, child) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: widget.course.sections.asMap().entries.map((entry) {
              int index = entry.key;
              Section section = entry.value;

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

              // Determina se la sezione è accessibile
              bool isFirstSection = index == 0;
              bool hasPurchased = _isCourseUnlocked;
              bool hasCompletedPrevious = _arePreviousSectionsCompleted(index);
              bool isAccessible = isFirstSection || (hasPurchased && hasCompletedPrevious);

              return TweenAnimationBuilder(
                duration: Duration(milliseconds: 300 + (index * 100)),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: GestureDetector(
                        onTap: isAccessible ? () async {
                          // Traccia il click sulla sezione
                          Posthog().capture(
                            eventName: 'section_clicked',
                            properties: {
                              'course_id': widget.course.id,
                              'course_title': widget.course.title,
                              'section_title': section.title,
                              'section_index': index,
                              'is_completed': isCompleted,
                            },
                          );
                          
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LevelScreen(section: section),
                            ),
                          );

                          // Sempre ricaricare i dati utente dopo il ritorno
                          await _reloadUserData();
                          setState(() {
                            // Forza il re-render per aggiornare le barre di progresso
                          });
                        } : null,
                        child: Container(
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
                                    _buildSectionDetails(totalTime, totalVideos, totalQuestions),
                                    SizedBox(height: 15),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: _buildProgressBar(currentStep, section.steps.length),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isAccessible)
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                                      child: Container(
                                        color: Colors.black.withOpacity(0.5),
                                        child: Center(
                                          child: Icon(
                                            Icons.lock_outline_rounded,
                                            color: Colors.white70,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      );
    },
  );
}
}