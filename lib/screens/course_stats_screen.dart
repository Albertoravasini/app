import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CourseStatsScreen extends StatefulWidget {
  final Course course;

  const CourseStatsScreen({
    Key? key,
    required this.course,
  }) : super(key: key);

  @override
  State<CourseStatsScreen> createState() => _CourseStatsScreenState();
}

class _CourseStatsScreenState extends State<CourseStatsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  int _totalStudents = 0;
  int _totalCompletedSteps = 0;

  @override
  void initState() {
    super.initState();
    _loadCourseStats();
  }

  Future<void> _loadCourseStats() async {
    setState(() => _isLoading = true);

    try {
      final userRef = FirebaseFirestore.instance.collection('users');
      final usersSnapshot = await userRef.get();
      
      final List<Map<String, dynamic>> students = [];
      int totalCompletedSteps = 0;

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final startedCourses = List<Map<String, dynamic>>.from(
          userData['startedCourses'] ?? []
        );
        
        // Cerca il corso specifico nei corsi iniziati
        final courseData = startedCourses.firstWhere(
          (course) => course['courseId'] == widget.course.id,
          orElse: () => <String, dynamic>{},
        );

        if (courseData.isNotEmpty) {
          // Ottieni i video guardati e le domande risposte
          final watchedVideos = List<Map<String, dynamic>>.from(
            (userData['WatchedVideos'] ?? {})[widget.course.topic] ?? []
          );
          final answeredQuestions = List<String>.from(
            (userData['answeredQuestions'] ?? {})[widget.course.topic] ?? []
          );
          
          // Conta gli step completati per questo studente
          int completedStepsCount = 0;
          
          for (var section in widget.course.sections) {
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

          students.add({
            'name': userData['name'] ?? 'Unknown',
            'startDate': courseData['startDate'] as Timestamp,
            'completedSteps': completedStepsCount,
          });

          totalCompletedSteps += completedStepsCount;
        }
      }

      // Ordina gli studenti per data di inizio (più recenti prima)
      students.sort((a, b) => (b['startDate'] as Timestamp)
          .compareTo(a['startDate'] as Timestamp));

      if (mounted) {
        setState(() {
          _students = students;
          _totalStudents = students.length;
          _totalCompletedSteps = totalCompletedSteps;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading course stats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          title: Text(widget.course.title),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Generale'),
              Tab(text: 'Studenti'),
            ],
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            _buildGeneralTab(),
            _buildStudentsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildStatCard(
            'Totale Studenti',
            _totalStudents.toString(),
            Icons.people,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Step Completati',
            _totalCompletedSteps.toString(),
            Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No students yet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final startDate = (student['startDate'] as Timestamp).toDate();
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: ListTile(
            title: Text(
              student['name'],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Started ${_formatDate(startDate)} • ${student['completedSteps']} steps completed',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 