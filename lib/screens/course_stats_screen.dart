import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/user.dart';

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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildStatCard(
            'Totale Studenti',
            '0', // Questo sarà dinamico
            Icons.people,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Step Completati',
            '0', // Questo sarà dinamico
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
    // Lista di esempio, sarà dinamica
    final List<Map<String, dynamic>> students = [
      {'name': 'Mario Rossi', 'startDate': DateTime.now()},
      {'name': 'Luigi Verdi', 'startDate': DateTime.now().subtract(const Duration(days: 2))},
    ];

    return ListView.builder(
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
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
            leading: Text(
              _formatDate(student['startDate']),
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