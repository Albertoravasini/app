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

  Future<void> checkCoursesToRelease() async {
    final now = DateTime.now();
    final coursesCollection = FirebaseFirestore.instance.collection('courses');
    
    try {
      // Query courses that have a release date and are not visible
      final querySnapshot = await coursesCollection
          .where('releaseDate', isLessThan: Timestamp.fromDate(now))
          .where('visible', isEqualTo: false)
          .get();

      // Update each course that needs to be released
      for (var doc in querySnapshot.docs) {
        await coursesCollection.doc(doc.id).update({
          'visible': true,
          'releaseDate': null,
        });
      }
    } catch (e) {
      print('Error checking courses to release: $e');
    }
  }
}