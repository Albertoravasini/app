import 'package:Just_Learn/web/screens/web_home_screen.dart';
import 'package:Just_Learn/web/screens/web_onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:Just_Learn/services/web_auth_service.dart';

class WebSignUpScreen extends StatefulWidget {
  @override
  _WebSignUpScreenState createState() => _WebSignUpScreenState();
}

class _WebSignUpScreenState extends State<WebSignUpScreen> {
  bool showEmailSignup = false;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final WebAuthService _authService = WebAuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF111111),
      body: Center(
        child: Container(
          width: 480,
          padding: EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!showEmailSignup) ...[
                _buildInitialView(),
              ] else ...[
                _buildEmailSignupView(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialView() {
    return Column(
      children: [
        Text(
          'Create your account',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Create your account to access JustLearn immediately. You can use an email address or continue with social.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.grey[400],
            fontSize: 16,
            height: 1.5,
          ),
        ),
        SizedBox(height: 40),
        _buildSocialButton(
          onPressed: _handleGoogleSignIn,
          icon: Icon(FontAwesomeIcons.google, color: Colors.black, size: 24),
          text: 'Continue with Google',
        ),
        SizedBox(height: 16),
        _buildSocialButton(
          onPressed: _handleAppleSignIn,
          icon: Icon(FontAwesomeIcons.apple, color: Colors.white, size: 24),
          text: 'Continue with Apple',
          isDark: true,
        ),
        SizedBox(height: 16),
        _buildSocialButton(
          onPressed: () => setState(() => showEmailSignup = true),
          icon: Icon(Icons.email_outlined, color: Colors.white, size: 24),
          text: 'Continue with Email',
          isDark: true,
        ),
        SizedBox(height: 32),
        Text(
          'By continuing you accept the',
          style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {},
              child: Text(
                'privacy policy',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Text(
              'and',
              style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'terms of service',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: GoogleFonts.inter(color: Colors.grey[400]),
            ),
            TextButton(
              onPressed: () {
                // Navigate to login
              },
              child: Text(
                'Sign in to JustLearn',
                style: GoogleFonts.inter(
                  color: Colors.yellowAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailSignupView() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => setState(() => showEmailSignup = false),
            ),
            Expanded(
              child: Text(
                'Create Account',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: 40),
          ],
        ),
        SizedBox(height: 40),
        TextField(
          controller: nameController,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
            filled: true,
            fillColor: Color(0xFF242424),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.all(16),
          ),
        ),
        SizedBox(height: 16),
        TextField(
          controller: emailController,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your email',
            hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
            filled: true,
            fillColor: Color(0xFF242424),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.all(16),
          ),
        ),
        SizedBox(height: 16),
        TextField(
          controller: passwordController,
          obscureText: true,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Create a password',
            hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
            filled: true,
            fillColor: Color(0xFF242424),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.all(16),
            suffixIcon: Icon(Icons.visibility_off, color: Colors.grey[400]),
          ),
        ),
        SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () async {
              try {
                final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: emailController.text,
                  password: passwordController.text,
                );
                
                // Salva il nome dell'utente
                await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
                  'name': nameController.text,
                  'email': emailController.text,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                // Naviga alla schermata di onboarding
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => WebOnboardingScreen()),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Errore di registrazione: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Continue',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onPressed,
    required Widget icon,
    required String text,
    bool isDark = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Color(0xFF242424) : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isDark 
              ? BorderSide(color: Colors.white.withOpacity(0.1))
              : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            SizedBox(width: 12),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential != null) {
        await _handleSuccessfulAuth(userCredential);
      }
    } catch (e) {
      _handleAuthError('Google', e);
    }
  }

  Future<void> _handleAppleSignIn() async {
    try {
      final userCredential = await _authService.signInWithApple();
      if (userCredential != null) {
        await _handleSuccessfulAuth(userCredential);
      }
    } catch (e) {
      _handleAuthError('Apple', e);
    }
  }

  Future<void> _handleSuccessfulAuth(UserCredential userCredential) async {
    final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
    
    if (isNewUser) {
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': userCredential.user!.displayName ?? '',
        'email': userCredential.user!.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastAccess': FieldValue.serverTimestamp(),
        'role': 'user',
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WebOnboardingScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WebHomeScreen()),
      );
    }
  }

  void _handleAuthError(String provider, dynamic error) {
    print('Errore durante l\'autenticazione con $provider: $error');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Errore durante l\'accesso con $provider. Riprova più tardi.'),
        backgroundColor: Colors.red,
      ),
    );
  }
} 