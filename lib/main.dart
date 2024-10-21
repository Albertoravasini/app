import 'package:Just_Learn/screens/access/login_screen.dart';
import 'package:Just_Learn/screens/access/register_screen.dart';
import 'package:Just_Learn/screens/access/topic_selection_screen.dart';
import 'package:Just_Learn/screens/access/splash_screen.dart';
import 'package:Just_Learn/screens/course_screen.dart';
import 'package:Just_Learn/screens/quiz_screen.dart';
import 'package:Just_Learn/services/%20notification_service.dart';
import 'package:Just_Learn/services/auth_service.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'admin_panel/admin_panel_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/bottom_navigation_bar_custom.dart'; // Importa la barra di navigazione personalizzata

// Navigator key globale per accedere al contesto fuori dal MaterialApp
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Ottenere l'utente corrente (se autenticato)
  User? currentUser = FirebaseAuth.instance.currentUser;

  // Inizializza il servizio notifiche
  final NotificationService notificationService = NotificationService();
  await notificationService.initialize();

  runApp(MyApp(user: currentUser));
}

class MyApp extends StatelessWidget {
  final User? user;

  const MyApp({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().user,
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'Education App',
        navigatorKey: navigatorKey,
        theme: ThemeData(
          primaryColor: Colors.white,
          scaffoldBackgroundColor: Colors.black,
          fontFamily: 'Montserrat',
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            color: Colors.black,
            titleTextStyle: TextStyle(
              fontSize: 20.0,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            iconTheme: IconThemeData(
              color: Colors.white,
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.black,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white54,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(
              fontSize: 14.0,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.normal,
              color: Colors.white,
            ),
            bodyMedium: TextStyle(
              fontSize: 16.0,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.normal,
              color: Colors.white,
            ),
            titleLarge: TextStyle(
              fontSize: 20.0,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Colors.white,
          ),
          textSelectionTheme: const TextSelectionThemeData(
            selectionColor: Color.fromARGB(130, 158, 158, 158),
            selectionHandleColor: Color.fromARGB(130, 158, 158, 158),
            cursorColor: Colors.white,
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: Colors.white,
            contentTextStyle: const TextStyle(color: Colors.black),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        ),
        home: const SplashScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/topics': (context) => TopicSelectionScreen(user: FirebaseAuth.instance.currentUser!),
          '/admin': (context) => const AdminPanelScreen(),
          '/privacy-policy': (context) => const PrivacyPolicyScreen(),
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final UserModel userModel;

  const MainScreen({super.key, required this.userModel});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;  // Cambia l'indice selezionato
    });
  }

  @override
  Widget build(BuildContext context) {
    // Inizializziamo _screens qui, dove è possibile accedere a widget
    final List<Widget> _screens = [
      const CourseScreen(),
      const HomeScreen(),
      const QuizScreen(),
      SettingsScreen(currentUser: widget.userModel),  // Qui ora puoi accedere a widget.userModel
    ];

    return Scaffold(
      body: _screens[_selectedIndex],  // Mostra la schermata selezionata
      bottomNavigationBar: BottomNavigationBarCustom(
        currentUser: widget.userModel,
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,  // Callback per cambiare schermata
      ),
    );
  }
}