// lib/admin_panel/course_management_screen.dart

import 'package:Just_Learn/admin_panel/CourseEditScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:async';

class CourseManagementScreen extends StatefulWidget {
  final String? userId;

  const CourseManagementScreen({
    super.key,
    this.userId,
  });

  @override
  _CourseManagementScreenState createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  List<Course> _courses = [];
  List<String> _topics = [];
  String _searchQuery = '';
  String _selectedFilter = 'Tutti';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTopics();
    _loadCourses();
  }

  Future<void> _loadTopics() async {
    final topicsCollection = FirebaseFirestore.instance.collection('topics');
    final querySnapshot = await topicsCollection.get();
    setState(() {
      _topics = querySnapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<void> _loadCourses() async {
    final coursesCollection = FirebaseFirestore.instance.collection('courses');
    QuerySnapshot querySnapshot;
    
    if (widget.userId != null) {
      querySnapshot = await coursesCollection
          .where('authorId', isEqualTo: widget.userId)
          .get();
    } else {
      querySnapshot = await coursesCollection.get();
    }

    setState(() {
      _courses = querySnapshot.docs
          .map((doc) => Course.fromFirestore(doc))
          .toList();
    });
  }

  void _updateCourseVisibility(Course course, bool visible) {
    FirebaseFirestore.instance
        .collection('courses')
        .doc(course.id)
        .update({'visible': visible}).then((_) {
      setState(() {
        course.visible = visible;
      });
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating visibility: $error')),
      );
    });
  }

  void _deleteCourse(Course course) async {
    try {
      setState(() => _isLoading = true);

      // 1. Prima elimina tutti i video del corso dallo storage
      for (var section in course.sections) {
        for (var step in section.steps) {
          if (step.type == 'video' && step.videoUrl != null) {
            try {
              // Ottieni il riferimento al file dallo storage usando l'URL
              final videoRef = FirebaseStorage.instance.refFromURL(step.videoUrl!);
              await videoRef.delete();
              print('Video eliminato dallo storage: ${step.videoUrl}');
            } catch (e) {
              print('Errore durante l\'eliminazione del video: $e');
              // Continua con gli altri video anche se uno fallisce
            }
          }
        }
      }

      // 2. Elimina l'immagine di copertina se esiste
      if (course.coverImageUrl != null) {
        try {
          final coverRef = FirebaseStorage.instance.refFromURL(course.coverImageUrl!);
          await coverRef.delete();
          print('Immagine di copertina eliminata: ${course.coverImageUrl}');
        } catch (e) {
          print('Errore durante l\'eliminazione dell\'immagine di copertina: $e');
        }
      }

      // 3. Elimina il documento del corso da Firestore
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(course.id)
          .delete();

      // 4. Aggiorna lo stato locale
      setState(() {
        _courses.remove(course);
        _isLoading = false;
      });

      if (!mounted) return;
      
      // 5. Mostra conferma
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Corso e contenuti multimediali eliminati con successo'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      setState(() => _isLoading = false);
      print('Errore durante l\'eliminazione del corso: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante l\'eliminazione: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showReleaseDatePicker(Course course) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: course.releaseDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.yellowAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF282828),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF282828),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      try {
        setState(() => _isLoading = true);

        await FirebaseFirestore.instance
            .collection('courses')
            .doc(course.id)
            .update({
          'releaseDate': Timestamp.fromDate(picked),
          'visible': false,
        });

        // Update local state
        setState(() {
          course.releaseDate = picked;
          course.visible = false;
          _isLoading = false;
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Course will be released on ${picked.day}/${picked.month}/${picked.year}'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting release date: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelRelease(Course course) async {
    try {
      setState(() => _isLoading = true);

      await FirebaseFirestore.instance
          .collection('courses')
          .doc(course.id)
          .update({
        'releaseDate': null,
      });

      // Update local state
      setState(() {
        course.releaseDate = null;
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Release date cancelled'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling release date: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _checkCoursesToRelease() async {
    final now = DateTime.now();
    for (var course in _courses) {
      if (course.releaseDate != null && 
          course.releaseDate!.isBefore(now) && 
          !course.visible) {
        try {
          await FirebaseFirestore.instance
              .collection('courses')
              .doc(course.id)
              .update({
            'visible': true,
            'releaseDate': null,
          });

          setState(() {
            course.visible = true;
            course.releaseDate = null;
          });
        } catch (e) {
          print('Error releasing course ${course.id}: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181819),
      body: SafeArea(
        child: Column(
          children: [
            // Header semplificato con lo stesso stile di CourseEditScreen
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF181819),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    icon: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Course Management',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white70),
                    onPressed: () => _showSearchModal(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.white70),
                    onPressed: () => _showFilterSheet(context),
                  ),
                ],
              ),
            ),

            // Resto del contenuto esistente
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Stats Section con animazioni
                  SliverToBoxAdapter(
                    child: _buildAnimatedStats(),
                  ),

                  // Grid dei corsi
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: _courses.isEmpty
                        ? SliverToBoxAdapter(child: _buildEmptyState())
                        : SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildEnhancedCourseCard(_courses[index]),
                              childCount: _courses.length,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CourseEditScreen()),
        ).then((_) => _loadCourses()),
        backgroundColor: Colors.yellowAccent,
        label: Row(
          children: [
            const Icon(Icons.add, color: Colors.black),
            const SizedBox(width: 8),
            const Text(
              'New Course',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF181819),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.yellowAccent.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAnimatedStatItem(
            'Total',
            _courses.length.toString(),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.yellowAccent.withOpacity(0.2),
          ),
          _buildAnimatedStatItem(
            'Published',
            _courses.where((c) => c.visible).length.toString(),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.yellowAccent.withOpacity(0.2),
          ),
          _buildAnimatedStatItem(
            'Drafts',
            _courses.where((c) => !c.visible).length.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.yellowAccent,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontFamily: 'Montserrat',
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
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
            'No courses created',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by creating your first course',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedCourseCard(Course course) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseEditScreen(course: course),
          ),
        );
        // Reload courses after editing
        _loadCourses();
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF181819),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Immagine di copertina con overlay sfumato
            Positioned.fill(
              child: Image.network(
                course.coverImageUrl ?? 'placeholder_url',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),

            // Contenuto
            Positioned.fill(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge stato
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: course.visible
                                ? Colors.yellowAccent.withOpacity(0.2)
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: course.visible
                                  ? Colors.yellowAccent
                                  : Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            course.visible ? 'Published' : 'Draft',
                            style: TextStyle(
                              color: course.visible ? Colors.yellowAccent : Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ),
                        if (course.releaseDate != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Release: ${course.releaseDate!.day}/${course.releaseDate!.month}/${course.releaseDate!.year}',
                              style: const TextStyle(
                                color: Colors.lightBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Info corso
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.library_books,
                              size: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${course.sections.length} sections',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.monetization_on,
                              size: 14,
                              color: Colors.yellowAccent.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${course.cost}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Menu contestuale in alto a destra
            Positioned(
              top: 8,
              right: 8,
              child: Theme(
                data: Theme.of(context).copyWith(
                  popupMenuTheme: PopupMenuThemeData(
                    color: const Color(0xFF2D2D2D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                child: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.white.withOpacity(0.8),
                    size: 20,
                  ),
                  offset: const Offset(0, 40),
                  itemBuilder: (context) => [
                    // Edit
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Edit Course',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Visibility Toggle
                    PopupMenuItem<String>(
                      value: 'visibility',
                      child: Row(
                        children: [
                          Icon(
                            course.visible ? Icons.visibility_off : Icons.visibility,
                            size: 20,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            course.visible ? 'Hide' : 'Show',
                            style: TextStyle(color: Colors.white.withOpacity(0.8)),
                          ),
                        ],
                      ),
                    ),
                    // Release
                    PopupMenuItem<String>(
                      value: 'release',
                      child: Row(
                        children: [
                          Icon(
                            course.releaseDate != null ? Icons.event_busy : Icons.event,
                            size: 20,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            course.releaseDate != null ? 'Cancel Release' : 'Set Release Date',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Divider
                    const PopupMenuDivider(),
                    // Delete
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.redAccent.withOpacity(0.9),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Delete Course',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    switch (value) {
                      case 'edit':
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseEditScreen(course: course),
                          ),
                        );
                        _loadCourses();
                        break;
                        
                      case 'visibility':
                        try {
                          setState(() => _isLoading = true);
                          
                          await FirebaseFirestore.instance
                            .collection('courses')
                            .doc(course.id)
                            .update({'visible': !course.visible});
                          
                          setState(() {
                            course.visible = !course.visible;
                            _isLoading = false;
                          });
                          
                          if (!mounted) return;
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(course.visible ? 'Course visible' : 'Course hidden'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          setState(() => _isLoading = false);
                          
                          if (!mounted) return;
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error updating visibility: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        break;

                      case 'release':
                        if (course.releaseDate != null) {
                          _cancelRelease(course);
                        } else {
                          _showReleaseDatePicker(course);
                        }
                        break;
                        
                      case 'delete':
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF2D2D2D),
                            title: const Text(
                              'Delete Course',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: Text(
                              'Are you sure you want to delete "${course.title}"?\nThis action cannot be undone.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _deleteCourse(course);
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                        );
                        break;
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchModal(BuildContext context) {
    // Implementa la logica per mostrare il modal di ricerca
  }

  void _showFilterSheet(BuildContext context) {
    // Implementa la logica per mostrare il sheet di filtro
  }

  void _showCourseActions(BuildContext context, Course course) {
    // Implementa la logica per mostrare le azioni del corso
  }
}