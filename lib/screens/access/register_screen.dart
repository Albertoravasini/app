import 'package:Just_Learn/main.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:Just_Learn/screens/access/topic_selection_screen.dart';
import 'package:Just_Learn/screens/home_screen.dart';
import 'package:Just_Learn/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart'; // Import your login screen

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(color: Colors.black),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status bar and top spacing
            Container(
              width: double.infinity,
              height: 60,
            ),
            const SizedBox(height: 1),
            // Form container
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 22),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05), // Trasparenza come su login_screen.dart
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(31),
                    topRight: Radius.circular(31),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header text
                      const Text(
                        'Create a new Account',
                        style: TextStyle(
                          color: Colors.white, // Cambiato a bianco
                          fontSize: 45,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Name input
                      _buildTextInput(nameController, 'Name', TextInputType.name),
                      const SizedBox(height: 31),

                      // Email input
                      _buildTextInput(emailController, 'Email', TextInputType.emailAddress),
                      const SizedBox(height: 31),

                      // Password input
                      _buildPasswordInput(passwordController, 'Password'),
                      const SizedBox(height: 31),

                      // OR divider
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(right: 20.0),
                              child: Divider(
                                color: Colors.white70, // Cambiato a bianco semi-opaco
                                thickness: 1,
                                height: 3,
                              ),
                            ),
                          ),
                          const Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.white70, // Cambiato a bianco semi-opaco
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(left: 20.0),
                              child: Divider(
                                color: Colors.white70, // Cambiato a bianco semi-opaco
                                thickness: 1,
                                height: 3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 31),

                      // Google sign-in button
                      GestureDetector(
                        onTap: () async {
                          final authService = Provider.of<AuthService>(context, listen: false);
                          User? user = await authService.signInWithGoogle();

                          if (user != null) {
                            final userDoc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .get();

                            if (userDoc.exists) {
                              final userModel = UserModel.fromMap(userDoc.data()!);

                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MainScreen(userModel: userModel),
                                ),
                                (Route<dynamic> route) => false,
                              );
                            } else {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TopicSelectionScreen(user: user),
                                ),
                                (Route<dynamic> route) => false,
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Failed to sign in with Google')),
                            );
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(width: 2, color: Colors.white12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/Vector1.png',
                                height: 24,
                                width: 24,
                                color: Colors.white, // Cambiato a bianco
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Sign In with Google',
                                style: TextStyle(
                                  color: Colors.white, // Cambiato a bianco
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Continue and Log In buttons
                      _buildPrimaryButton('Continue', Colors.white, Colors.black, () async {
                        if (_formKey.currentState!.validate()) {
                          try {
                            User? user = await authService.registerWithEmailPassword(
                              emailController.text.trim(),
                              passwordController.text.trim(),
                            );

                            if (user != null) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .set({
                                'uid': user.uid,
                                'email': emailController.text.trim(),
                                'name': nameController.text.trim(),
                                'topics': [],
                                'completedLevels': [],
                                'consecutiveDays': 0,
                                'role': 'user',
                                'lastAccess': DateTime.now().toIso8601String(),
                              });

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TopicSelectionScreen(user: user),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to register: $e')),
                            );
                          }
                        }
                      }),
                      const SizedBox(height: 11),
                      _buildPrimaryButton('Log In', Colors.white.withOpacity(0.05), Colors.white, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInput(TextEditingController controller, String hintText, TextInputType inputType) {
    return Container(
      width: double.infinity,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 17),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1), // Sfondo trasparente
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        style: const TextStyle(color: Colors.white), // Cambiato a bianco
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white70), // Cambiato a bianco semi-opaco
          border: InputBorder.none,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your $hintText';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordInput(TextEditingController controller, String hintText) {    return Container(
      width: double.infinity,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1), // Sfondo trasparente
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12, width: 1), // Bordo semi-trasparente
      ),
      child: TextFormField(
        controller: controller,
        obscureText: !_isPasswordVisible,
        style: const TextStyle(color: Colors.white), // Cambiato a bianco
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white70), // Cambiato a bianco semi-opaco
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.white, // Cambiato a bianco
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your $hintText';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPrimaryButton(String label, Color backgroundColor, Color textColor, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: textColor.withOpacity(0.2), width: 2), // Trasparenza
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Montserrat',
            ),
          ),
        ),
      ),
    );
  }
}