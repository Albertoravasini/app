import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> subscribe({
    required String subscriberId,
    required String creatorId,
  }) async {
    try {
      // Aggiunge il subscriber alla lista dei subscribers del creator
      await _firestore.collection('users').doc(creatorId).update({
        'subscribers': FieldValue.arrayUnion([subscriberId])
      });

      // Aggiunge il creator alla lista delle subscriptions del subscriber
      await _firestore.collection('users').doc(subscriberId).update({
        'subscriptions': FieldValue.arrayUnion([creatorId])
      });
    } catch (e) {
      throw SubscriptionException('Errore durante la subscription: $e');
    }
  }

  Future<void> unsubscribe({
    required String subscriberId,
    required String creatorId,
  }) async {
    try {
      await _firestore.collection('users').doc(creatorId).update({
        'subscribers': FieldValue.arrayRemove([subscriberId])
      });

      await _firestore.collection('users').doc(subscriberId).update({
        'subscriptions': FieldValue.arrayRemove([creatorId])
      });
    } catch (e) {
      throw SubscriptionException('Errore durante l\'unsubscribe: $e');
    }
  }

  Future<bool> isSubscribed({
    required String subscriberId,
    required String creatorId,
  }) async {
    try {
      final doc = await _firestore.collection('users').doc(subscriberId).get();
      final subscriptions = List<String>.from(doc.data()?['subscriptions'] ?? []);
      return subscriptions.contains(creatorId);
    } catch (e) {
      throw SubscriptionException('Errore nel controllo della subscription: $e');
    }
  }
}

class SubscriptionException implements Exception {
  final String message;
  SubscriptionException(this.message);
} 