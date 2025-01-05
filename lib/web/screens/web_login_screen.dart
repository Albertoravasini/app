import 'package:Just_Learn/web/screens/web_home_screen.dart';
import 'package:Just_Learn/web/screens/web_onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class WebLoginScreen extends StatefulWidget {
  @override
  _WebLoginScreenState createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen> {
  bool showEmailLogin = false;
  bool showSignUp = false;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

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
              if (showSignUp) ...[
                _buildSignUpView(),
              ] else if (!showEmailLogin) ...[
                _buildInitialView(),
              ] else ...[
                _buildEmailLoginView(),
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
          'Sign in to JustLearn',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Enter the email and password you used during registration to access JustLearn.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.grey[400],
            fontSize: 16,
            height: 1.5,
          ),
        ),
        SizedBox(height: 40),
        _buildSocialButton(
          onPressed: () => _handleGoogleSignIn(),
          icon: Icon(FontAwesomeIcons.google, color: Colors.black, size: 24),
          text: 'Continue with Google',
        ),
        SizedBox(height: 16),
        _buildSocialButton(
          onPressed: () => _handleAppleSignIn(),
          icon: Icon(FontAwesomeIcons.apple, color: Colors.white, size: 24),
          text: 'Continue with Apple',
          isDark: true,
        ),
        SizedBox(height: 16),
        _buildSocialButton(
          onPressed: () => setState(() => showEmailLogin = true),
          icon: Icon(Icons.email_outlined, color: Colors.white, size: 24),
          text: 'Continue with Email',
          isDark: true,
        ),
        SizedBox(height: 32),

        // Divider with text
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[800])),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Don\'t have an account?',
                style: GoogleFonts.inter(color: Colors.grey[400]),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey[800])),
          ],
        ),
        SizedBox(height: 32),

        // Sign up button
        TextButton(
          onPressed: () => setState(() => showSignUp = true),
          child: Text(
            'Create your JustLearn account',
            style: GoogleFonts.inter(
              color: Colors.yellowAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailLoginView() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => setState(() => showEmailLogin = false),
            ),
            Expanded(
              child: Text(
                'Sign in with Email',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: 40), // Per bilanciare il back button
          ],
        ),
        SizedBox(height: 40),
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
            hintText: 'Enter your password',
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
        SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: Text(
              'Forgot password?',
              style: GoogleFonts.inter(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
        ),
        SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () async {
              try {
                final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: emailController.text,
                  password: passwordController.text,
                );
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => WebHomeScreen()),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Errore di accesso: ${e.toString()}')),
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
              'Sign in',
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

  Widget _buildSignUpView() {
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
                
                await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
                  'name': nameController.text,
                  'email': emailController.text,
                  'createdAt': FieldValue.serverTimestamp(),
                });

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
        SizedBox(height: 32),
        Text(
          'or',
          style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
        ),
        SizedBox(height: 32),
        _buildSocialButton(
          onPressed: () => _handleGoogleSignIn(),
          icon: Icon(FontAwesomeIcons.google, color: Colors.black, size: 24),
          text: 'Continue with Google',
        ),
        SizedBox(height: 16),
        _buildSocialButton(
          onPressed: () => _handleAppleSignIn(),
          icon: Icon(FontAwesomeIcons.apple, color: Colors.white, size: 24),
          text: 'Continue with Apple',
          isDark: true,
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
              onPressed: () => setState(() => showSignUp = false),
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

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'name': userCredential.user!.displayName,
          'email': userCredential.user!.email,
          'createdAt': FieldValue.serverTimestamp(),
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore di accesso con Google: ${e.toString()}')),
      );
    }
  }

  Future<void> _handleAppleSignIn() async {
    try {
      final appleProvider = AppleAuthProvider();
      final userCredential = await FirebaseAuth.instance.signInWithProvider(appleProvider);

      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'name': userCredential.user!.displayName,
          'email': userCredential.user!.email,
          'createdAt': FieldValue.serverTimestamp(),
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore di accesso con Apple: ${e.toString()}')),
      );
    }
  }
} 