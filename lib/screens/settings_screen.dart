import 'package:Just_Learn/screens/NotificationsScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import 'access/login_screen.dart';
import 'privacy_policy_screen.dart';
import 'how_to_use_screen.dart';

class SettingsScreen extends StatelessWidget {
  final UserModel? currentUser;

  const SettingsScreen({super.key, this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 0.0),
            child: Text(
              currentUser?.name ?? 'Settings',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSectionTitle('Profile'),
            const SizedBox(height: 8),
            _buildProfileSection(context),
            const SizedBox(height: 16),
            _buildSectionTitle('Preferences'),
            const SizedBox(height: 8),
            _buildPreferencesSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w700,
          height: 1.5,
          letterSpacing: 0.42,
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.98),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildListTile(
            context,
            icon: Icons.question_mark_rounded,
            text: 'How to use JustLearn',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  HowToUseScreen()),
              );
            },
          ),
          const Divider(thickness: 1, color: Color(0xFFD9D9D9)),
          _buildListTile(
            context,
            icon: Icons.language,
            text: 'Change language',
            onTap: () {
              // Aggiungi il codice per cambiare la lingua qui
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.98),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
      children: [
        _buildListTile(
          context,
          icon: Icons.notifications,
          text: 'Notifications',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationsScreen()),
            );
          },
        ),
        const Divider(thickness: 1, color: Color(0xFFD9D9D9)),
        _buildListTile(
          context,
          icon: Icons.privacy_tip,
          text: 'Privacy Policy',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
            );
          },
        ),
        const Divider(thickness: 1, color: Color(0xFFD9D9D9)),
        _buildListTile(
          context,
          icon: Icons.delete,
          text: 'Delete Account',
          onTap: () {
            _showDeleteAccountDialog(context);
          },
        ),
      ],
    ),
  );
}

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color textColor = Colors.black, // Aggiungi un parametro per il colore del testo
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.black),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: textColor, // Usa il colore passato come parametro
                  fontSize: 14,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                  letterSpacing: 0.42,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 16),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
  String email = '';
  String password = '';

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(
          'Delete Account',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            color: Colors.black, // Testo del titolo nero
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please enter your email and password to confirm.',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.black, // Testo descrittivo nero
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => email = value,
              style: const TextStyle(color: Colors.black), // Testo di input nero
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: Colors.black), // Testo dell'etichetta nero
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.black), // Bordo nero quando non selezionato
                  borderRadius: BorderRadius.circular(8.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.black), // Bordo nero quando selezionato
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              cursorColor: Colors.black, // Colore del cursore nero
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => password = value,
              style: const TextStyle(color: Colors.black), // Testo di input nero
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: const TextStyle(color: Colors.black), // Testo dell'etichetta nero
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.black), // Bordo nero quando non selezionato
                  borderRadius: BorderRadius.circular(8.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.black), // Bordo nero quando selezionato
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              obscureText: true,
              cursorColor: Colors.black, // Colore del cursore nero
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (email.isNotEmpty && password.isNotEmpty) {
                try {
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    AuthCredential credential = EmailAuthProvider.credential(
                      email: email,
                      password: password,
                    );
                    await user.reauthenticateWithCredential(credential);
                    await user.delete();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (Route<dynamic> route) => false,
                    );
                  }
                } catch (e) {
                  // Gestisci l'errore (es. credenziali non valide)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error: ${e.toString()}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                  );
                }
              } else {
                // Mostra un messaggio di errore se i campi sono vuoti
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please fill in all fields.',
                      style: TextStyle(
                        color: Colors.red,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, // Sfondo rosso
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // Bordi arrotondati
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white, // Testo bianco
              ),
            ),
          ),
        ],
      );
    },
  );
}}