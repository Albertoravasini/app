import 'package:flutter/material.dart';
import 'privacy_policy_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'access/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  final UserModel? user;

  SettingsScreen({this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Impostazioni',
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '   ${user?.name ?? 'Utente'}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              title: Text(
                'Privacy Policy',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Icon(Icons.arrow_forward, color: Colors.white),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()),
                );
              },
            ),
            ListTile(
              title: Text(
                'Elimina Account',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Icon(Icons.delete, color: Colors.white),
              onTap: () {
                _showDeleteAccountDialog(context);
              },
            ),
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Sfondo bianco
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.black, width: 2), // Linee nere
          ),
          title: Text(
            'Elimina Account',
            style: TextStyle(color: Colors.black), // Testo nero
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.black), // Testo nero
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black), // Bordo nero
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black), // Bordo nero
                  ),
                ),
                style: TextStyle(color: Colors.black), // Testo nero
              ),
              SizedBox(height: 10),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.black), // Testo nero
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black), // Bordo nero
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black), // Bordo nero
                  ),
                ),
                obscureText: true,
                style: TextStyle(color: Colors.black), // Testo nero
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annulla', style: TextStyle(color: Colors.black)), // Testo nero
            ),
            TextButton(
              onPressed: () async {
                await _deleteAccount(
                  context,
                  emailController.text,
                  passwordController.text,
                );
              },
              child: Text('Elimina', style: TextStyle(color: Colors.red)), // Pulsante rosso
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount(BuildContext context, String email, String password) async {
  try {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Riautenticazione
      AuthCredential credential = EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);
      
      // Verifica se l'utente ha i permessi necessari
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        // Elimina i dati dell'utente dal Firestore
        await docRef.delete();

        // Elimina l'utente da Firebase Authentication
        await user.delete();
        
        // Logout e reindirizzamento alla schermata di login
        await FirebaseAuth.instance.signOut();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        print("Documento utente non trovato.");
      }
    }
  } catch (e) {
    print("Errore durante l'eliminazione dell'account: $e");
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore durante l\'eliminazione dell\'account')));
  }
}}