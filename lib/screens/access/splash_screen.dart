import 'package:Just_Learn/admin_panel/admin_panel_screen.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:Just_Learn/screens/access/onboarding_screen.dart';
import 'package:Just_Learn/screens/streak_screen.dart'; // Importiamo la schermata di streak
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Just_Learn/screens/access/login_screen.dart';
import 'package:Just_Learn/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int? _previousConsecutiveDays; // Variabile per memorizzare i giorni consecutivi precedenti

  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
  // Inizia a caricare l'utente contemporaneamente al delay
  Future<UserModel?> userModelFuture = _loadUserData();

  // Simula il tempo di caricamento (1 secondo)
  await Future.delayed(const Duration(seconds: 1));

  // Una volta che il caricamento simulato è finito, controlla i dati dell'utente
  UserModel? userModel = await userModelFuture;

  if (userModel != null) {
    // Controlla se `consecutiveDays` è aumentato rispetto all'ultimo accesso
    final now = DateTime.now();
    final lastAccess = userModel.lastAccess;

    // Confrontiamo solo le date, ignorando l'ora
    final lastAccessDate = DateTime(lastAccess.year, lastAccess.month, lastAccess.day);
    final todayDate = DateTime(now.year, now.month, now.day);

    final difference = todayDate.difference(lastAccessDate).inDays;

    if (difference >= 1) { 
      // Se è passata almeno una giornata (qualsiasi ora del giorno successivo)
      setState(() {
        _previousConsecutiveDays = userModel.consecutiveDays;
      });

      if (difference == 1) {
        // Incrementa consecutiveDays solo se è passato un solo giorno
        userModel.consecutiveDays += 1;
      } else {
        // Se è passato più di un giorno, resetta il conteggio
        userModel.consecutiveDays = 1;
      }

      // Aggiorna lastAccess e consecutiveDays nel database
      await FirebaseFirestore.instance.collection('users').doc(userModel.uid).update({
        'consecutiveDays': userModel.consecutiveDays,
        'lastAccess': now.toIso8601String(),
      });

      // Mostra la schermata di streak
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StreakScreen(
            consecutiveDays: userModel.consecutiveDays,
            coins: userModel.coins,
            userModel: userModel, // Passa l'UserModel
            onCollectCoins: () async {
  print('onCollectCoins called'); // Debugging

  // Aumenta i coins quando l'utente raccoglie la ricompensa
  try {
    await FirebaseFirestore.instance.collection('users').doc(userModel.uid).update({
      'coins': FieldValue.increment(userModel.consecutiveDays),
    });
    print('Coins updated in Firestore'); // Debugging
  } catch (e) {
    print('Error updating coins: $e'); // Debugging
  }

  // Naviga alla schermata principale dopo aver raccolto i coin
  _navigateToMainScreen(userModel);
},
          ),
        ),
      );
      return; // Interrompi l'esecuzione per evitare la navigazione immediata
    } else {
      // Se non c'è un nuovo giorno, continua con la navigazione normale
      _navigateToMainScreen(userModel);
    }
  } else {
    // Se non c'è un utente loggato o non esiste l'utente, mostra l'OnboardingScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
    );
  }
}

  Future<UserModel?> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      }
    }
    return null; // Se non c'è un utente corrente o il documento non esiste
  }

  void _navigateToMainScreen(UserModel userModel) {
  if (!mounted) {
    print('Widget is not mounted'); // Debugging
    return;
  }

  print('Navigating to main screen'); // Debugging

  if (userModel.role == 'admin') {
    // Se l'utente è un admin, naviga all'AdminPanelScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
    );
    print('Navigated to AdminPanelScreen'); // Debugging
  } else {
    // Se è un utente normale, naviga alla MainScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainScreen(userModel: userModel)),
    );
    print('Navigated to MainScreen'); // Debugging
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Sfondo nero
      body: Center(
        child: Image.asset(
          'assets/Just_Learn.png', // Immagine centrale
          width: 200, // Puoi regolare la larghezza
          height: 200, // Puoi regolare l'altezza
        ),
      ),
    );
  }
}