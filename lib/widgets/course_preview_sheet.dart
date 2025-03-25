import 'package:Just_Learn/main.dart';
import 'package:Just_Learn/models/level.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:Just_Learn/screens/home_screen.dart';
import 'package:flutter/material.dart';
import '../models/course.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:Just_Learn/screens/top_teachers_screen.dart';
import 'package:Just_Learn/screens/profile_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CoursePreviewSheet extends StatefulWidget {
  final Course course;

  const CoursePreviewSheet({
    Key? key,
    required this.course,
  }) : super(key: key);

  // Aggiungiamo una cache statica per i dati del corso
  static final Map<String, Map<String, dynamic>> _courseDataCache = {};

  static Future<void> preload(BuildContext context, Course course) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Verifica se i dati sono già in cache
      if (_courseDataCache.containsKey(course.id)) {
        _preloadedData = _courseDataCache[course.id];
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        final userData = UserModel.fromMap(userDoc.data()!);
        
        // Esegui tutte le query in parallelo
        final futures = await Future.wait([
          course.getStudentsCount(),
          _calculateAllSectionsProgress(course, userData),
        ]);

        final studentsCount = futures[0] as int;
        final sectionProgress = futures[1] as Map<String, Map<String, dynamic>>;
        
        final isPro = userDoc.data()?['isPro'] ?? false;
        
        // Calcola il numero totale di step nel corso
        final totalSteps = course.sections
            .map((s) => s.steps.length)
            .reduce((a, b) => a + b);
        
        // Calcola il punto di blocco (40% del totale)
        final unlockLimit = (totalSteps * 0.4).round();
        
        final cacheData = {
          'userData': userData,
          'studentsCount': studentsCount,
          'sectionProgress': sectionProgress,
          'isPro': isPro,
          'totalSteps': totalSteps,
          'unlockLimit': unlockLimit
        };

        // Salva in cache
        _courseDataCache[course.id] = cacheData;
        _preloadedData = cacheData;
      }
    }
  }

  // Nuovo metodo per calcolare il progresso di tutte le sezioni in una volta
  static Future<Map<String, Map<String, dynamic>>> _calculateAllSectionsProgress(Course course, UserModel userData) async {
    final sectionProgress = <String, Map<String, dynamic>>{};
    var stepCounter = 0;
    final isPro = userData.isPro;
    final isOwner = userData.uid == course.authorId; // Check if user is course owner
    final totalSteps = course.sections
        .map((s) => s.steps.length)
        .reduce((a, b) => a + b);
    final unlockLimit = (totalSteps * 0.4).round();

    // Fetch all assignments for this user in this course
    final assignmentsSnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .doc(course.id)
        .collection('assignments')
        .where('userId', isEqualTo: userData.uid)
        .get();

    // Create a set of completed assignment stepIds
    final completedAssignments = assignmentsSnapshot.docs
        .where((doc) => doc.data()['status'] == 'submitted')
        .map((doc) => doc.data()['stepId'] as String)
        .toSet();

    for (final section in course.sections) {
      int completedSteps = 0;
      List<bool> stepsCompleted = [];
      
      // If user is owner, they have full access
      bool containsLockedSteps = !isOwner && !isPro && stepCounter + section.steps.length > unlockLimit;
      int lockIndex = (isOwner || isPro) ? section.steps.length : (containsLockedSteps ? (unlockLimit - stepCounter).clamp(0, section.steps.length) : section.steps.length);

      for (var i = 0; i < section.steps.length; i++) {
        final step = section.steps[i];
        bool isCompleted = false;
        bool isStepLocked = !isOwner && !isPro && containsLockedSteps && i >= lockIndex;

        if (!isStepLocked) {
          if (step.type == 'video') {
            final videoId = step.videoUrl ?? step.content;
            isCompleted = userData.WatchedVideos[course.topic]?.any(
              (v) => v.videoId == videoId && v.completed
            ) ?? false;
          } else if (step.type == 'question') {
            isCompleted = userData.answeredQuestions[course.topic]?.contains(step.content) ?? false;
          } else if (step.type == 'points') {
            isCompleted = userData.completedPoints.contains(step.content);
          } else if (step.type == 'compito') {
            // Check if this assignment is completed
            isCompleted = completedAssignments.contains(step.content);
          }
        }

        if (isCompleted) completedSteps++;
        stepsCompleted.add(isCompleted);
      }

      stepCounter += section.steps.length;

      sectionProgress[section.title] = {
        'currentStep': completedSteps,
        'totalSteps': section.steps.length,
        'isCompleted': completedSteps == section.steps.length,
        'stepsCompleted': stepsCompleted,
        'lockIndex': lockIndex,
        'containsLockedSteps': containsLockedSteps,
        'stepCounter': stepCounter,
        'unlockLimit': unlockLimit,
        'isPro': isPro,
        'isOwner': isOwner
      };
    }

    return sectionProgress;
  }

  // Variabile statica per i dati pre-caricati
  static Map<String, dynamic>? _preloadedData;

  @override
  State<CoursePreviewSheet> createState() => _CoursePreviewSheetState();
}

class _CoursePreviewSheetState extends State<CoursePreviewSheet> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _buttonController;
  late Animation<double> _scaleAnimation;
  final ValueNotifier<bool> _isExpanded = ValueNotifier<bool>(false);
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0.0);
  final ValueNotifier<String> _startButtonText = ValueNotifier<String>('Start Course');
  final ValueNotifier<bool> _showUnlockOptions = ValueNotifier<bool>(false);
  final ValueNotifier<CourseState> _courseState = ValueNotifier<CourseState>(CourseState.locked);
  
  // Cache per i dati
  final Map<String, Future<Map<String, dynamic>>> _sectionProgressCache = {};
  final ValueNotifier<Map<String, Map<String, dynamic>>> _sectionProgressData = ValueNotifier<Map<String, Map<String, dynamic>>>({});
  final ValueNotifier<UserModel?> _userData = ValueNotifier<UserModel?>(null);
  final ValueNotifier<bool> _isLoadingUserData = ValueNotifier<bool>(true);
  final ValueNotifier<int?> _studentsCount = ValueNotifier<int?>(null);
  final ValueNotifier<bool> _isLoadingStudents = ValueNotifier<bool>(true);
  
  late int _totalDuration;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: Curves.easeInOut,
      ),
    );
    
    _courseState.value = CourseState.locked;
    _checkCourseState();
    
    // Usa i dati pre-caricati se disponibili
    if (CoursePreviewSheet._preloadedData != null) {
      _userData.value = CoursePreviewSheet._preloadedData!['userData'];
      _studentsCount.value = CoursePreviewSheet._preloadedData!['studentsCount'];
      _sectionProgressData.value = CoursePreviewSheet._preloadedData!['sectionProgress'];
      _isLoadingStudents.value = false;
      _isLoadingUserData.value = false;
    } else {
      // Fallback al caricamento normale
      _initializeData();
    }
    
    _totalDuration = widget.course.sections.fold(0, (total, section) {
      int totalVideos = section.steps.where((step) => step.type == 'video').length;
      int totalQuestions = section.steps.where((step) => step.type == 'question').length;
      double totalTime = totalVideos * 1 + totalQuestions * 0.5;
      return total + totalTime.ceil();
    });

    _loadUserData();
    _precacheSectionProgress();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _buttonController.dispose();
    _courseState.dispose();
    _sectionProgressCache.clear();
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

      // If user is the course owner, always grant access
      if (user.uid == widget.course.authorId) {
        _courseState.value = CourseState.unlocked;
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

      // Se il corso è free, è sempre sbloccato
      if (!widget.course.isSubscriptionRequired) {
        _courseState.value = CourseState.unlocked;
        return;
      }

      // Se richiede subscription, controlla se l'utente è abbonato
      final userData = userDoc.data() as Map<String, dynamic>;
      final subscriptions = List<String>.from(userData['subscriptions'] ?? []);
      _courseState.value = subscriptions.contains(widget.course.authorId)
          ? CourseState.unlocked 
          : CourseState.locked;
    } catch (e) {
      _courseState.value = CourseState.error;
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

    if (widget.course.isSubscriptionRequired) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOptionButton(
                icon: Icons.workspace_premium_rounded,
                title: 'Subscribe to ${widget.course.authorName}',
                subtitle: 'Access all premium courses from this creator',
                onTap: () {
                  Navigator.pop(context); // Chiude il bottom sheet
                  Navigator.pop(context); // Torna alla schermata precedente
                  // Qui puoi aggiungere la navigazione alla schermata di subscription
                },
              ),
            ],
          ),
        ),
      );
    } else {
      // Se il corso è free, avvialo direttamente
      _handleStartCourse();
    }
  }

  void _handleStartCourse() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Recupera i dati dell'utente
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userDoc = await userRef.get();
      
      if (!userDoc.exists) return;
      
      final userModel = UserModel.fromMap(userDoc.data()!);
      
      // Trova l'ultimo step completato
      int lastCompletedSectionIndex = 0;
      int lastCompletedStepIndex = 0;
      bool foundLastCompleted = false;

      // Itera attraverso le sezioni e gli step per trovare l'ultimo completato
      for (int sectionIndex = 0; sectionIndex < widget.course.sections.length; sectionIndex++) {
        final section = widget.course.sections[sectionIndex];
        
        for (int stepIndex = 0; stepIndex < section.steps.length; stepIndex++) {
          final step = section.steps[stepIndex];
          bool isCompleted = false;

          if (step.type == 'video') {
            // Controlla se il video è stato completato
            final videoId = step.videoUrl ?? step.content;
            isCompleted = userModel.WatchedVideos[widget.course.topic]?.any(
              (video) => video.videoId.contains(videoId) && video.completed
            ) ?? false;
          } else if (step.type == 'question') {
            // Controlla se la domanda è stata risposta
            isCompleted = userModel.answeredQuestions[widget.course.topic]?.contains(step.content) ?? false;
          } else if (step.type == 'points') {
            // Check if the points step is completed in completedPoints array
            isCompleted = userModel.completedPoints.contains(step.content);
          }

          if (isCompleted) {
            lastCompletedSectionIndex = sectionIndex;
            lastCompletedStepIndex = stepIndex + 1; // Punta al prossimo step
            foundLastCompleted = true;
          }
        }
      }

      // Registra il corso come iniziato se non lo è già
      final startedCourses = List<Map<String, dynamic>>.from(
        userDoc.data()?['startedCourses'] ?? []
      );

      if (!startedCourses.any((course) => course['courseId'] == widget.course.id)) {
        await userRef.update({
          'startedCourses': FieldValue.arrayUnion([
            {
              'courseId': widget.course.id,
              'startDate': Timestamp.now(),
              'completed': false
            }
          ])
        });

        await widget.course.enrollStudent(user.uid);
      }

      // Avvia il corso dall'ultimo punto completato o dall'inizio
      Section targetSection;
      int targetStepIndex;
      bool isResuming = false;

      if (foundLastCompleted && 
          lastCompletedSectionIndex < widget.course.sections.length &&
          lastCompletedStepIndex < widget.course.sections[lastCompletedSectionIndex].steps.length) {
        targetSection = widget.course.sections[lastCompletedSectionIndex];
        targetStepIndex = lastCompletedStepIndex;
        isResuming = true;
      } else {
        targetSection = widget.course.sections.first;
        targetStepIndex = 0;
        isResuming = false;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(
            userModel: userModel,
            initialIndex: 2,
            initialCourseData: {
              'course': widget.course,
              'section': targetSection,
              'stepIndex': targetStepIndex,
              'sectionStepIndex': targetStepIndex,
              'isResuming': isResuming,
            },
          ),
        ),
        (route) => false,
      );

    } catch (e) {
      print('Error starting course: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore nell\'avvio del corso. Riprova.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
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
                ValueListenableBuilder<double>(
                  valueListenable: _scrollOffset,
                  builder: (context, scrollOffset, _) {
                    return Positioned(
                      top: -scrollOffset * 0.5,
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
                        child: Hero(
                          tag: 'course-${widget.course.id}',
                          child: Image.network(
                            widget.course.coverImageUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[900],
                              child: Icon(
                                Icons.school,
                                color: Colors.white.withOpacity(0.2),
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // Contenuto principale
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  _scrollOffset.value = notification.metrics.pixels;
                  return false;
                },
                child: CustomScrollView(
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
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _isLoadingStudents,
                          builder: (context, isLoading, _) {
                            return _buildCourseStats(isLoading);
                          },
                        ),
                      ),
                    ),

                    // Descrizione
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildDescription(),
                      ),
                    ),

                    // Sezioni del corso
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= widget.course.sections.length) return null;
                          return ValueListenableBuilder<Map<String, Map<String, dynamic>>>(
                            valueListenable: _sectionProgressData,
                            builder: (context, progressData, _) {
                              return _buildSectionCard(widget.course.sections[index]);
                            },
                          );
                        },
                      ),
                    ),

                    // Informazioni aggiuntive
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: _buildAdditionalInfo(),
                      ),
                    ),

                    const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                  ],
                ),
              ),

              // Pulsante di chiusura
              Positioned(
                top: 20,
                right: 20,
                child: _buildCloseButton(),
              ),

              // Bottone in fondo
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomButton(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCloseButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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
      child: ValueListenableBuilder<CourseState>(
        valueListenable: _courseState,
        builder: (context, state, _) {
          return _buildStartButton();
        },
      ),
    );
  }

  Widget _buildCourseStats(bool isLoading) {
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
          _buildStat(
            Icons.people_alt_rounded, 
            isLoading ? '...' : '${_studentsCount.value ?? 0}', 
            'Students'
          ),
          _buildVerticalDivider(),
          _buildStat(
            Icons.timer_outlined,
            '$_totalDuration min',
            'Duration',
          ),
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
    final progress = _sectionProgressData.value[section.title];
    
    if (progress == null) {
      return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
    }

    final completedSteps = progress['currentStep'] as int;
    final totalSteps = progress['totalSteps'] as int;
    final isCompleted = progress['isCompleted'] as bool;
    final stepsCompleted = progress['stepsCompleted'] as List<bool>;
    final lockIndex = progress['lockIndex'] as int;
    final containsLockedSteps = progress['containsLockedSteps'] as bool;
    final stepCounter = progress['stepCounter'] as int;
    final unlockLimit = progress['unlockLimit'] as int;
    final isPro = progress['isPro'] as bool;
    final isOwner = progress['isOwner'] as bool;
    final progressValue = totalSteps > 0 ? completedSteps / totalSteps : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? Colors.yellowAccent.withOpacity(0.3) : Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(progressValue * 100).round()}%',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
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
                        '${section.sectionNumber}',
                        style: const TextStyle(
                          color: Colors.yellowAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.clock,
                              size: 10,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_calculateTotalTime(section)} min',
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
              const SizedBox(height: 12),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      backgroundColor: const Color(0xFF2D2D2D),
                      valueColor: AlwaysStoppedAnimation(
                        isCompleted ? Colors.yellowAccent : Colors.yellowAccent.withOpacity(0.7),
                      ),
                      minHeight: 3,
                    ),
                  ),
                  if (isCompleted)
                    const Positioned(
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
              physics: const NeverScrollableScrollPhysics(),
              itemCount: section.steps.length,
              itemBuilder: (context, index) {
                final step = section.steps[index];
                final isStepCompleted = stepsCompleted[index];
                final isLocked = !isOwner && !isPro && containsLockedSteps && index >= lockIndex;
                
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isLocked 
                              ? Colors.grey[800]!.withOpacity(0.15)
                              : (isStepCompleted 
                                  ? Colors.yellowAccent.withOpacity(0.15)
                                  : Colors.grey[800]!.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isLocked 
                              ? Icons.lock
                              : (step.type == 'video' 
                                  ? FontAwesomeIcons.play 
                                  : step.type == 'points'
                                      ? FontAwesomeIcons.listCheck
                                      : step.type == 'question'
                                          ? FontAwesomeIcons.question
                                          : FontAwesomeIcons.circle),
                          color: isLocked 
                              ? Colors.grey[600]
                              : (isStepCompleted 
                                  ? Colors.yellowAccent 
                                  : Colors.white),
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step.content,
                          style: TextStyle(
                            color: isLocked 
                                ? Colors.white.withOpacity(0.3)
                                : (isStepCompleted 
                                    ? Colors.yellowAccent 
                                    : Colors.white),
                            fontSize: 14,
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
                                : (isStepCompleted 
                                    ? Colors.yellowAccent 
                                    : Colors.grey[500]),
                            fontSize: 12,
                          ),
                        ),
                      if (isStepCompleted && !isLocked)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(4),
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
                );
              },
            ),
          ],
        ),
      ),
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

  Future<void> _initializeData() async {
    await Future.wait([
      _loadUserData(),
      _loadStudentsCount(),
      _precacheSectionProgress(),
    ]);
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isLoadingUserData.value = false;
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        _isLoadingUserData.value = false;
        return;
      }

      setState(() {
        _userData.value = UserModel.fromMap(userDoc.data()!);
        _isLoadingUserData.value = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoadingUserData.value = false);
    }
  }

  Future<void> _precacheSectionProgress() async {
    if (_userData.value == null) return;

    final allProgress = await CoursePreviewSheet._calculateAllSectionsProgress(widget.course, _userData.value!);
    
    setState(() {
      _sectionProgressData.value = allProgress;
    });
  }

  @override
  void didUpdateWidget(CoursePreviewSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.course != widget.course) {
      _precacheSectionProgress();
    }
  }

  Widget _buildStartButton() {
    // If the course has a future release date, don't show the button
    if (widget.course.releaseDate != null && widget.course.releaseDate!.isAfter(DateTime.now())) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: Future.wait([
        _isCourseStarted(),
        _checkSubscriptionStatus(),
      ]).then((results) => {
        'isStarted': results[0],
        'isSubscribed': results[1],
      }),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 64); // Placeholder durante il caricamento
        }

        final bool isStarted = snapshot.data!['isStarted'];
        final bool isSubscribed = snapshot.data!['isSubscribed'];

        // Se il corso richiede subscription e l'utente non è iscritto, non mostrare il pulsante
        if (widget.course.isSubscriptionRequired && !isSubscribed) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTapDown: (_) => _buttonController.forward(),
          onTapUp: (_) {
            _buttonController.reverse();
            _handleStartCourse();
          },
          onTapCancel: () => _buttonController.reverse(),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 64,
              decoration: BoxDecoration(
                color: isStarted 
                  ? const Color(0xFFFFFF28).withOpacity(0.15)
                  : const Color(0xFFFFFF28),
                borderRadius: BorderRadius.circular(12),
                border: isStarted 
                  ? Border.all(
                      color: const Color(0xFFFFFF28),
                      width: 2,
                    ) 
                  : null,
              ),
              child: Center(
                child: Text(
                  isStarted ? 'Continue' : 'Start Course',
                  style: TextStyle(
                    color: isStarted ? const Color(0xFFFFFF28) : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _checkSubscriptionStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final subscriptions = List<String>.from(userData['subscriptions'] ?? []);
      return subscriptions.contains(widget.course.authorId);
    } catch (e) {
      print('Error checking subscription status: $e');
      return false;
    }
  }

  Future<bool> _isCourseStarted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return false;

      final startedCourses = List<Map<String, dynamic>>.from(
        userDoc.data()?['startedCourses'] ?? []
      );

      return startedCourses.any((course) => course['courseId'] == widget.course.id);
    } catch (e) {
      print('Error checking if course is started: $e');
      return false;
    }
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

  Future<void> _loadStudentsCount() async {
    if (widget.course == null) return;
    
    try {
      final count = await widget.course!.getStudentsCount();
      if (mounted) {
        setState(() {
          _studentsCount.value = count;
          _isLoadingStudents.value = false;
        });
      }
    } catch (e) {
      print('Error loading students count: $e');
      if (mounted) {
        setState(() {
          _isLoadingStudents.value = false;
        });
      }
    }
  }

  Widget _buildDescription() {
    return Column(
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
    );
  }
}

// Enums e classi di supporto
enum CourseState { loading, locked, unlocked, error }