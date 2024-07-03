import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/topic_selection_screen.dart';
import 'services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
          appBarTheme: AppBarTheme(
            color: Colors.black,
            titleTextStyle: TextStyle(
              fontSize: 20.0,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            iconTheme: IconThemeData(
              color: Colors.white, // Imposta il colore delle icone nell'AppBar
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.black,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white54,
          ),
          textTheme: TextTheme(
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
              textStyle: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        home: Consumer<User?>(
          builder: (context, user, _) {
            if (user == null) {
              return LoginScreen();
            } else {
              return HomeScreen();
            }
          },
        ),
        routes: {
          '/home': (context) => HomeScreen(),
          '/login': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/topics': (context) => TopicSelectionScreen(user: FirebaseAuth.instance.currentUser!),
        },
      ),
    );
  }
}