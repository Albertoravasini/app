import 'package:Just_Learn/screens/access/login_screen.dart';
import 'package:Just_Learn/screens/access/register_screen.dart';
import 'package:Just_Learn/screens/access/topic_selection_screen.dart';
import 'package:Just_Learn/screens/access/welcome_screen.dart';
import 'package:Just_Learn/screens/access/splash_screen.dart'; // Importa la Splash Screen
import 'package:Just_Learn/screens/futuristic_screen.dart';
import 'package:Just_Learn/services/auth_service.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:firebase_core/firebase_core.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              textStyle: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),// Personalizza il colore della rotella di caricamento (CircularProgressIndicator)
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Colors.white, // Cambia la rotella di caricamento a bianco
          ),
          // Personalizza il colore dell'evidenziazione del testo
          textSelectionTheme: const TextSelectionThemeData(
            selectionColor: Color.fromARGB(130, 158, 158, 158), // Colore dell'evidenziazione del testo
            selectionHandleColor: Color.fromARGB(130, 158, 158, 158), // Colore del "manico" di selezione
            cursorColor: Colors.white, // Colore della lineetta del cursore
          ),
          // Personalizzazione globale degli errori con SnackBar
          snackBarTheme: SnackBarThemeData(
            backgroundColor: Colors.white, // Sfondo bianco
            contentTextStyle: const TextStyle(color: Colors.black), // Testo nero
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Bordi arrotondati
            ),
            behavior: SnackBarBehavior.floating, // SnackBar fluttuante sopra il contenuto
          ),
        ),
        home: const SplashScreen(), // SplashScreen come la schermata iniziale
        routes: {
          '/home': (context) => const HomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/topics': (context) => TopicSelectionScreen(user: FirebaseAuth.instance.currentUser!),
          '/admin': (context) => const AdminPanelScreen(),
          '/welcome': (context) => const WelcomeScreen(),
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
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const Center(child: ComingSoonAI()),
    const SettingsScreen(currentUser: null),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBarCustom(
        currentUser: widget.userModel,
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}