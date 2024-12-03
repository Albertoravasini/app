// lib/screens/access/sign_in_options_screen.dart

import 'package:Just_Learn/main.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:Just_Learn/screens/Privacy_Policy_Screen.dart';
import 'package:Just_Learn/screens/home_screen.dart';
import 'package:Just_Learn/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'register_screen.dart'; // Import your registration screen
import 'login_screen.dart'; // Import your login screen
import 'topic_selection_screen.dart'; // Import the topic selection screen
import 'package:sign_in_with_apple/sign_in_with_apple.dart'; // Import Sign in with Apple
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

class SignInOptionsScreen extends StatelessWidget {
  const SignInOptionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false); // Use AuthService for Google and Apple Sign-In

    void handlePrivacyPolicy() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: Colors.black), // Sfondo nero come login_screen.dart
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Spazio per la status bar
            Container(
              width: double.infinity,
              height: 60,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 25),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05), // Colore bianco con opacità
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(31),
                    topRight: Radius.circular(31),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Welcome To JustLearn',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white, // Colore testo cambiato a bianco
                        fontSize: 45,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Stop wasting your time',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70, // Cambiato a bianco semi-trasparente
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const Spacer(),
                    // Sign In with Email button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()), // Navigate to Register screen
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white12, width: 2), // Bordi cambiati a bianco con opacità
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/Vector.png', // Email icon path
                              height: 24,
                              width: 24,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Sign In with Email',
                              style: TextStyle(
                                color: Colors.white, // Cambiato colore a bianco
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 19),
                    // Sign In with Google button
                    GestureDetector(
                      onTap: () async {
                        User? user = await authService.signInWithGoogle();

                        if (user != null) {
                          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

                          if (userDoc.exists) {
                            final userModel = UserModel.fromMap(userDoc.data()!);

                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => MainScreen(userModel: userModel),
                              ),
                              (Route<dynamic> route) => false,
                            );
                          } else {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => TopicSelectionScreen(user: user),
                              ),
                              (Route<dynamic> route) => false,
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to sign in with Google')),
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white12, width: 2), // Bordi cambiati a bianco con opacità
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/Vector1.png', // Google icon path
                              height: 24,
                              width: 24,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Sign In with Google',
                              style: TextStyle(
                                color: Colors.white, // Cambiato colore a bianco
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 19),
                    // Conditionally display "Sign in with Apple" on iOS devices
                    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
                      GestureDetector(
                        onTap: () async {
                          try {
                            User? user = await authService.signInWithApple();

                            if (user != null) {
                              final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

                              if (userDoc.exists) {
                                final userModel = UserModel.fromMap(userDoc.data()!);

                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (context) => MainScreen(userModel: userModel),
                                  ),
                                  (Route<dynamic> route) => false,
                                );
                              } else {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (context) => TopicSelectionScreen(user: user),
                                  ),
                                  (Route<dynamic> route) => false,
                                );
                              }
                            }
                          } catch (error) {
                            print('Errore durante il login con Apple: $error');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Fallito il login con Apple')),
                            );
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12, width: 2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.apple,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Sign In with Apple',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 19),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 20.0),
                            child: Divider(
                              color: Colors.white70, // Cambiato colore a bianco semi-trasparente
                              thickness: 1, // Spessore della linea
                              height: 3,
                            ),
                          ),
                        ),
                        const Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.white70, // Cambiato colore a bianco semi-trasparente
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 20.0),
                            child: Divider(
                              color: Colors.white70, // Cambiato colore a bianco semi-trasparente
                              thickness: 1, // Spessore della linea
                              height: 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 19),
                    // Log in to my Account button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()), // Navigate to Login screen
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
                        decoration: BoxDecoration(
                          color: Colors.white, // Cambiato colore a bianco
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Text(
                            'Log in to my Account',
                            style: TextStyle(
                              color: Colors.black, // Testo nero
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Privacy Policy
                    GestureDetector(
                      onTap: handlePrivacyPolicy,
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          text: 'By continuing you agree to Justlearn ',
                          style: TextStyle(
                            color: Colors.white70, // Cambiato colore a bianco semi-trasparente
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Montserrat',
                          ),
                          children: [
                            TextSpan(
                              text: 'Privacy Policy.',
                              style: TextStyle(
                                color: Colors.white70, // Cambiato colore a bianco semi-trasparente
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}