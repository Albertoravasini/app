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
      
      // 2. Ottieni le subscription attive (correzione qui)
      final subscribersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('subscribedTo', arrayContains: userId)
          .get();

      // 3. Ottieni i corsi dell'insegnante
      final coursesSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('authorId', isEqualTo: userId)
          .get();
      
      _courses = coursesSnapshot.docs.map((doc) => Course.fromFirestore(doc)).toList();

      // 4. Calcola revenue
      double totalRevenue = 0;
      double monthlyRevenue = 0;
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Revenue da acquisti diretti
      final purchasesSnapshot = await FirebaseFirestore.instance
          .collection('purchases')
          .where('teacherId', isEqualTo: userId)
          .get();

      for (var purchase in purchasesSnapshot.docs) {
        final purchaseData = purchase.data();
        final purchaseDate = (purchaseData['timestamp'] as Timestamp).toDate();
        final amount = (purchaseData['amount'] as num).toDouble();

        totalRevenue += amount;
        if (purchaseDate.isAfter(startOfMonth)) {
          monthlyRevenue += amount;
        }
      }

      // Revenue da subscription
      for (var subscriber in subscribersSnapshot.docs) {
        final userData = subscriber.data();
        final subscriptionPrice = userData['subscriptionPrice'] ?? 0.0;
        
        totalRevenue += subscriptionPrice;
        monthlyRevenue += subscriptionPrice;
      }

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
      body: RefreshIndicator(
        color: Colors.yellowAccent,
        backgroundColor: const Color(0xFF282828),
        onRefresh: _loadTeacherStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewCards(),
              const SizedBox(height: 32),
              _buildCoursesSection(),
            ],
          ),
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
        childAspectRatio: 1.5,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'I tuoi corsi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_courses.length} corsi',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _courses.length,
          itemBuilder: (context, index) {
            final course = _courses[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF282828),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(
                    course.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  children: [
                    FutureBuilder<Map<String, dynamic>>(
                      future: _getCourseStats(course.id),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
                              ),
                            ),
                          );
                        }

                        final stats = snapshot.data!;
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildCourseStats(stats),
                              const SizedBox(height: 24),
                              _buildProgressChart(stats['progressDistribution']),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCourseStats(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildCourseStatRow(
            'Studenti Totali',
            stats['totalStudents'].toString(),
            Icons.school_rounded,
          ),
          const Divider(color: Colors.white10),
          _buildCourseStatRow(
            'Acquistati con Coins',
            stats['purchasedWithCoins'].toString(),
            Icons.monetization_on_rounded,
          ),
          const Divider(color: Colors.white10),
          _buildCourseStatRow(
            'Completamento Medio',
            '${stats['averageCompletion'].toStringAsFixed(1)}%',
            Icons.trending_up_rounded,
          ),
          const Divider(color: Colors.white10),
          _buildCourseStatRow(
            'Tasso di Completamento',
            '${stats['completionRate'].toStringAsFixed(1)}%',
            Icons.check_circle_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.yellowAccent, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart(Map<String, int> distribution) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(8),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: distribution.values.reduce((a, b) => a > b ? a : b).toDouble(),
          barGroups: [
            _buildBarGroup(0, '0-20%', distribution['0-20'] ?? 0),
            _buildBarGroup(1, '21-40%', distribution['21-40'] ?? 0),
            _buildBarGroup(2, '41-60%', distribution['41-60'] ?? 0),
            _buildBarGroup(3, '61-80%', distribution['61-80'] ?? 0),
            _buildBarGroup(4, '81-100%', distribution['81-100'] ?? 0),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(
                  ['0-20%', '21-40%', '41-60%', '61-80%', '81-100%'][value.toInt()],
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ),
            ),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, String label, int value) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value.toDouble(),
          color: Colors.yellowAccent,
          width: 20,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
} 