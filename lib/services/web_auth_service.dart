import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class WebAuthService {
  static final WebAuthService _instance = WebAuthService._internal();
  factory WebAuthService() => _instance;
  WebAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Configura GoogleSignIn per il web
      final googleSignIn = GoogleSignIn(
        clientId: '1234567890-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com', // Sostituisci con il tuo client ID
        scopes: ['email', 'profile'],
      );

      // Effettua il sign out prima del sign in per evitare problemi di cache
      await googleSignIn.signOut();
      
      // Effettua il sign in
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      // Ottieni le credenziali di autenticazione
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Effettua il sign in con Firebase
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Errore durante il sign in con Google: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithApple() async {
    try {
      final provider = AppleAuthProvider();
      provider.addScope('email');
      provider.addScope('name');

      // Su web, usa signInWithPopup invece di signInWithRedirect
      return await _auth.signInWithPopup(provider);
    } catch (e) {
      print('Errore durante il sign in con Apple: $e');
      rethrow;
    }
  }
} 