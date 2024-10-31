// lib/services/course_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';

class CourseService {
  final CollectionReference courseCollection = FirebaseFirestore.instance.collection('courses');

  Future<void> createCourse(Course course) async {
    await courseCollection.add(course.toMap());
  }

  Future<List<Course>> getAllCourses() async {
    final querySnapshot = await courseCollection.get();
    return querySnapshot.docs.map((doc) => Course.fromFirestore(doc)).toList();
  }

  // Nuova funzione per ottenere solo i corsi visibili
  Future<List<Course>> getVisibleCourses() async {
    final querySnapshot = await courseCollection.where('visible', isEqualTo: true).get();
    return querySnapshot.docs.map((doc) => Course.fromFirestore(doc)).toList();
  }
}