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
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          image: DecorationImage(
            image: AssetImage('assets/pattern_bg.png'), // Aggiungi un pattern di sfondo sottile
            opacity: 0.05,
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // Header con logo e animazione
            SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    // Logo animato
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, double value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Image.asset(
                            'assets/justlearnback.png',
                            height: 80,
                            width: 80,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Titolo con animazione di fade
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, double value, child) {
                        return Opacity(
                          opacity: value,
                          child: const Column(
                            children: [
                              Text(
                                'Welcome To JustLearn',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Stop wasting your time',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Contenitore principale con i pulsanti
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF181819),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Spacer(),
                    // Sign In with Email button
                    _buildSignInButton(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      ),
                      icon: 'assets/Vector.png',
                      text: 'Sign In with Email',
                      isOutlined: true,
                    ),
                    const SizedBox(height: 16),
                    
                    // Sign In with Google button
                    _buildSignInButton(
                      onTap: () async {
                        User? user = await authService.signInWithGoogle();
                        // ... existing Google sign-in logic ...
                      },
                      icon: 'assets/Vector1.png',
                      text: 'Sign In with Google',
                      isOutlined: true,
                    ),
                    const SizedBox(height: 16),
                    
                    // Sign In with Apple button (iOS only)
                    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
                      _buildSignInButton(
                        onTap: () async {
                          try {
                            User? user = await authService.signInWithApple();
                            // ... existing Apple sign-in logic ...
                          } catch (error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Fallito il login con Apple')),
                            );
                          }
                        },
                        icon: '',
                        text: 'Sign In with Apple',
                        isOutlined: true,
                        useAppleIcon: true,
                      ),
                    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
                      const SizedBox(height: 16),
                    
                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Log in button
                    _buildSignInButton(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      ),
                      text: 'Log in to my Account',
                      isPrimary: true,
                    ),
                    const Spacer(),
                    
                    // Privacy Policy
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            text: 'By continuing you agree to Justlearn ',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildSignInButton({
    required VoidCallback onTap,
    required String text,
    String? icon,
    bool isOutlined = false,
    bool isPrimary = false,
    bool useAppleIcon = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: isPrimary ? Colors.yellowAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isOutlined
              ? Border.all(color: Colors.white.withOpacity(0.1), width: 1)
              : null,
          gradient: isOutlined
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null && !useAppleIcon)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Image.asset(
                  icon,
                  height: 24,
                  width: 24,
                  color: isPrimary ? Colors.black : Colors.white,
                ),
              )
            else if (useAppleIcon)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.apple,
                  color: isPrimary ? Colors.black : Colors.white,
                  size: 24,
                ),
              ),
            Text(
              text,
              style: TextStyle(
                color: isPrimary ? Colors.black : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}