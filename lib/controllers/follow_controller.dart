import 'package:cloud_firestore/cloud_firestore.dart';

class FollowController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> followUser({
    required String followerId,
    required String followedId,
  }) async {
    try {
      // Aggiungi il follower alla lista dei followers dell'utente seguito
      await _firestore.collection('users').doc(followedId).update({
        'followers': FieldValue.arrayUnion([followerId])
      });

      // Aggiungi l'utente seguito alla lista following del follower
      await _firestore.collection('users').doc(followerId).update({
        'following': FieldValue.arrayUnion([followedId])
      });
    } catch (e) {
      throw FollowException('Errore durante il follow: $e');
    }
  }

  Future<void> unfollowUser({
    required String followerId,
    required String followedId,
  }) async {
    try {
      await _firestore.collection('users').doc(followedId).update({
        'followers': FieldValue.arrayRemove([followerId])
      });

      await _firestore.collection('users').doc(followerId).update({
        'following': FieldValue.arrayRemove([followedId])
      });
    } catch (e) {
      throw FollowException('Errore durante l\'unfollow: $e');
    }
  }

  Future<bool> isFollowing({
    required String followerId,
    required String followedId,
  }) async {
    try {
      final doc = await _firestore.collection('users').doc(followerId).get();
      final following = List<String>.from(doc.data()?['following'] ?? []);
      return following.contains(followedId);
    } catch (e) {
      throw FollowException('Errore nel controllo del follow: $e');
    }
  }
}

class FollowException implements Exception {
  final String message;
  FollowException(this.message);
} 