import 'package:Just_Learn/admin_panel/bulk_shorts_screen.dart';
import 'package:Just_Learn/admin_panel/chart_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './user_management_screen.dart.dart';
import './level_management_screen.dart.dart';
import '../services/auth_service.dart';
import '../screens/access/login_screen.dart';


class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        setState(() {
          isAdmin = userData?['role'] == 'admin';
        });
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
    Navigator.pushAndRemoveUntil(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Accesso Negato', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: Text('Non hai i permessi per accedere a questa sezione.', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            color: Colors.white,
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Gestione Utenti', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserManagementScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Gestione Livelli', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LevelManagementScreen()),
              );
            },
          ),
          ListTile(
  title: const Text('Statistiche Accessi Utenti', style: TextStyle(color: Colors.white)),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserActivityChartScreen()),
    );
  },
),ListTile(
            title: Text('Aggiungi Shorts in Bulk', style: TextStyle(color: Colors.white)), // Nuovo pulsante
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BulkShortsScreen()), // Naviga alla nuova schermata
              );
            },
          ),
        ],
      ),
    );
  }
}