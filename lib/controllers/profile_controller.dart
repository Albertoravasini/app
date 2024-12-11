import 'package:Just_Learn/models/course.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(userId).update(updates);
    } catch (e) {
      throw ProfileUpdateException('Errore nell\'aggiornamento del profilo: $e');
    }
  }

  Future<void> updateSubscriptionSettings({
    required String userId,
    required double price,
    required List<String> benefits,
  }) async {
    if (benefits.length != 3) {
      throw ProfileUpdateException('Sono richiesti esattamente 3 benefici');
    }
    
    try {
      await updateProfile(
        userId: userId,
        updates: {
          'subscriptionPrice': price,
          'subscriptionDescription1': benefits[0],
          'subscriptionDescription2': benefits[1],
          'subscriptionDescription3': benefits[2],
        },
      );
    } catch (e) {
      throw ProfileUpdateException('Errore nell\'aggiornamento delle impostazioni subscription: $e');
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