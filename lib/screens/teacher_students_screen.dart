import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../screens/profile_screen.dart';
import '../screens/student_details_screen.dart';

class TeacherStudentsScreen extends StatefulWidget {
  final String teacherId;

  const TeacherStudentsScreen({
    Key? key,
    required this.teacherId,
  }) : super(key: key);

  @override
  State<TeacherStudentsScreen> createState() => _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends State<TeacherStudentsScreen> {
  List<UserModel> _allStudents = [];
  List<UserModel> _filteredStudents = [];
  Set<String> _subscribedStudentIds = {};
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _allStudents.where((student) {
        return student.name.toLowerCase().contains(query) ||
            (student.username?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    try {
      // Carica tutti i followers
      final followersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('following', arrayContains: widget.teacherId)
          .get();

      // Carica tutti i subscribers e salva i loro ID
      final subscribersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('subscriptions', arrayContains: widget.teacherId)
          .get();

      _subscribedStudentIds = subscribersSnapshot.docs
          .map((doc) => doc.id)
          .toSet();

      // Combina followers e subscribers in una lista unica senza duplicati
      final Map<String, UserModel> uniqueStudents = {};
      
      for (var doc in followersSnapshot.docs) {
        uniqueStudents[doc.id] = UserModel.fromMap(doc.data());
      }
      
      for (var doc in subscribersSnapshot.docs) {
        uniqueStudents[doc.id] = UserModel.fromMap(doc.data());
      }

      setState(() {
        _allStudents = uniqueStudents.values.toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        _filteredStudents = _allStudents;
        _isLoading = false;
      });
    } catch (e) {
      print('Errore nel caricamento degli studenti: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('I Miei Studenti'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cerca studenti...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: const Color(0xFF282828),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
                    ),
                  )
                : _buildStudentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    if (_filteredStudents.isEmpty) {
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
              'Nessuno studente trovato',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        final isSubscribed = _subscribedStudentIds.contains(student.uid);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF282828),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentDetailsScreen(student: student),
                ),
              );
            },
            leading: CircleAvatar(
              backgroundImage: student.profileImageUrl != null
                  ? NetworkImage(student.profileImageUrl!)
                  : null,
              child: student.profileImageUrl == null
                  ? Text(student.name.isNotEmpty 
                      ? student.name[0].toUpperCase() 
                      : '?')
                  : null,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    student.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isSubscribed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.yellowAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.yellowAccent),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.yellowAccent,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.yellowAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              '@${student.username ?? "username"}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white54,
              size: 16,
            ),
          ),
        );
      },
    );
  }
} 