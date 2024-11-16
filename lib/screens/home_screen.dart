import 'package:Just_Learn/screens/access/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'shorts_screen.dart';
import '../models/user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedTopic;
  String? selectedSubtopic;
  bool isLoading = true;
  UserModel? currentUser;
  List<String> allTopics = [];
  List<String> subtopics = [];
  String videoTitle = ""; // Titolo iniziale del video
  bool showSavedVideos = false;
  bool showArticles = false; // Aggiungi questa variabile
  int _currentPage = 1;  // Inizia da 1 perché il video è al centro
  

  @override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (allTopics.isEmpty) {
    _loadTopicsAndUser();
  }
}

void _toggleSavedVideos() {
  setState(() {
    showSavedVideos = !showSavedVideos; // Alterna la variabile
  });
  // Non serve ricaricare tutto qui perché la chiave cambierà e forzerà il ri-rendering
}

  Future<void> _loadTopicsAndUser() async {
    final user = FirebaseAuth.instance.currentUser;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (user != null || (args != null && args['isGuest'] == true)) {
      try {
        if (user != null) {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

          if (userDoc.exists) {
            final userData = userDoc.data();

            if (userData != null) {
              final userModel = UserModel.fromMap(userData);
              await _updateConsecutiveDays(userModel);

              if (mounted) {
                setState(() {
                  currentUser = userModel;
                  selectedTopic = userModel.topics.isNotEmpty ? userModel.topics.first : 'Just Learn';
                  selectedSubtopic = selectedSubtopic ?? null; // Manteniamo il subtopic se già selezionato
                });
              }
            }
          } else {
            _redirectToLogin();
          }
        } else {
          // Logica per l'ospite
          if (mounted) {
            setState(() {
              selectedTopic = 'Just Learn';
              selectedSubtopic = null;
            });
          }
        }
      } catch (e) {
        print('Error loading user: $e');
        if (mounted) {
          _redirectToLogin();
        }
      }
    } else {
      _redirectToLogin();
    }

    if (selectedTopic == null) {
      setState(() {
        selectedTopic = 'Just Learn';
        selectedSubtopic = null;
      });
    }
  }

  // Metodo per aggiornare i coins dell'utente
void _updateCoins(int newCoins) {
  if (mounted) {
    setState(() {
      currentUser?.coins = newCoins;
    });
  }
}

Future<void> _updateConsecutiveDays(UserModel user) async {
  final now = DateTime.now();
  final lastAccess = user.lastAccess;
  final difference = DateTime(now.year, now.month, now.day)
      .difference(DateTime(lastAccess.year, lastAccess.month, lastAccess.day))
      .inDays;

  if (difference == 1) {
    // Incrementa se l'accesso è avvenuto il giorno successivo
    user.consecutiveDays += 1;
  } else if (difference > 1) {
    // Resetta a 0 se sono passati più di un giorno
    user.consecutiveDays = 0;
  }
  // Se difference == 0, nessuna modifica

  user.lastAccess = now;

  await FirebaseFirestore.instance.collection('users').doc(user.uid).update(user.toMap());
}

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    });
  }

 void _updateVideoTitle(String newTitle) {
  if (mounted) { // Controlla se il widget è ancora montato
    setState(() {
      videoTitle = newTitle;
    });
  }
}

// Aggiungi questo metodo per gestire il cambio pagina
void _onPageChanged(int page) {
  print('Page changed to: $page');
  setState(() {
    _currentPage = page;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ShortsScreen(
            key: ValueKey('$selectedTopic-$selectedSubtopic-$showSavedVideos'),
            selectedTopic: selectedTopic,
            selectedSubtopic: selectedSubtopic,
            onVideoTitleChange: _updateVideoTitle,
            onCoinsUpdate: _updateCoins,
            showSavedVideos: showSavedVideos,
            onPageChanged: _onPageChanged,
          ),
          // Contenitore superiore che include sia l'indicatore che i coins
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 4.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Container dei coins
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: ShapeDecoration(
                      color: Color(0x93333333),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color: Colors.white.withOpacity(0.10000000149011612),
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          color: Colors.yellowAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          '${currentUser?.coins ?? 0}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.48,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Indicatore di pagina
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        height: 12,
                        width: _currentPage == index ? 32 : 12,
                        decoration: BoxDecoration(
                          color: _currentPage == index 
                            ? Colors.yellowAccent 
                            : Color(0x93333333),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(  // Aggiunto il bordo bianco
                            color: Colors.white.withOpacity(0.10000000149011612),
                            width: 1,
                          ),
                        ),
                      );
                    }),
                  ),
                  // Spazio vuoto per bilanciare il layout
                  SizedBox(
                    width: 80, // Larghezza approssimativa del container dei coins
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}