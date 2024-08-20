import 'package:Just_Learn/models/user.dart';
import 'package:Just_Learn/screens/Privacy_Policy_Screen.dart';
import 'package:Just_Learn/screens/access/welcome_screen.dart';
import 'package:Just_Learn/screens/guest_register_prompt_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/access/login_screen.dart';
import 'screens/access/register_screen.dart';
import 'screens/access/topic_selection_screen.dart';
import 'services/auth_service.dart';
import 'admin_panel/admin_panel_screen.dart';
import './admin_panel/user_management_screen.dart.dart';
import './admin_panel/level_management_screen.dart.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/video_list_screen.dart'; // Importa la nuova schermata

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  try {
    await createTopics();
  } catch (e) {
    print('Error creating topics: $e');
  }
  runApp(MyApp());
}

Future<void> createTopics() async {
  final topics = ['Finanza'];
  final topicsCollection = FirebaseFirestore.instance.collection('topics');
  
  try {
    for (var topic in topics) {
      final doc = await topicsCollection.doc(topic).get();
      if (!doc.exists) {
        await topicsCollection.doc(topic).set({});
      }
    }
  } catch (e) {
    print('Error while accessing Firestore: $e');
    throw e;
  }
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
              color: Colors.white,
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
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Scaffold(body: Center(child: CircularProgressIndicator()));
                  } else if (snapshot.hasError) {
                    return Scaffold(
                      body: Center(
                        child: Text('Errore: ${snapshot.error}'),
                      ),
                    );
                  } else if (snapshot.hasData && snapshot.data != null) {
                    final userData = snapshot.data!.data() as Map<String, dynamic>?;
                    if (userData == null) {
                      return LoginScreen();
                    }
                    final userModel = UserModel.fromMap(userData);
                    if (userModel.role == 'admin') {
                      return AdminPanelScreen();
                    } else {
                      return HomeScreen();
                    }
                  } else {
                    return LoginScreen();
                  }
                },
              );
            }
          },
        ),
        routes: {
  '/home': (context) => HomeScreen(),
  '/login': (context) => LoginScreen(),
  '/register': (context) => RegisterScreen(),
  '/topics': (context) => TopicSelectionScreen(user: FirebaseAuth.instance.currentUser!),
  '/admin': (context) => AdminPanelScreen(),
  '/admin/users': (context) => UserManagementScreen(),
  '/admin/levels': (context) => LevelManagementScreen(),
  '/welcome': (context) => WelcomeScreen(),
  '/videos': (context) => VideoListScreen(),
  '/privacy-policy': (context) => PrivacyPolicyScreen(), // Aggiungi questa linea
  '/guest_register_prompt': (context) => GuestRegisterPromptScreen(),
},
      ),
    );
  }
}