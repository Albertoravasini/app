import 'package:Just_Learn/models/user.dart';
import 'package:Just_Learn/screens/subscription_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:Just_Learn/screens/question_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  UserModel? currentUser;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  final List<Map<String, dynamic>> quizzes = [
     {
      'title': 'Daily Quiz',
      'description': 'Test what you have learned about your recent viewed videos',
      'isQuestionMark': true,
      'cost': 50, // Costo in coin
    },
    {
      'title': 'JustLearn',
      'description': 'Explore the world and test your culture',
      'image': 'assets/General Culture.png',
    },
    {
      'title': 'History',
      'description': 'Test your knowledge about historical events and figures.',
      'image': 'assets/History.png',
    },
    {
      'title': 'Fitness',
      'description': 'Learn about diet and fitness',
      'image': 'assets/Fitnes.png',
    },
    {
      'title': 'Business',
      'description': 'Learn about investments, entrepreneurship, finance and more ',
      'image': 'assets/business.png',
    },
    {
      'title': 'Train Your Mistakes',
      'description': '',
      'isQuestionMark': true,
      'cost': 100
    },
  ];

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          currentUser = UserModel.fromMap(userDoc.data()!);
        });
      }
    }
  }

  Future<void> _subtractCoins(int amount) async {
    if (currentUser != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
      await userDoc.update({
        'coins': FieldValue.increment(-amount),
      });

      setState(() {
        currentUser!.coins -= amount;
      });
    }
  }

Future<void> _handleLastViewedVideosQuiz(bool isFree) async {
  if (currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Devi essere loggato per accedere a questa funzionalità.'),
      ),
    );
    return;
  }

  DateTime now = DateTime.now();
  DateTime todayAtMidnight = DateTime(now.year, now.month, now.day);
  DateTime lastAccessAtMidnight = DateTime(
    currentUser!.lastAccess.year,
    currentUser!.lastAccess.month,
    currentUser!.lastAccess.day,
  );

  // Verifica se è un nuovo giorno e resetta i campi giornalieri se necessario
  if (todayAtMidnight.isAfter(lastAccessAtMidnight)) {
    currentUser!.dailyVideosCompleted = 0;
    currentUser!.dailyQuizFreeUses = 0;
    currentUser!.lastAccess = todayAtMidnight;

    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
      'dailyVideosCompleted': 0,
      'dailyQuizFreeUses': 0,
      'lastAccess': todayAtMidnight.toIso8601String(),
    });
  }

  // Gestisci l'uso gratuito del quiz giornaliero
  if (!isFree) {
    if (currentUser!.coins < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Non hai abbastanza coin per accedere a questo quiz.'),
        ),
      );
      return;
    } else {
      await _subtractCoins(50);
    }
  } else {
    // Incrementa gli utilizzi gratuiti del quiz giornaliero
    currentUser!.dailyQuizFreeUses += 1;
    await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
      'dailyQuizFreeUses': currentUser!.dailyQuizFreeUses,
    });
  }

  // Recupera gli ultimi video completati
  List<VideoWatched> completedVideos = currentUser!.WatchedVideos.values
      .expand((videoList) => videoList)
      .where((video) => video.completed)
      .toList();

  // Ordina per watchedAt decrescente
  completedVideos.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));

  // Prendi gli ultimi 5
  completedVideos = completedVideos.take(5).toList();

  // Controlla se ci sono almeno 3 video completati
  if (completedVideos.length < 3) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Devi completare almeno 3 video per accedere a questo quiz.'),
      ),
    );
    return;
  }

  // Raccogli gli ID dei video
  List<String> videoIds = completedVideos.map((video) => video.videoId).toList();

  // Naviga a QuestionScreen passando gli ID dei video
  Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => QuestionScreen(topic: 'Daily Quiz', videoIds: videoIds),
  ),
).then((_) {
  // Quando si ritorna al QuizScreen, aggiorna lo stato per ricaricare il costo
  setState(() {
    _loadCurrentUser(); // Ricarica l'utente per aggiornare i dati come il costo
  });
});
}

void _startQuiz(String quizTitle) async {
  _analytics.logEvent(
    name: 'quiz_start',
    parameters: {
      'quiz_title': quizTitle,
      'user_id': FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user',
    },
  );

  if (quizTitle == 'Daily Quiz' && currentUser != null) {
    int requiredVideosForNextFreeUnlock = 3 + (currentUser!.dailyQuizFreeUses * 5);
    bool isFree = currentUser!.dailyVideosCompleted >= requiredVideosForNextFreeUnlock;

    await _handleLastViewedVideosQuiz(isFree).then((_) {
      // Forza l'aggiornamento della UI al ritorno
      setState(() {
        _loadCurrentUser(); // Ricarica l'utente per assicurarsi che sia aggiornato
      });
    });
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionScreen(topic: quizTitle),
      ),
    );
  }
}

  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background dinamico
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black87, Colors.black54],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40), // Spazio per togliere AppBar

                // Titolo Quiz allineato a sinistra
                const Text(
                  'Quiz',
                  style: TextStyle(
                    fontSize: 36,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),

                // Descrizione sotto il titolo
                const Text(
                  'Take a quick quiz and test what you’ve learned. New quizzes every day!',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 30),

                // Sezione Upgrade Pro
                _buildUpgradeProCard(),

                const SizedBox(height: 24),

                // Titolo Popular Quiz
                const Text(
                  'Popular Quizzes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 16),

                // Carousel Slider
                _buildCarousel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildMysteryCard(double width, String title, String description, int cost) {
  bool isFree = false;

  if (title == 'Daily Quiz' && currentUser != null) {
    int requiredVideosForNextFreeUnlock = 3 + (currentUser!.dailyQuizFreeUses * 5);
    if (currentUser!.dailyVideosCompleted >= requiredVideosForNextFreeUnlock) {
      isFree = true;
    }
  }

  return GestureDetector(
    onTap: () async {
      if (title == 'Daily Quiz') {
        await _handleLastViewedVideosQuiz(isFree);
      } else if (title == 'Train Your Mistakes') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Questa carta non è ancora disponibile.'),
          ),
        );
      } else {
        // Altre logiche per altri quiz se necessario
      }
    },
    child: Stack(
      children: [
        Container(
          width: width,
          margin: const EdgeInsets.symmetric(vertical: 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.yellow.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '?',
                style: TextStyle(
                  fontSize: 100,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  fontFamily: 'Montserrat',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.yellow, size: 25),
                const SizedBox(width: 8),
                if (isFree) ...[
                  const Text(
                    'FREE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    'assets/free_icon.png', // Percorso dell'icona
                    width: 24,
                    height: 24,
                  ),
                ] else ...[
                  Text(
                    '$cost',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildCarousel() {
    return Expanded(
      child: CarouselSlider.builder(
        itemCount: quizzes.length,
        itemBuilder: (BuildContext context, int index, int realIndex) {
          final quiz = quizzes[index];
          final isCenter = index == _current;
          final width = isCenter ? 350.0 : 300.0;

          if (quiz['isQuestionMark'] == true) {
            return _buildMysteryCard(
              width,
              quiz['title'],
              quiz['description'],
              quiz['cost'] ?? 0, // Passa il costo, default a 0 se non definito
            );
          } else {
            return GestureDetector(
              onTap: () {
                _startQuiz(quiz['title']!);
              },
              child: QuizCard(
                title: quiz['title']!,
                description: quiz['description']!,
                imagePath: quiz['image'] ?? 'assets/default.png', // Gestisci le carte senza immagine
                width: width,
              ),
            );
          }
        },
        options: CarouselOptions(
          height: 450,
          enlargeCenterPage: true,
          enableInfiniteScroll: true,
          viewportFraction: 0.85,
          onPageChanged: (index, reason) {
            setState(() {
              _current = index;
            });
          },
        ),
      ),
    );
  }

  // Costruisce la card per l'upgrade
// Costruisce la card per l'upgrade
// Costruisce la card per l'upgrade
Widget _buildUpgradeProCard() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), // Padding contenuto
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12), // Bordi arrotondati
      border: Border.all(color: Colors.white12),
    ),
    child: Row(
      children: [
        // Icona stilizzata
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.stars_rounded,
            color: Colors.yellowAccent,
            size: 28, // Dimensioni dell'icona leggermente ridotte
          ),
        ),
        const SizedBox(width: 12), // Spazio tra icona e testo
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              // Titolo principale
              Text(
                'Upgrade to Pro',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18, // Font leggermente ridotto
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              // Testo descrittivo
              Text(
                'Unlock unlimited quizzes and access all courses.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12, // Font ridotto per il testo descrittivo
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Pulsante "Upgrade" con dimensioni compatte
        SizedBox(
          width: 100, // Larghezza coerente ma più compatta
          child: ElevatedButton(
            onPressed: () {
              // Naviga alla schermata di abbonamento
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellowAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12), // Altezza ridotta
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // Bordi leggermente arrotondati
              ),
            ),
            child: const Text(
              'Upgrade',
              style: TextStyle(
                fontSize: 14, // Font leggermente ridotto
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}


}

// Design della card del quiz
class QuizCard extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final double width;

  const QuizCard({
    Key? key,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(vertical: 0), // Margine tra le card
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20), // Bordi arrotondati
        child: Stack(
          children: [
            // Immagine di sfondo con effetto oscurato
            Positioned.fill(
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),
            ),
            // Overlay nero traslucido sopra l'immagine
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Contenuto della card (titolo, descrizione, pulsante)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titolo del quiz
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Descrizione del quiz
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}