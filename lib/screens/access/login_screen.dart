import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          width: 316,
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Reduced font size to fit on screen
              Text(
                'Just Learn',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 57, // Adjusted from 57 to 40
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 160), // Adjusted spacing

              Container(
                height: 137,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 17),
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(width: 1, color: Colors.white),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: TextField(
                        controller: emailController,
                        cursorColor: Colors.white,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.48,
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Container(
                      width: double.infinity,
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 17),
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(width: 1, color: Colors.white),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: TextField(
                        controller: passwordController,
                        cursorColor: Colors.white,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.48,
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100), // Adjusted spacing

              Container( // Adjusted height to accommodate all buttons
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final email = emailController.text;
                        final password = passwordController.text;
                        User? user = await authService.signInWithEmailPassword(email, password);
                        if (user != null) {
                          Navigator.pushReplacementNamed(context, '/home');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to sign in')),
                          );
                        }
                      },
                      child: Container(
                        width: 135.27,
                        height: 56,
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(width: 1, color: Colors.white),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Log In',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              letterSpacing: 0.48,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        // Navigate to home screen as a guest
                        Navigator.pushReplacementNamed(context, '/home', arguments: {'isGuest': true});
                      },
                      child: Container(
                        width: 135.27,
                        height: 56,
                        decoration: ShapeDecoration(
                          color: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(width: 1, color: Colors.grey),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Ospite',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              letterSpacing: 0.48,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 31),
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/welcome');
                        },
                        child: Text(
                          'Don’t have an account? Register',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            letterSpacing: 0.42,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/privacy-policy'); // Assuming you have a route for Privacy Policy screen
                      },
                      child: Text(
                        'Privacy Policy',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}