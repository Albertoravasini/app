import 'package:Just_Learn/models/user.dart';
import 'package:Just_Learn/screens/subscription_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }
  final List<Map<String, dynamic>> quizzes = [
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
    'description': 'Answer questions about diet and fitness',
    'image': 'assets/Fitnes.png',
  },
  {
    'title': 'Daily Quiz',
    'description': '',
    'isQuestionMark': true,
  },
  {
    'title': 'Train Your Mistakes',
    'description': '',
    'isQuestionMark': true,
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

  Widget _buildMysteryCard(double width, String title, String description) {
  return GestureDetector(
    onTap: () {
      if (title == 'Daily Quiz' || title == 'Train Your Mistakes') {
        // Mostra un messaggio che la carta non è disponibile per entrambi i titoli
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('This card is not yet available.'),
          ),
        );
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
                Text(
                  '100', // Costo della carta in coins
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  // Costruisce la card per l'upgrade
// Costruisce la card per l'upgrade
// Costruisce la card per l'upgrade
Widget _buildUpgradeProCard() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Padding contenuto
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

  // Costruisce il carousel dei quiz
  Widget _buildCarousel() {
  return Expanded(
    child: CarouselSlider.builder(
      itemCount: quizzes.length,
      itemBuilder: (BuildContext context, int index, int realIndex) {
        final quiz = quizzes[index];
        final isCenter = index == _current;
        final width = isCenter ? 350.0 : 300.0;

        if (quiz['isQuestionMark'] == true) {
          return _buildMysteryCard(width, quiz['title'], quiz['description']);
        } else {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuestionScreen(topic: quiz['title']!),
                ),
              );
            },
            child: QuizCard(
              title: quiz['title']!,
              description: quiz['description']!,
              imagePath: quiz['image']!,
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