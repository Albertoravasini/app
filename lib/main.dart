// main.dart
import 'package:Just_Learn/screens/access/login_screen.dart';
import 'package:Just_Learn/screens/access/register_screen.dart';
import 'package:Just_Learn/screens/access/topic_selection_screen.dart';
import 'package:Just_Learn/screens/access/splash_screen.dart';
import 'package:Just_Learn/screens/course_screen.dart';
import 'package:Just_Learn/screens/quiz_screen.dart';
import 'package:Just_Learn/services/notification_service.dart';
import 'package:Just_Learn/services/auth_service.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'admin_panel/admin_panel_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/bottom_navigation_bar_custom.dart'; // Importa la barra di navigazione personalizzata
import 'screens/support_screen.dart'; // Importa la schermata di supporto
import 'screens/profile_screen.dart'; // Importa la schermata del profilo insegnante
import 'web/screens/web_home_screen.dart';
import 'screens/NotificationsScreen.dart';

// Navigator key globale per accedere al contesto fuori dal MaterialApp
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Aggiungi questa funzione helper
bool get isWeb {
  try {
    return kIsWeb;
  } catch (e) {
    return false;
  }
}

// Funzione di gestione dei messaggi in background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).then((app) async {
      print('Firebase inizializzato correttamente');
    }).catchError((e) {
      if (e.toString().contains('duplicate-app')) {
        print('Firebase già inizializzato, continuo...');
      } else {
        print('Errore inizializzazione Firebase: $e');
      }
    });

    // Sposta l'inizializzazione del NotificationService fuori dal then
    final notificationService = NotificationService();
    await notificationService.initialize();
    print('NotificationService inizializzato');
    
  } catch (e) {
    print('Errore generale: $e');
  }

  runApp(const MyApp(user: null));
}

class MyApp extends StatelessWidget {
  final User? user;

  const MyApp({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: MultiProvider(
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
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: ThemeData(
            primaryColor: Colors.white,
            scaffoldBackgroundColor: const Color(0xFF121212),
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
          initialRoute: '/',
          routes: {
            '/': (context) => isWeb ? WebHomeScreen() : SplashScreen(),
            '/home': (context) => const HomeScreen(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/topics': (context) => TopicSelectionScreen(user: FirebaseAuth.instance.currentUser!),
            '/admin': (context) => const AdminPanelScreen(),
            '/privacy-policy': (context) => const PrivacyPolicyScreen(),
            '/support': (context) => const SupportScreen(),
            '/profile': (context) => ProfileScreen(
              currentUser: ModalRoute.of(context)!.settings.arguments as UserModel
            ),
          },
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final UserModel userModel;
  final int initialIndex;

  const MainScreen({super.key, required this.userModel, this.initialIndex = 1});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex == 1 ? 2 : widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _checkDailyReset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      const CourseScreen(),
      const QuizScreen(),
      const HomeScreen(),
      const NotificationsScreen(),
      SettingsScreen(currentUser: widget.userModel),
    ];

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBarCustom(
        currentUser: widget.userModel,
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  void _checkDailyReset() async {
    DateTime now = DateTime.now();
    
    // Imposta la data corrente e l'ultimo accesso a mezzanotte per il confronto
    DateTime todayAtMidnight = DateTime(now.year, now.month, now.day);
    DateTime lastAccessAtMidnight = DateTime(
      widget.userModel.lastAccess.year,
      widget.userModel.lastAccess.month,
      widget.userModel.lastAccess.day,
    );

    // Se la data di oggi a mezzanotte è successiva all'ultimo accesso
    if (todayAtMidnight.isAfter(lastAccessAtMidnight)) {
      // Effettua il reset giornaliero
      widget.userModel.dailyVideosCompleted = 0;
      widget.userModel.dailyQuizFreeUses = 0;

      // Aggiorna lastAccess a oggi, rappresentato da oggi a mezzanotte
      widget.userModel.lastAccess = todayAtMidnight;

      // Salva su Firestore solo i campi modificati
      await FirebaseFirestore.instance.collection('users').doc(widget.userModel.uid).update({
        'dailyVideosCompleted': 0,
        'dailyQuizFreeUses': 0,
        'lastAccess': todayAtMidnight.toIso8601String(),
      });
    } else {
      // Aggiorna solo lastAccess per indicare l'accesso senza reset
      await FirebaseFirestore.instance.collection('users').doc(widget.userModel.uid).update({
        'lastAccess': now.toIso8601String(),
      });
    }
  }
}

// Aggiungi questa funzione globale
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Assicurati che Firebase sia inizializzato anche in background
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  print('Gestione notifica in background: ${message.messageId}');
}