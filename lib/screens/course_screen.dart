import 'package:Just_Learn/models/user.dart';
import 'package:Just_Learn/screens/profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key});

  @override
  _CourseScreenState createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  List<UserModel> topTeachers = [];
  bool isLoading = true;
  bool isSearching = false;
  String searchText = "";

  @override
  void initState() {
    super.initState();
    _loadTopTeachers();
  }

  Future<void> _loadTopTeachers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'teacher')
          .limit(50)
          .get();

      if (mounted) {
        setState(() {
          topTeachers = snapshot.docs
              .map((doc) => UserModel.fromMap({...doc.data(), 'uid': doc.id}))
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading teachers: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover the Best',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Teachers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: 'Search teachers...',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 0,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchText = value;
                      if (value.isNotEmpty) {
                        final searchLower = value.toLowerCase();
                        topTeachers = topTeachers.where((teacher) =>
                          teacher.name.toLowerCase().contains(searchLower) ||
                          teacher.topics.any((topic) => 
                            topic.toLowerCase().contains(searchLower))
                        ).toList();
                      } else {
                        _loadTopTeachers();
                      }
                    });
                  },
                ),
              ),
            ),

            // Teachers grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: topTeachers.length,
                itemBuilder: (context, index) {
                  final teacher = topTeachers[index];
                  return _buildTeacherCard(teacher);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card insegnante ridisegnata
  Widget _buildTeacherCard(UserModel teacher) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getTeacherStats(teacher.uid),
      builder: (context, snapshot) {
        final coursesCount = snapshot.data?['coursesCount'] ?? 0;
        final rating = snapshot.data?['rating'] ?? 0.0;
        
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen(currentUser: teacher)),
              ),
              child: Column(
                children: [
                  // Immagine profilo insegnante
                  Expanded(
                    flex: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(
                            teacher.profileImageUrl ?? '',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  // Info insegnante
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teacher.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            teacher.topics.join(' • '),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.yellowAccent,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.yellowAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$coursesCount courses',
                                  style: const TextStyle(
                                    color: Colors.yellowAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Future<Map<String, dynamic>> _getTeacherStats(String teacherId) async {
    final coursesSnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('authorId', isEqualTo: teacherId)
        .get();
        
    final reviewsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(teacherId)
        .collection('reviews')
        .get();
        
    double totalRating = 0;
    final reviews = reviewsSnapshot.docs;
    if (reviews.isNotEmpty) {
      totalRating = reviews.fold(0.0, (sum, doc) => sum + (doc.data()['rating'] ?? 0.0)) / reviews.length;
    }

    return {
      'coursesCount': coursesSnapshot.docs.length,
      'rating': totalRating,
    };
  }
}