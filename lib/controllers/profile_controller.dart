import 'package:Just_Learn/models/course.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<void> updateProfile({
    required String userId,
    required String name,
    required String username,
    required String bio,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'name': name,
        'username': username,
        'bio': bio,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ProfileUpdateException('Errore nell\'aggiornamento del profilo: $e');
    }
  }

  Future<int> getTeacherCoursesCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('courses')
          .where('authorId', isEqualTo: userId)
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      throw ProfileFetchException('Errore nel recupero dei corsi: $e');
    }
  }

  Future<double> getTeacherRating(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('courses')
          .where('authorId', isEqualTo: userId)
          .get();
      
      double totalRating = 0;
      int totalRatings = 0;
      
      for (var doc in querySnapshot.docs) {
        final course = Course.fromFirestore(doc);
        totalRating += course.rating * course.totalRatings;
        totalRatings += course.totalRatings;
      }
      
      return totalRatings > 0 ? totalRating / totalRatings : 0;
    } catch (e) {
      throw ProfileFetchException('Errore nel recupero delle valutazioni: $e');
    }
  }
}

class ProfileUpdateException implements Exception {
  final String message;
  ProfileUpdateException(this.message);
}

class ProfileFetchException implements Exception {
  final String message;
  ProfileFetchException(this.message);
} 