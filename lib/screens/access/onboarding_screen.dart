import 'package:Just_Learn/screens/access/sign_in_options_screen.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  // Definisci i testi e le immagini per le pagine
  final List<Map<String, String>> _onboardingData = [
    {
      'image': 'assets/Just_Learn.png',
      'title': 'Turn your free time into a learning opportunity',
      'subtitle': 'Stop wasting your time',
    },
    {
      'image': 'assets/Cap.png', // Seconda immagine
      'title': 'Learn something new everyday',
      'subtitle': 'Learn from a mini-course',
    },
    {
      'image': 'assets/thunder.png', // Terza immagine
      'title': 'Want to learn something fast?',
      'subtitle': 'Take a quick quiz and accumulate coins',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PageView per scorrere le pagine
          PageView.builder(
            controller: _pageController,
            itemCount: _onboardingData.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black, // Colore di sfondo
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Immagine di sfondo
                    Image.asset(
                      _onboardingData[index]['image']!,
                      width: 200, // Dimensione dell'immagine
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 30),
                    // Testo principale
                    Text(
                      _onboardingData[index]['title']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Sottotitolo
                    Text(
                      _onboardingData[index]['subtitle']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Puntini indicatori
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_onboardingData.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  height: 10,
                  width: _currentPage == index ? 20 : 10,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(5),
                  ),
                );
              }),
            ),
          ),
          // Bottone "Continue"
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                if (_currentPage == _onboardingData.length - 1) {
                  // Se siamo all'ultima pagina, esegui l'azione
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const SignInOptionsScreen()), // Vai alla schermata successiva
                  );
                } else {
                  // Altrimenti vai alla pagina successiva
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    _currentPage == _onboardingData.length - 1 ? 'Get Started' : 'Continue',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}