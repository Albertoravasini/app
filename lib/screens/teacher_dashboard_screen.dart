import 'package:Just_Learn/screens/teacher_courses_screen.dart';
import 'package:Just_Learn/screens/teacher_students_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Just_Learn/models/course.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherDashboardScreen extends StatefulWidget {
  final String teacherId;

  const TeacherDashboardScreen({
    Key? key,
    required this.teacherId,
  }) : super(key: key);

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadTeacherStats();
  }

  Future<void> _loadTeacherStats() async {
    setState(() => _isLoading = true);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // 1. Ottieni i followers
      final followersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('following', arrayContains: userId)
          .get();
      
      // 2. Ottieni le subscription attive
      final subscribersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('subscriptions', arrayContains: userId)
          .get();

      // 3. Ottieni i corsi dell'insegnante
      final coursesSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('authorId', isEqualTo: userId)
          .get();
      
      _courses = coursesSnapshot.docs.map((doc) => Course.fromFirestore(doc)).toList();

      // 4. Ottieni il prezzo della subscription dell'insegnante
      final teacherDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      final subscriptionPrice = (teacherDoc.data()?['subscriptionPrice'] as num?)?.toDouble() ?? 0.0;
      
      // 5. Calcola revenue
      double totalRevenue = 0;
      double monthlyRevenue = subscriptionPrice * subscribersSnapshot.docs.length; // Revenue mensile dalle subscription

      // Revenue da acquisti diretti (resta invariata)
      final purchasesSnapshot = await FirebaseFirestore.instance
          .collection('purchases')
          .where('teacherId', isEqualTo: userId)
          .get();

      for (var purchase in purchasesSnapshot.docs) {
        final purchaseData = purchase.data();
        final amount = (purchaseData['amount'] as num).toDouble();
        totalRevenue += amount;
      }

      // Aggiungi anche la revenue totale dalle subscription
      totalRevenue += monthlyRevenue;

      setState(() {
        _stats = {
          'followers': followersSnapshot.docs.length,
          'subscriptions': subscribersSnapshot.docs.length,
          'totalRevenue': totalRevenue,
          'monthlyRevenue': monthlyRevenue,
          'coursesCount': _courses.length,
        };
        _isLoading = false;
      });

    } catch (e) {
      print('Errore nel caricamento dei dati: $e');
      setState(() {
        _stats = {
          'followers': 0,
          'subscriptions': 0,
          'totalRevenue': 0.0,
          'monthlyRevenue': 0.0,
          'coursesCount': 0,
        };
        _isLoading = false;
      });
    }
  }

  Future<int> _getPurchasedWithCoins(String courseId) async {
    final purchasesSnapshot = await _firestore
        .collection('users')
        .where('unlockedCourses', arrayContains: courseId)
        .get();
    return purchasesSnapshot.docs.length;
  }

  Future<Map<String, dynamic>> _getCourseStats(String courseId) async {
    final studentsSnapshot = await _firestore
        .collection('users')
        .where('unlockedCourses', arrayContains: courseId)
        .get();

    int totalStudents = studentsSnapshot.docs.length;
    int purchasedWithCoins = 0;
    int completedStudents = 0;
    double totalProgress = 0;
    Map<String, int> progressDistribution = {
      '0-20': 0,
      '21-40': 0,
      '41-60': 0,
      '61-80': 0,
      '81-100': 0,
    };

    for (var doc in studentsSnapshot.docs) {
      final userData = UserModel.fromMap(doc.data());
      
      // Calcola il progresso per questo studente
      double progress = await _calculateStudentProgress(userData, courseId);
      totalProgress += progress;

      // Aggiorna la distribuzione del progresso
      if (progress <= 20) progressDistribution['0-20'] = (progressDistribution['0-20'] ?? 0) + 1;
      else if (progress <= 40) progressDistribution['21-40'] = (progressDistribution['21-40'] ?? 0) + 1;
      else if (progress <= 60) progressDistribution['41-60'] = (progressDistribution['41-60'] ?? 0) + 1;
      else if (progress <= 80) progressDistribution['61-80'] = (progressDistribution['61-80'] ?? 0) + 1;
      else progressDistribution['81-100'] = (progressDistribution['81-100'] ?? 0) + 1;

      if (progress == 100) completedStudents++;
      if (userData.unlockedCourses.contains(courseId)) purchasedWithCoins++;
    }

    return {
      'totalStudents': totalStudents,
      'purchasedWithCoins': purchasedWithCoins,
      'averageCompletion': totalStudents > 0 ? totalProgress / totalStudents : 0,
      'completionRate': totalStudents > 0 ? (completedStudents / totalStudents) * 100 : 0,
      'progressDistribution': progressDistribution,
    };
  }

  Future<double> _calculateStudentProgress(UserModel student, String courseId) async {
    // Recupera il corso
    final courseDoc = await _firestore.collection('courses').doc(courseId).get();
    final course = Course.fromFirestore(courseDoc);

    // Calcola il totale delle sezioni completate
    int completedSections = student.completedSections
        .where((sectionId) => sectionId.startsWith(courseId))
        .length;

    // Calcola la percentuale di completamento
    return (completedSections / course.sections.length) * 100;
  }

  Future<Map<String, dynamic>> _calculateDashboardData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return {};

    try {
      // 1. Ottieni tutti i corsi dell'insegnante
      final coursesSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('authorId', isEqualTo: userId)
          .get();

      final courses = coursesSnapshot.docs;
      
      // 2. Calcoli base
      int totalStudents = 0;
      int totalViews = 0;
      int totalCompletions = 0;
      double totalEarnings = 0;

      // 3. Calcola i dati per ogni corso
      for (var course in courses) {
        final courseData = course.data();
        
        // Studenti: conta gli utenti che hanno iniziato il corso
        final studentsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('startedCourses', arrayContains: course.id)
            .get();
        
        final studentCount = studentsSnapshot.docs.length;
        totalStudents += studentCount;

        // Views: somma le visualizzazioni di tutti i video del corso
        totalViews += (courseData['totalViews'] ?? 0) as int;
        
        // Completamenti: conta gli utenti che hanno completato il corso
        final completionsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('completedCourses', arrayContains: course.id)
            .get();
        
        totalCompletions += completionsSnapshot.docs.length;

        // Guadagni: calcola in base ai completamenti e al prezzo del corso
        final coursePrice = (courseData['price'] ?? 0) as double;
        totalEarnings += completionsSnapshot.docs.length * coursePrice;
      }

      // 4. Calcola il tasso di completamento
      final completionRate = totalStudents > 0 
          ? (totalCompletions / totalStudents * 100).toStringAsFixed(1)
          : '0';

      return {
        'totalStudents': totalStudents,
        'totalViews': totalViews,
        'completionRate': '$completionRate%',
        'totalEarnings': totalEarnings.toStringAsFixed(2),
        'coursesCount': courses.length,
      };
    } catch (e) {
      print('Errore nel calcolo dei dati dashboard: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadTeacherStats,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildOverviewCards(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildNavigationCard(
                    title: 'Students',
                    subtitle: '${_stats['followers']} followers\n${_stats['subscriptions']} subscribers',
                    icon: Icons.people_alt_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeacherStudentsScreen(teacherId: widget.teacherId),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNavigationCard(
                    title: 'Courses',
                    subtitle: '${_courses.length} corsi pubblicati',
                    icon: Icons.school_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeacherCoursesScreen(
                            teacherId: widget.teacherId,
                            courses: _courses,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.3,
        children: [
          _buildStatCard(
            'Follower',
            _stats['followers'].toString(),
            Icons.people_alt_rounded,
            Colors.yellowAccent,
          ),
          _buildStatCard(
            'Subscription',
            _stats['subscriptions'].toString(),
            Icons.star_rounded,
            Colors.yellowAccent,
          ),
          _buildStatCard(
            'Revenue Totale',
            '€${_stats['totalRevenue'].toStringAsFixed(2)}',
            Icons.account_balance_wallet_rounded,
            Colors.yellowAccent,
          ),
          _buildStatCard(
            'Revenue Mensile',
            '€${_stats['monthlyRevenue'].toStringAsFixed(2)}',
            Icons.trending_up_rounded,
            Colors.yellowAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.yellowAccent, size: 28),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
} 