// lib/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:math';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // L'utente ha annullato il login
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Verifica se l'utente esiste in Firestore
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          // Se l'utente non esiste, crealo
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'name': user.displayName ?? '',
            'topics': [],
            'completedLevels': [],
            'consecutiveDays': 0,
            'role': 'user',
            'lastAccess': DateTime.now().toIso8601String(),
          });
        }
        // Imposta le proprietà utente
    await FirebaseAnalytics.instance.setUserId(id: user.uid);
    await FirebaseAnalytics.instance.setUserProperty(name: 'email', value: user.email);
    await FirebaseAnalytics.instance.setUserProperty(name: 'name', value: user.displayName ?? '');
  
      }

      return user;
    } catch (e) {
      print('Errore durante il login con Google: $e');
      return null;
    }
  }

  /// Sign in with Email and Password
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Errore durante il login con email/password: $e');
      return null;
    }
  }

  /// Register with Email and Password
  Future<User?> registerWithEmailPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Errore durante la registrazione con email/password: $e');
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      print('Errore durante il logout: $e');
    }
  }

  /// Stream of authentication state changes
  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  /// Sign in with Apple
  Future<User?> signInWithApple() async {
    try {
      // Ottieni le credenziali Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Crea le credenziali OAuth per Firebase
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Effettua il login con Firebase usando le credenziali Apple
      final UserCredential userCredential = await _auth.signInWithCredential(oauthCredential);
      final User? user = userCredential.user;

      if (user != null) {
        // Verifica se l'utente esiste in Firestore
        final userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          // Se l'utente non esiste, crealo
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': appleCredential.email ?? user.email ?? '',
            'name': _getFullName(appleCredential),
            'topics': [],
            'completedLevels': [],
            'consecutiveDays': 0,
            'role': 'user',
            'lastAccess': DateTime.now().toIso8601String(),
          });
        } else {
          // Aggiorna lastAccess se l'utente esiste già
          await _firestore.collection('users').doc(user.uid).update({
            'lastAccess': DateTime.now().toIso8601String(),
          });
        }
      }

      return user;
    } catch (e) {
      print('Errore durante il login con Apple: $e');
      return null;
    }
  }

  /// Helper method to get the full name from Apple credentials
  String _getFullName(AuthorizationCredentialAppleID appleCredential) {
    String firstName = appleCredential.givenName ?? '';
    String lastName = appleCredential.familyName ?? '';
    if (firstName.isEmpty && lastName.isEmpty) {
      return '';
    }
    return '$firstName $lastName'.trim();
  }
}