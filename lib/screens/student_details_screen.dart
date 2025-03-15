import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/course.dart';
import '../models/event.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/notification_service.dart';

class StudentDetailsScreen extends StatefulWidget {
  final UserModel student;

  const StudentDetailsScreen({
    Key? key,
    required this.student,
  }) : super(key: key);

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  bool _isLoading = true;
  List<Course> _completedCourses = [];
  List<Event> _attendedEvents = [];
  Map<String, List<String>> _completedSteps = {};
  List<Map<String, dynamic>> _assignments = [];

  @override
  void initState() {
    super.initState();
    _loadStudentData();
    _loadAssignments();
  }

  Future<void> _loadStudentData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Ottieni l'ID dell'utente corrente (l'insegnante)
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 2. Ottieni tutti i corsi su cui lo studente ha fatto progressi
      final Set<String> courseTopics = widget.student.WatchedVideos.keys.toSet();
      
      // 3. Modifica la query per ottenere solo i corsi creati dall'insegnante corrente
      final coursesSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('topic', whereIn: courseTopics.toList())
          .where('authorId', isEqualTo: currentUser.uid)
          .get();

      _completedCourses = coursesSnapshot.docs
          .map((doc) => Course.fromFirestore(doc))
          .toList();

      // Get completedPoints from student data
      final studentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.student.uid)
          .get();
      
      final studentData = studentDoc.data()!;
      final completedPoints = List<String>.from(studentData['completedPoints'] ?? []);

      // 4. Carica i passi completati solo per i corsi filtrati
      for (var course in _completedCourses) {
        final topic = course.topic;
        final watchedVideos = widget.student.WatchedVideos[topic] ?? [];
        final answeredQuestions = widget.student.answeredQuestions[topic] ?? [];
        
        _completedSteps[topic] = [
          ...watchedVideos
              .where((video) => video.completed)
              .map((video) => video.videoId),
          ...answeredQuestions,
          ...completedPoints,
        ];
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Errore nel caricamento dei dati: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAttendedEvents() async {
    try {
      // Modifichiamo la query per ottenere gli eventi dove l'utente è tra i partecipanti
      final eventsSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('participants', arrayContains: widget.student.uid)
          .get();

      setState(() {
        _attendedEvents = eventsSnapshot.docs
            .map((doc) => Event.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      print('Errore nel caricamento degli eventi: $e');
      setState(() {
        _attendedEvents = [];
      });
    }
  }

  Future<void> _loadAssignments() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Get all courses by the current teacher
      final coursesSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('authorId', isEqualTo: currentUser.uid)
          .get();

      List<Map<String, dynamic>> allAssignments = [];

      // For each course, get the student's assignments
      for (var courseDoc in coursesSnapshot.docs) {
        final assignmentsSnapshot = await courseDoc
            .reference
            .collection('assignments')
            .where('userId', isEqualTo: widget.student.uid)
            .get();

        print('Found ${assignmentsSnapshot.docs.length} assignments for course ${courseDoc.id}'); // Debug print

        for (var assignmentDoc in assignmentsSnapshot.docs) {
          final assignmentData = assignmentDoc.data();
          
          // Get the step data to get the description
          String? description;
          for (var section in (courseDoc.data()['sections'] as List<dynamic>)) {
            for (var step in (section['steps'] as List<dynamic>)) {
              if (step['content'] == assignmentData['stepId']) {
                description = step['explanation'];
                break;
              }
            }
            if (description != null) break;
          }

          allAssignments.add({
            ...assignmentData,
            'courseId': courseDoc.id,
            'courseName': courseDoc.data()['title'],
            'description': description,
          });
        }
      }

      print('Total assignments loaded: ${allAssignments.length}'); // Debug print

      setState(() {
        _assignments = allAssignments;
      });
    } catch (e) {
      print('Error loading assignments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.student.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '@${widget.student.username ?? "username"}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.school_outlined),
                text: 'Courses',
              ),
              Tab(
                icon: Icon(Icons.event_outlined),
                text: 'Events',
              ),
              Tab(
                icon: Icon(Icons.assignment_outlined),
                text: 'Assignments',
              ),
            ],
            indicatorColor: Colors.yellowAccent,
            labelColor: Colors.yellowAccent,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
                ),
              )
            : TabBarView(
                children: [
                  _buildCoursesTab(),
                  _buildEventsTab(),
                  _buildAssignmentsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildCoursesTab() {
    if (_completedCourses.isEmpty) {
      return _buildEmptyState(
        'Nessun corso iniziato',
        Icons.school_outlined,
        'Lo studente non ha ancora iniziato nessun corso',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _completedCourses.length,
      itemBuilder: (context, index) {
        final course = _completedCourses[index];
        
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.student.uid)
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
              ));
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final completedPoints = List<String>.from(userData['completedPoints'] ?? []);
            
            // Calcolo corretto del progresso totale
            int totalSteps = 0;
            int completedStepsCount = 0;
            
            for (var section in course.sections) {
              for (var step in section.steps) {
                totalSteps++;
                if (step.type == 'points') {
                  if (completedPoints.contains(step.content)) {
                    completedStepsCount++;
                  }
                } else if (_completedSteps[course.topic]?.contains(step.videoUrl ?? step.content) ?? false) {
                  completedStepsCount++;
                }
              }
            }
            
            final progress = totalSteps > 0 ? completedStepsCount / totalSteps : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF282828),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (course.coverImageUrl != null)
                    Image.network(
                      course.coverImageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                course.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.yellowAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.yellowAccent),
                              ),
                              child: Text(
                                '${(progress * 100).round()}%',
                                style: const TextStyle(
                                  color: Colors.yellowAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _buildProgressStats(
                          course, 
                          completedStepsCount,
                          totalSteps,
                        ),
                        const SizedBox(height: 16),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation(Colors.yellowAccent),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 16),

                        InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) => _buildCourseDetailsSheet(course, _completedSteps[course.topic] ?? []),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Vedi dettagli progresso',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCourseDetailsSheet(Course course, List<String> completedSteps) {
    // Get completedPoints from user data
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.student.uid)
        .get();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: FutureBuilder<DocumentSnapshot>(
            future: userDoc,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
                ));
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>;
              final completedPoints = List<String>.from(userData['completedPoints'] ?? []);

              // Calcolo del progresso totale
              int totalSteps = 0;
              int completedStepsCount = 0;

              for (var section in course.sections) {
                totalSteps += section.steps.length;
                completedStepsCount += section.steps.where((step) {
                  if (step.type == 'points') {
                    return completedPoints.contains(step.content);
                  }
                  return completedSteps.contains(step.videoUrl ?? step.content);
                }).length;
              }

              final totalProgress = totalSteps > 0 ? completedStepsCount / totalSteps : 0.0;

              return Column(
                children: [
                  // Header con progresso totale
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF282828),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      children: [
                        // Indicatore di drag
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Progresso totale
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    course.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.yellowAccent.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.yellowAccent),
                                  ),
                                  child: Text(
                                    '${(totalProgress * 100).round()}%',
                                    style: const TextStyle(
                                      color: Colors.yellowAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$completedStepsCount di $totalSteps step completati',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Barra progresso totale
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: totalProgress,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                valueColor: const AlwaysStoppedAnimation(Colors.yellowAccent),
                                minHeight: 4,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Lista sezioni
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: course.sections.length,
                      itemBuilder: (context, index) {
                        final section = course.sections[index];
                        final completedInSection = section.steps.where((step) {
                          if (step.type == 'points') {
                            return completedPoints.contains(step.content);
                          }
                          return completedSteps.contains(step.videoUrl ?? step.content);
                        }).length;
                        final sectionProgress = section.steps.isNotEmpty 
                          ? completedInSection / section.steps.length 
                          : 0.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF282828),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              childrenPadding: EdgeInsets.zero,
                              tilePadding: const EdgeInsets.all(16),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: sectionProgress == 1.0
                                            ? Colors.yellowAccent.withOpacity(0.2)
                                            : Colors.white.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          sectionProgress == 1.0
                                            ? Icons.check
                                            : Icons.play_arrow,
                                          color: sectionProgress == 1.0
                                            ? Colors.yellowAccent
                                            : Colors.white70,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              section.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              '$completedInSection di ${section.steps.length} step',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.5),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.yellowAccent.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${(sectionProgress * 100).round()}%',
                                          style: const TextStyle(
                                            color: Colors.yellowAccent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              children: [
                                ...section.steps.map((step) {
                                  final isCompleted = step.type == 'points'
                                    ? completedPoints.contains(step.content)
                                    : completedSteps.contains(step.videoUrl ?? step.content);
                                  return Container(
                                    color: const Color(0xFF1E1E1E),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          margin: const EdgeInsets.only(right: 12),
                                          decoration: BoxDecoration(
                                            color: isCompleted
                                              ? Colors.yellowAccent.withOpacity(0.2)
                                              : Colors.white.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isCompleted
                                              ? Icons.check
                                              : _getStepIcon(step.type),
                                            color: isCompleted
                                              ? Colors.yellowAccent
                                              : Colors.white70,
                                            size: 12,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            step.content ?? 'Step',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.9),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        if (step.type == 'video' && step.duration != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${step.duration} min',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.7),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  IconData _getStepIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.play_circle_outline;
      case 'question':
        return Icons.quiz_outlined;
      case 'points':
        return FontAwesomeIcons.listCheck;
      default:
        return Icons.circle_outlined;
    }
  }

  Widget _buildProgressStats(Course course, int completed, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStat(
          Icons.check_circle_outline,
          '$completed',
          'Step Completati',
        ),
        _buildDivider(),
        _buildStat(
          Icons.list_alt,
          '$total',
          'Step Totali',
        ),
        _buildDivider(),
        _buildStat(
          Icons.access_time,
          '${course.sections.length}',
          'Sezioni',
        ),
      ],
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.yellowAccent,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildEmptyState(String title, IconData icon, [String? subtitle]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    if (_attendedEvents.isEmpty) {
      return _buildEmptyState(
        'Nessun evento frequentato',
        Icons.event_outlined,
        'Lo studente non ha ancora partecipato a nessun evento',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _attendedEvents.length,
      itemBuilder: (context, index) {
        final event = _attendedEvents[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF282828),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: ListTile(
            title: Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              event.description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            trailing: Text(
              _formatDate(event.startDate),
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<Map<String, dynamic>> _getSectionProgress(Course course) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'progress': 0.0, 'remainingMinutes': 0};

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) return {'progress': 0.0, 'remainingMinutes': 0};

    final userData = userDoc.data()!;
    final userModel = UserModel.fromMap(userData);
    
    // Get completedPoints from userData
    final completedPoints = List<String>.from(userData['completedPoints'] ?? []);
    
    int totalSteps = 0;
    int completedSteps = 0;
    int totalDuration = 0;

    // Calcola per tutte le sezioni
    for (var section in course.sections) {
      for (var step in section.steps) {
        totalSteps++;
        totalDuration += step.duration ?? (step.type == 'video' ? 1 : 0);

        if (step.type == 'video') {
          final videoId = step.videoUrl ?? step.content;
          final watchedVideos = userModel.WatchedVideos[course.topic] ?? [];
          if (watchedVideos.any((v) => v.videoId == videoId && v.completed)) {
            completedSteps++;
          }
        } else if (step.type == 'question') {
          final answeredQuestions = userModel.answeredQuestions[course.topic] ?? [];
          if (answeredQuestions.contains(step.content)) {
            completedSteps++;
          }
        } else if (step.type == 'points') {
          if (completedPoints.contains(step.content)) {
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

  Widget _buildAssignmentsTab() {
    if (_assignments.isEmpty) {
      return _buildEmptyState(
        'No assignments submitted',
        Icons.assignment_outlined,
        'This student hasn\'t submitted any assignments yet',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _assignments.length,
      itemBuilder: (context, index) {
        final assignment = _assignments[index];
        final submissionDate = (assignment['submissionDate'] as Timestamp).toDate();
        final fileSize = assignment['fileSize'] as int;
        final fileSizeInMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF282828),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(
                  assignment['courseName'] ?? 'Unknown Course',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Step: ${assignment['stepId']}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (String status) async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('courses')
                          .doc(assignment['courseId'])
                          .collection('assignments')
                          .doc(widget.student.uid)
                          .update({'status': status});

                      // Update local state
                      setState(() {
                        _assignments[index]['status'] = status;
                      });
                    } catch (e) {
                      print('Error updating status: $e');
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'completed',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Completed', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'reviewing',
                      child: Row(
                        children: [
                          Icon(Icons.pending, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('In Review', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'pending',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('To Review', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(assignment['status']).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(assignment['status'])),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(assignment['status']),
                          color: _getStatusColor(assignment['status']),
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _getStatusText(assignment['status']),
                          style: TextStyle(
                            color: _getStatusColor(assignment['status']),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Divider(color: Colors.white.withOpacity(0.1)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getFileIcon(assignment['fileType']),
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            assignment['fileName'] ?? 'Unknown file',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          '$fileSizeInMB MB',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Submitted on ${_formatDate(submissionDate)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              launch(assignment['fileUrl']);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellowAccent.withOpacity(0.2),
                              foregroundColor: Colors.yellowAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.yellowAccent),
                              ),
                            ),
                            icon: const Icon(Icons.visibility_outlined),
                            label: const Text('View Submission'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                backgroundColor: const Color(0xFF282828),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Assignment Description',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        assignment['description'] ?? 'No description available',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      ),
                                      SizedBox(height: 24),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text(
                                            'Close',
                                            style: TextStyle(
                                              color: Colors.yellowAccent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            padding: const EdgeInsets.all(12),
                          ),
                          icon: Icon(
                            Icons.description_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            _showCommentDialog(assignment);
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            padding: const EdgeInsets.all(12),
                          ),
                          icon: Icon(
                            Icons.comment_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCommentDialog(Map<String, dynamic> assignment) {
    final TextEditingController commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF282828),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Comment',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: commentController,
                style: TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write your feedback...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.yellowAccent),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (commentController.text.trim().isEmpty) return;
                      
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser == null) return;

                      try {
                        // Get teacher's name
                        final teacherDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUser.uid)
                            .get();
                        final teacherName = teacherDoc.data()?['name'] ?? 'Teacher';

                        // Create chat message
                        final chatId = _getChatId(currentUser.uid, widget.student.uid);
                        final messageRef = FirebaseFirestore.instance
                            .collection('chats')
                            .doc(chatId)
                            .collection('messages')
                            .doc();

                        final message = {
                          'id': messageRef.id,
                          'message': commentController.text,
                          'timestamp': FieldValue.serverTimestamp(),
                          'senderId': currentUser.uid,
                          'receiverId': widget.student.uid,
                          'type': 'assignment_comment',
                          'assignmentId': assignment['assignmentId'],
                          'courseId': assignment['courseId'],
                        };

                        // Update or create chat document
                        await FirebaseFirestore.instance
                            .collection('chats')
                            .doc(chatId)
                            .set({
                          'participants': [currentUser.uid, widget.student.uid],
                          'lastMessage': commentController.text,
                          'lastMessageTimestamp': FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true));

                        // Save the message
                        await messageRef.set(message);

                        // Create notification
                        final notification = {
                          'id': DateTime.now().millisecondsSinceEpoch.toString(),
                          'message': 'New feedback on your assignment',
                          'timestamp': DateTime.now().toIso8601String(),
                          'isRead': false,
                          'isFromTeacher': true,
                          'senderId': currentUser.uid,
                          'type': 'teacherMessage',
                          'assignmentId': assignment['assignmentId'],
                          'courseId': assignment['courseId'],
                        };

                        // Add notification to student's notifications
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.student.uid)
                            .update({
                          'notifications': FieldValue.arrayUnion([notification])
                        });

                        // Send push notification if FCM token exists
                        final studentDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.student.uid)
                            .get();
                        
                        final fcmToken = studentDoc.data()?['fcmToken'];
                        if (fcmToken != null) {
                          final notificationService = NotificationService();
                          await notificationService.sendSpecificNotification(
                            fcmToken,
                            'assignment_feedback',
                            teacherName
                          );
                        }

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Comment sent successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        print('Error sending comment: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error sending comment'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellowAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Send'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getChatId(String currentUserId, String otherUserId) {
    final List<String> ids = [currentUserId, otherUserId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'reviewing':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.yellowAccent;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'reviewing':
        return Icons.pending;
      case 'pending':
        return Icons.visibility;
      default:
        return Icons.assignment_turned_in;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return 'COMPLETED';
      case 'reviewing':
        return 'REVIEWING';
      case 'pending':
        return 'TO REVIEW';
      default:
        return 'SUBMITTED';
    }
  }

  IconData _getFileIcon(String? fileType) {
    if (fileType == null) return Icons.insert_drive_file_outlined;
    switch (fileType.toLowerCase()) {
      case '.pdf':
        return Icons.picture_as_pdf_outlined;
      case '.jpg':
      case '.jpeg':
      case '.png':
        return Icons.image_outlined;
      case '.mp4':
        return Icons.video_library_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }
} 