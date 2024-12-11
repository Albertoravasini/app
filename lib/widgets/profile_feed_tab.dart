import 'package:Just_Learn/widgets/course_preview_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/course.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileFeedTab extends StatelessWidget {
  final List<Course> userCourses;
  final bool isLoading;

  const ProfileFeedTab({
    Key? key,
    required this.userCourses,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
              strokeWidth: 2,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading courses...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (userCourses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No published courses',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your courses will appear here',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: userCourses.length,
      itemBuilder: (context, index) {
        final course = userCourses[index];
        return Hero(
          tag: 'course_${course.id}',
          child: Card(
            color: const Color(0xFF282828),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedback.lightImpact();
                _showCoursePreview(context, course);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stack per l'immagine di copertina e il badge del prezzo
                  Stack(
                    children: [
                      _buildCoverImage(course),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _buildPriceBadge(course.cost, course.id),
                      ),
                    ],
                  ),
                  // Contenuto del corso
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titolo e descrizione
                        _buildTitleAndDescription(course),
                        const SizedBox(height: 16),
                        // Statistiche del corso
                        _buildCourseStats(course),
                        const SizedBox(height: 16),
                        // Sezioni e progresso
                        _buildSectionsProgress(course),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoverImage(Course course) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: course.coverImageUrl != null
            ? Image.network(
                course.coverImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[800],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        color: Colors.white.withOpacity(0.3),
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Image not available',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
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
    );
  }

  Widget _buildPriceBadge(int cost, String courseId) {
    return FutureBuilder<bool>(
      future: _isCourseUnlocked(courseId),
      builder: (context, snapshot) {
        final isUnlocked = snapshot.data ?? false;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isUnlocked 
                ? Colors.black.withOpacity(0.7)
                : Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUnlocked 
                  ? Colors.yellowAccent.withOpacity(0.3)
                  : Colors.yellowAccent.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isUnlocked ? Icons.lock_open : Icons.stars_rounded,
                size: 16,
                color: Colors.yellowAccent,
              ),
              const SizedBox(width: 4),
              Text(
                isUnlocked ? 'Unlocked' : '$cost',
                style: const TextStyle(
                  color: Colors.yellowAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitleAndDescription(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          course.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          course.description,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildCourseStats(Course course) {
    return Row(
      children: [
        _buildStat(Icons.star_rounded, course.rating.toStringAsFixed(1), 'Rating'),
        _buildDivider(),
        _buildStat(Icons.people_outline_rounded, '${course.totalRatings}', 'Students'),
        _buildDivider(),
        _buildStat(
          Icons.timer_outlined,
          '${_calculateTotalDuration(course)} min',
          'Duration',
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

  Widget _buildSectionsProgress(Course course) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getCourseProgress(course),
      builder: (context, snapshot) {
        final completedSections = snapshot.data?['completedSections'] as List<String>? ?? [];
        final totalSections = course.sections.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$totalSections sections',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${course.sections.fold(0, (sum, section) => sum + section.steps.length)} Steps',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                children: List.generate(
                  totalSections,
                  (index) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: completedSections.contains(course.sections[index].title)
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
        );
      },
    );
  }

Future<Map<String, dynamic>> _getCourseProgress(Course course) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return {
      'completedSections': <String>[],
      'currentSteps': <String, int>{},
    };
  }

  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (!userDoc.exists) {
    return {
      'completedSections': <String>[],
      'currentSteps': <String, int>{},
    };
  }

  final userData = userDoc.data() as Map<String, dynamic>;
  final completedSections = List<String>.from(userData['completedSections'] ?? []);
  final currentSteps = Map<String, dynamic>.from(userData['currentSteps'] ?? {});

  // Controlla se ci sono sezioni completate non ancora aggiunte
  for (var section in course.sections) {
    final currentStep = currentSteps[section.title] ?? 0;
    if (currentStep >= section.steps.length && !completedSections.contains(section.title)) {
      completedSections.add(section.title);
    }
  }

  return {
    'completedSections': completedSections,
    'currentSteps': currentSteps,
  };
}

  int _calculateTotalDuration(Course course) {
    return course.sections.fold(0, (total, section) {
      int totalVideos = section.steps.where((step) => step.type == 'video').length;
      int totalQuestions = section.steps.where((step) => step.type == 'question').length;
      double totalTime = totalVideos * 1 + totalQuestions * 0.5;
      return total + totalTime.ceil();
    });
  }

  void _showCoursePreview(BuildContext context, Course course) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CoursePreviewSheet(course: course),
    );
  }

  Future<bool> _isCourseUnlocked(String courseId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) return false;

    // Ottieni i dati del corso
    final courseDoc = await FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .get();

    final userData = userDoc.data() as Map<String, dynamic>;
    final unlockedCourses = List<String>.from(userData['unlockedCourses'] ?? []);
    final subscriptions = List<String>.from(userData['subscriptions'] ?? []);
    
    // Controlla se l'utente ha una subscription al creatore del corso
    if (courseDoc.exists && subscriptions.contains(courseDoc.get('authorId'))) {
      return true;
    }
    
    return unlockedCourses.contains(courseId);
  }
} 