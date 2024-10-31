// lib/admin_panel/course_management_screen.dart

import 'package:Just_Learn/admin_panel/CourseEditScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';

class CourseManagementScreen extends StatefulWidget {
  const CourseManagementScreen({super.key});

  @override
  _CourseManagementScreenState createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  List<Course> _courses = [];
  List<String> _topics = [];

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
    final querySnapshot = await coursesCollection.get();

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
        SnackBar(content: Text('Errore nell\'aggiornare la visibilità: $error')),
      );
    });
  }

  void _deleteCourse(Course course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Elimina Corso',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Sei sicuro di voler eliminare il corso "${course.title}"?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annulla',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('courses').doc(course.id).delete();
              setState(() {
                _courses.remove(course);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Corso eliminato con successo')),
              );
            },
            child: Text(
              'Elimina',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseList() {
    Map<String, List<Course>> coursesByTopic = {};

    for (var course in _courses) {
      if (!coursesByTopic.containsKey(course.topic)) {
        coursesByTopic[course.topic] = [];
      }
      coursesByTopic[course.topic]!.add(course);
    }

    return ListView(
      children: coursesByTopic.entries.map((entry) {
        String topic = entry.key;
        List<Course> courses = entry.value;

        return ExpansionTile(
          title: Text(
            topic,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          children: courses.map((course) {
            return ListTile(
              title: Text(
                course.title,
                style: TextStyle(color: Colors.white),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: course.visible,
                    onChanged: (value) {
                      _updateCourseVisibility(course, value);
                    },
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.red,
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CourseEditScreen(course: course),
                        ),
                      ).then((value) {
                        _loadCourses();
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () {
                      _deleteCourse(course);
                    },
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CourseEditScreen(course: course),
                  ),
                ).then((value) {
                  _loadCourses();
                });
              },
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Sfondo nero
      appBar: AppBar(
        title: const Text('Gestione Corsi'),
        backgroundColor: Colors.grey[900],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildCourseList(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                iconColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // Naviga alla schermata di creazione corso
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CourseEditScreen(),
                  ),
                ).then((value) {
                  _loadCourses();
                });
              },
              child: const Text(
                'Crea Nuovo Corso',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}