import 'package:Just_Learn/admin_panel/admin_panel_screen.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:Just_Learn/screens/access/onboarding_screen.dart';
import 'package:Just_Learn/screens/streak_screen.dart'; // Importiamo la schermata di streak
import 'package:Just_Learn/web/layout/web_main_layout.dart';
import 'package:Just_Learn/web/screens/web_explore_screen.dart';
import 'package:Just_Learn/web/screens/web_home_screen.dart';
import 'package:Just_Learn/web/screens/web_landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Just_Learn/screens/access/login_screen.dart';
import 'package:Just_Learn/main.dart';
import 'package:Just_Learn/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:Just_Learn/services/purchase_service.dart';

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
  try {
    await Future.delayed(const Duration(seconds: 1));

    // Verifica lo stato dell'abbonamento in modo diverso per web e mobile
    bool isPro = false;
    if (kIsWeb) {
      // Su web, verifica lo stato Pro da Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        isPro = doc.data()?['isPro'] ?? false;
      }
    } else {
      // Su mobile, usa RevenueCat
      final customerInfo = await PurchaseService.getCustomerInfo();
      isPro = PurchaseService.isProUser(customerInfo);
    }
    print('DEBUG: Utente Pro: $isPro');

    if (kIsWeb) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WebMainLayout(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => WebLandingScreen()),
        );
      }
      return;
    }

    // Per le app mobile, continua con il flusso esistente
    Future<UserModel?> userModelFuture = _loadUserData();
    UserModel? userModel = await userModelFuture;

    if (userModel != null) {
      final notificationService = NotificationService();

      final now = DateTime.now().toLocal();
      final lastAccess = userModel.lastAccess.toLocal();
      
      final lastAccessDate = DateTime(lastAccess.year, lastAccess.month, lastAccess.day);
      final todayDate = DateTime(now.year, now.month, now.day);
      
      print('DEBUG: Now: $now');
      print('DEBUG: Last Access: $lastAccess');
      print('DEBUG: Last Access Date: $lastAccessDate');
      print('DEBUG: Today Date: $todayDate');
      print('DEBUG: Is Before?: ${lastAccessDate.isBefore(todayDate)}');
      print('DEBUG: Consecutive Days: ${userModel.consecutiveDays}');

      if (lastAccessDate.isBefore(todayDate)) {
        print('DEBUG: Showing streak screen');
        userModel.consecutiveDays += 1;
        
        await FirebaseFirestore.instance.collection('users').doc(userModel.uid).update({
          'consecutiveDays': userModel.consecutiveDays,
          'lastAccess': now.toIso8601String(),
        });

        await notificationService.getAndUpdateToken();

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => StreakScreen(
                consecutiveDays: userModel.consecutiveDays,
                coins: userModel.coins,
                userModel: userModel,
                onCollectCoins: () async {
                  print('DEBUG: Collecting coins');
                  // Aumenta i coins quando l'utente raccoglie la ricompensa
                  try {
                    await FirebaseFirestore.instance.collection('users').doc(userModel.uid).update({
                      'coins': FieldValue.increment(10 + (userModel.consecutiveDays - 1) * 5),
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
          return;
        }
      } else {
        print('DEBUG: Skipping streak screen, same day');
        await notificationService.getAndUpdateToken();
      }
      
      // Aggiorna lo stato premium dell'utente in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userModel.uid)
          .update({'isPro': isPro});

      _navigateToMainScreen(userModel);
    } else {
      print('DEBUG: No user model found');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  } catch (e) {
    print('DEBUG: Error in _navigateToNextScreen: $e');
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