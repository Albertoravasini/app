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
    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('startedCourses', arrayContains: courseId)
        .get();

    final completionsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('completedCourses', arrayContains: courseId)
        .get();

    return {
      'totalStudents': studentsSnapshot.docs.length,
      'completions': completionsSnapshot.docs.length,
      'completionRate': studentsSnapshot.docs.isEmpty
          ? 0
          : (completionsSnapshot.docs.length / studentsSnapshot.docs.length * 100)
              .toStringAsFixed(1),
    };
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
                final stats = _courseStats[course.id] ?? {};
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF282828),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CourseStatsScreen(course: course),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        if (course.coverImageUrl != null)
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              image: DecorationImage(
                                image: NetworkImage(course.coverImageUrl!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
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
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStat(
                                    'Studenti',
                                    stats['totalStudents']?.toString() ?? '0',
                                    Icons.people,
                                  ),
                                  _buildStat(
                                    'Completamenti',
                                    stats['completions']?.toString() ?? '0',
                                    Icons.check_circle,
                                  ),
                                  _buildStat(
                                    'Tasso di completamento',
                                    '${stats['completionRate'] ?? '0'}%',
                                    Icons.trending_up,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
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
} 