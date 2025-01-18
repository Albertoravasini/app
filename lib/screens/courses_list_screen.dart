import 'package:Just_Learn/models/user.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/course.dart';
import '../services/course_service.dart';
import '../widgets/course_preview_sheet.dart';

class CoursesListScreen extends StatefulWidget {
  const CoursesListScreen({Key? key}) : super(key: key);

  @override
  _CoursesListScreenState createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends State<CoursesListScreen> {
  final CourseService _courseService = CourseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Tutti i corsi
  List<Course> _allCourses = [];
  bool _isLoadingCourses = true;

  // Corsi iniziati dall'utente
  List<Course> _userStartedCourses = [];
  bool _isLoadingUser = true;

  // Ultimo corso iniziato
  Course? _lastCourseStarted;

  // Controllo ricerca
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Aggiungi questa variabile di stato
  Map<String, List<String>> _watchedVideos = {};

  @override
  void initState() {
    super.initState();
    _loadAllCourses();
    _loadUserStartedCourses();
    _loadWatchedVideos();
  }

  // Carica tutti i corsi visibili
  Future<void> _loadAllCourses() async {
    try {
      final courses = await _courseService.getVisibleCourses();
      setState(() {
        _allCourses = courses;
        _isLoadingCourses = false;
      });
    } catch (e) {
      print('Errore nel caricamento dei corsi: $e');
      setState(() => _isLoadingCourses = false);
    }
  }

  // Carica i dati utente per corsi iniziati
  Future<void> _loadUserStartedCourses() async {
    final user = _auth.currentUser;
    if (user == null) {
      // Nessun utente loggato
      setState(() => _isLoadingUser = false);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        setState(() => _isLoadingUser = false);
        return;
      }

      final userData = userDoc.data()!;
      final startedCoursesRaw = userData['startedCourses'] as List<dynamic>? ?? [];

      // Ordina i startedCourses per data di inizio discendente
      startedCoursesRaw.sort((a, b) {
        final dateA = (a['startDate'] as Timestamp).toDate();
        final dateB = (b['startDate'] as Timestamp).toDate();
        return dateB.compareTo(dateA);
      });

      // Id del corso più recente
      String? lastCourseId;
      if (startedCoursesRaw.isNotEmpty) {
        lastCourseId = startedCoursesRaw.first['courseId'];
      }

      // Id dei corsi iniziati
      final startedCoursesIds = startedCoursesRaw
          .map((map) => (map as Map<String, dynamic>)['courseId'] as String)
          .toList();

      // Query su Firestore (solo se ci sono corsi)
      if (startedCoursesIds.isNotEmpty) {
        final snapshot = await FirebaseFirestore.instance
            .collection('courses')
            .where(FieldPath.documentId, whereIn: startedCoursesIds)
            .get();

        final userCourses = snapshot.docs
            .map((doc) => Course.fromFirestore(doc))
            .toList();

        setState(() {
          _userStartedCourses = userCourses;
          _lastCourseStarted = userCourses.firstWhere(
            (c) => c.id == lastCourseId,
            orElse: () => userCourses.first,
          );
          _isLoadingUser = false;
        });
      } else {
        // Nessun corso iniziato
        setState(() => _isLoadingUser = false);
      }
    } catch (e) {
      print('Errore caricando i corsi iniziati: $e');
      setState(() => _isLoadingUser = false);
    }
  }

  // Aggiungi questo metodo
  Future<void> _loadWatchedVideos() async {
    if (_auth.currentUser?.uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      setState(() {
        _watchedVideos = Map<String, List<String>>.from(
          (doc.data()?['WatchedVideos'] ?? {}).map((key, value) => 
            MapEntry(key, 
              (value as List).where((v) => v['completed'] == true)
                           .map((v) => v['videoId'].toString())
                           .toList()
            )
          )
        );
      });
    }
  }

  // Restituisce i corsi raggruppati per topic, filtrati dal search
  Map<String, List<Course>> _getCoursesByTopic() {
    final Map<String, List<Course>> categorizedCourses = {};

    // Piccolo filtro in base alla search query
    final filtered = _allCourses.where((course) {
      final query = _searchQuery.toLowerCase();
      return course.title.toLowerCase().contains(query) ||
             course.description.toLowerCase().contains(query) ||
             course.topic.toLowerCase().contains(query);
    }).toList();

    for (var course in filtered) {
      final topic = course.topic.isNotEmpty ? course.topic : 'Other';
      if (!categorizedCourses.containsKey(topic)) {
        categorizedCourses[topic] = [];
      }
      categorizedCourses[topic]!.add(course);
    }
    return categorizedCourses;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isLoadingCourses || _isLoadingUser;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
              ),
            )
          : CustomScrollView(
              slivers: [
                // AppBar con comportamento floating
                SliverAppBar(
                  floating: true, // Scompare/riappare con lo scroll
                  snap: true,     // Snap animation quando riappare
                  pinned: false,  // Non rimane visibile
                  backgroundColor: const Color(0xFF121212),
                  toolbarHeight: 80,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.all(16),
                    title: _buildSearchField(),
                  ),
                ),

                // 1) Ultimo corso iniziato
                if (_lastCourseStarted != null)
                  SliverToBoxAdapter(
                    child: _buildLastCourse(_lastCourseStarted!),
                  ),

                // 2) Corsi iniziati
                if (_userStartedCourses.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildStartedCoursesSection(),
                  ),

                // 3) Corsi divisi per topic (filtrati)
                ..._buildTopicSections(),
              ],
            ),
    );
  }

  /// SearchField con bordi arrotondati e icona
  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.only(right: 16), // per allinearlo bene
      child: Material(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(24),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.yellowAccent,
          decoration: InputDecoration(
            hintText: 'Search courses...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            prefixIcon: const Icon(Icons.search, color: Colors.yellowAccent),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
    );
  }

  /// Card di "ultimo corso iniziato"
  Widget _buildLastCourse(Course course) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getSectionProgress(course),
      builder: (context, snapshot) {
        final progress = snapshot.data?['progress'] ?? 0.0;
        final remainingMinutes = snapshot.data?['remainingMinutes'] ?? 0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Stack(
            children: [
              // Sfondo con immagine
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Hero(
                  tag: 'lastCourse-${course.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      course.coverImageUrl ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[800],
                        child: Icon(
                          Icons.school,
                          color: Colors.white.withOpacity(0.3),
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Gradiente sfumato
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Testi e bottone
              Positioned(
                left: 20,
                right: 20,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.yellowAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Continue your last course',
                        style: TextStyle(
                          color: Colors.yellowAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Titolo
                    Text(
                      course.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Descrizione
                    Text(
                      course.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),

                    // Progress info e barra
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(progress * 100).round()}% completato',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '$remainingMinutes min rimanenti',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        color: Colors.yellowAccent,
                        backgroundColor: Colors.white12,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),

              // Gesture
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => _showCoursePreview(course),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getSectionProgress(Course course) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'progress': 0.0, 'remainingMinutes': 0};

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) return {'progress': 0.0, 'remainingMinutes': 0};

    final userData = UserModel.fromMap(userDoc.data()!);
    
    int totalSteps = 0;
    int completedSteps = 0;
    int totalDuration = 0;

    // Calcola per tutte le sezioni
    for (var section in course.sections) {
      for (var step in section.steps) {
        totalSteps++;
        totalDuration += step.type == 'video' ? 1 : 0;  // 1 minuto per video

        if (step.type == 'video') {
          final videoId = step.videoUrl ?? step.content;
          final watchedVideos = userData.WatchedVideos[course.topic] ?? [];
          if (watchedVideos.any((v) => v.videoId == videoId && v.completed)) {
            completedSteps++;
          }
        } else if (step.type == 'question') {
          final answeredQuestions = userData.answeredQuestions[course.topic] ?? [];
          if (answeredQuestions.contains(step.content)) {
            completedSteps++;
          }
        }
      }
    }

    final progress = totalSteps > 0 ? completedSteps / totalSteps : 0.0;
    final remainingMinutes = (totalDuration * (1 - progress)).round();

    return {
      'progress': progress,
      'remainingMinutes': remainingMinutes
    };
  }

  /// Sezione con i corsi iniziati (meno l'ultimo)
  Widget _buildStartedCoursesSection() {
    final List<Course> otherStarted = [..._userStartedCourses];
    if (_lastCourseStarted != null) {
      otherStarted.removeWhere((c) => c.id == _lastCourseStarted!.id);
    }
    if (otherStarted.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titolo
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Continue your courses',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Scroll orizzontale
        SizedBox(
          height: 300,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: otherStarted.length,
            itemBuilder: (context, index) {
              final course = otherStarted[index];
              return _buildCourseCard(course);
            },
          ),
        ),
      ],
    );
  }

  /// Costruisce le sezioni dei corsi divisi per topic
  List<Widget> _buildTopicSections() {
    final categorizedCourses = _getCoursesByTopic();
    if (categorizedCourses.isEmpty) {
      // Se la ricerca filtra troppo
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                'No courses found',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ];
    }

    return categorizedCourses.entries.map((entry) {
      final topic = entry.key;
      final courses = entry.value;

      return SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titolo del topic
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                topic,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Lista orizzontale
            SizedBox(
              height: 300,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  return _buildCourseCard(courses[index]);
                },
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// Card generica per un corso, con qualche tocco di UI e ombre
  Widget _buildCourseCard(Course course) {
    // Calcolo del progresso e durata
    int totalSteps = 0;
    int completedStepsCount = 0;
    int totalDuration = _calculateTotalDuration(course);
    
    for (var section in course.sections) {
      for (var step in section.steps) {
        totalSteps++;
        if (_userStartedCourses.contains(course) && 
            (_watchedVideos[course.topic] ?? [])
              .contains(step.videoUrl ?? step.content)) {
          completedStepsCount++;
        }
      }
    }
    
    final progress = totalSteps > 0 ? completedStepsCount / totalSteps : 0.0;
    final remainingMinutes = (totalDuration * (1 - progress)).round();

    return Container(
      width: 260,
      height: _userStartedCourses.contains(course) ? 300 : 260,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showCoursePreview(course),
        child: Card(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: Colors.black45,
          child: Column(
            children: [
              // Immagine con rating sovrapposto
              Stack(
                children: [
                  SizedBox(
                    height: 140,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Hero(
                        tag: 'course-${course.id}',
                        child: Image.network(
                          course.coverImageUrl ?? '',
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[800],
                            child: Icon(
                              Icons.school,
                              color: Colors.white.withOpacity(0.3),
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Rating overlay
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.yellowAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            course.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Contenuto
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          course.description,
                          maxLines: _userStartedCourses.contains(course) ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (_userStartedCourses.contains(course)) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${(progress * 100).round()}% completato',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              '$remainingMinutes min rimanenti',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation(Colors.yellowAccent),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCoursePreview(Course course) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CoursePreviewSheet(course: course),
    );
  }

  int _calculateTotalDuration(Course course) {
    return course.sections.fold(0, (total, section) {
      int totalVideos = section.steps.where((step) => step.type == 'video').length;
      int totalQuestions = section.steps.where((step) => step.type == 'question').length;
      double totalTime = totalVideos * 1 + totalQuestions * 0.5;
      return total + totalTime.ceil();
    });
  }
}