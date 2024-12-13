import 'package:Just_Learn/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache per ottimizzare le prestazioni
  final Map<String, UserModel> _userCache = {};
  final Duration _cacheDuration = Duration(minutes: 5);

  // Stream degli aggiornamenti utente
  Stream<UserModel?> getUserStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  }

  // Metodi per le subscription
  Future<bool> hasSubscription(String authorId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userData = await _getCachedUser(user.uid);
      return userData?.subscriptions.contains(authorId) ?? false;
    } catch (e) {
      print('Errore nel controllo subscription: $e');
      return false;
    }
  }

  // Gestione corsi
  Future<bool> hasCourseAccess(String courseId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userData = await _getCachedUser(user.uid);
      return userData?.unlockedCourses.contains(courseId) ?? false;
    } catch (e) {
      print('Errore nel controllo accesso corso: $e');
      return false;
    }
  }

  // Transazioni per l'acquisto dei corsi
  Future<bool> unlockCourse(String courseId, int cost) async {
    final user = _auth.currentUser;
    if (user == null) throw UnauthorizedException();

    try {
      bool success = false;
      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(
          _firestore.collection('users').doc(user.uid)
        );
        
        if (!userDoc.exists) throw UserNotFoundException();
        
        final userData = UserModel.fromMap(userDoc.data()!);
        if (userData.coins < cost) throw InsufficientCoinsException();
        
        transaction.update(userDoc.reference, {
          'coins': userData.coins - cost,
          'unlockedCourses': [...userData.unlockedCourses, courseId],
        });
        
        success = true;
      });
      
      // Invalida la cache dopo una transazione
      _invalidateUserCache(user.uid);
      return success;
    } catch (e) {
      print('Errore durante lo sblocco del corso: $e');
      rethrow;
    }
  }

  // Gestione cache utenti
  Future<UserModel?> _getCachedUser(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;

    final userData = UserModel.fromMap(doc.data()!);
    _userCache[userId] = userData;

    // Pulisci la cache dopo un certo tempo
    Future.delayed(_cacheDuration, () => _invalidateUserCache(userId));

    return userData;
  }

  void _invalidateUserCache(String userId) {
    _userCache.remove(userId);
  }
}

// Eccezioni personalizzate
class UnauthorizedException implements Exception {}
class UserNotFoundException implements Exception {}
class InsufficientCoinsException implements Exception {} 