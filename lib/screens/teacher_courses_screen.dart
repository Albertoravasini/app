import 'package:flutter/material.dart';
import '../models/course.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/course_preview_sheet.dart';
import '../screens/course_stats_screen.dart';

class TeacherCoursesScreen extends StatefulWidget {
  final String teacherId;
  final List<Course> courses;

  const TeacherCoursesScreen({
    Key? key,
    required this.teacherId,
    required this.courses,
  }) : super(key: key);

  @override
  State<TeacherCoursesScreen> createState() => _TeacherCoursesScreenState();
}

class _TeacherCoursesScreenState extends State<TeacherCoursesScreen> {
  Map<String, Map<String, dynamic>> _courseStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCoursesStats();
  }

  Future<void> _loadCoursesStats() async {
    setState(() => _isLoading = true);

    try {
      for (var course in widget.courses) {
        final stats = await _getCourseStats(course.id);
        _courseStats[course.id] = stats;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Errore nel caricamento delle statistiche: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _getCourseStats(String courseId) async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      
      int totalStudents = 0;
      int totalStepsCompleted = 0;

      final course = widget.courses.firstWhere((c) => c.id == courseId);

      // Controlla ogni utente
      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        
        // Controlla startedCourses
        final startedCourses = List<Map<String, dynamic>>.from(
          userData['startedCourses'] ?? []
        );
        
        if (startedCourses.any((c) => c['courseId'] == courseId)) {
          totalStudents++;
          
          // Ottieni i video guardati e le domande risposte
          final watchedVideos = List<Map<String, dynamic>>.from(
            (userData['WatchedVideos'] ?? {})[course.topic] ?? []
          );
          final answeredQuestions = List<String>.from(
            (userData['answeredQuestions'] ?? {})[course.topic] ?? []
          );
          
          // Conta gli step completati per questo studente
          int completedStepsCount = 0;
          
          for (var section in course.sections) {
            for (var step in section.steps) {
              if (step.videoUrl != null) {
                // Controlla se il video è stato completato
                if (watchedVideos.any((v) => 
                    v['videoId'] == step.videoUrl && v['completed'] == true)) {
                  completedStepsCount++;
                }
              } else if (step.content != null) {
                // Controlla se la domanda è stata risposta
                if (answeredQuestions.contains(step.content)) {
                  completedStepsCount++;
                }
              }
            }
          }
          
          totalStepsCompleted += completedStepsCount;
        }
      }

      return {
        'totalStudents': totalStudents,
        'totalStepsCompleted': totalStepsCompleted,
      };
    } catch (e) {
      print('Error getting course stats: $e');
      return {
        'totalStudents': 0,
        'totalStepsCompleted': 0,
      };
    }
  }

  Widget _buildCourseCard(Course course) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
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
      child: Stack(
        children: [
          // Immagine di copertina
          Positioned.fill(
            child: course.coverImageUrl != null
              ? Image.network(
                  course.coverImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[800],
                    child: Icon(
                      Icons.school,
                      color: Colors.white.withOpacity(0.3),
                      size: 48,
                    ),
                  ),
                )
              : Container(
                  color: Colors.grey[800],
                  child: Icon(
                    Icons.school,
                    color: Colors.white.withOpacity(0.3),
                    size: 48,
                  ),
                ),
          ),
          // Gradiente scuro
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.95),
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
          // Contenuto
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseStatsScreen(course: course),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 160),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        course.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<Map<String, dynamic>>(
                        future: _getCourseStats(course.id),
                        builder: (context, snapshot) {
                          final stats = snapshot.data ?? {
                            'totalStudents': 0,
                            'totalStepsCompleted': 0,
                          };
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStat(
                                Icons.people_outline,
                                '${stats['totalStudents']}',
                                'Studenti',
                              ),
                              _buildDivider(),
                              _buildStat(
                                Icons.check_circle_outline,
                                '${stats['totalStepsCompleted']}',
                                'Step Completati',
                              ),
                              _buildDivider(),
                              _buildStat(
                                Icons.timer_outlined,
                                '${_calculateTotalDuration(course)} min',
                                'Durata',
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('I Miei Corsi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.courses.length,
              itemBuilder: (context, index) {
                final course = widget.courses[index];
                return _buildCourseCard(course);
              },
            ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.yellowAccent),
        const SizedBox(height: 8),
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
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.white10,
    );
  }

  double _calculateTotalDuration(Course course) {
    // Implementa la logica per calcolare la durata totale del corso
    // Questo è un esempio di implementazione
    return 0.0;
  }
} 