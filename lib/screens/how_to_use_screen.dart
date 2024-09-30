import 'package:flutter/material.dart';

class HowToUseScreen extends StatefulWidget {
  @override
  _HowToUseScreenState createState() => _HowToUseScreenState();
}

class _HowToUseScreenState extends State<HowToUseScreen> {
  late PageController _horizontalPageController;
  late PageController _verticalPageController;
  int currentHorizontalPage = 1; // Partiamo dalla seconda immagine (indice 1)
  int currentVerticalPage = 0; // Partiamo dalla prima pagina verticale

  @override
  void initState() {
    super.initState();
    _horizontalPageController = PageController(initialPage: currentHorizontalPage);
    _verticalPageController = PageController(initialPage: currentVerticalPage);
  }

  @override
  void dispose() {
    _horizontalPageController.dispose();
    _verticalPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Use'),
        backgroundColor: Colors.black,
      ),
      body: PageView(
        controller: _verticalPageController,
        scrollDirection: Axis.vertical, // Scorrimento verticale
        children: [
          _buildHorizontalPageView(),
          _buildPage('assets/SHORTS1.png', 'Go to Next Video', swipeDirection: 'up'), // Immagine quando scorri in basso
        ],
      ),
    );
  }

  Widget _buildHorizontalPageView() {
    return PageView(
      controller: _horizontalPageController,
      scrollDirection: Axis.horizontal, // Scorrimento orizzontale
      onPageChanged: (index) {
        setState(() {
          currentHorizontalPage = index;
        });
      },
      children: [
        _buildPage('assets/feature.png', 'Discover Feature', swipeDirection: 'right'),
        _buildPage('assets/Shorts.png', 'Swipe', swipeDirection: 'all'), // Immagine centrale
        _buildPage('assets/question.png', 'Answer Questions', swipeDirection: 'left'),
      ],
    );
  }

  Widget _buildPage(String imagePath, String title, {required String swipeDirection}) {
    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Testo in alto, separato dall'immagine
            Padding(
              padding: const EdgeInsets.only(top: 1.0, bottom: 10.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            // Centrare l'immagine con bordi arrotondati e ridotta leggermente
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.60, // Leggermente ridotta (78%)
                height: MediaQuery.of(context).size.height * 0.66, // Altezza leggermente ridotta (55%)
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16), // Bordi arrotondati
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3), // Ombra per l'immagine
                      spreadRadius: 3,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover, // Copre tutto lo spazio senza deformare
                  ),
                ),
              ),
            ),
          ],
        ),

        // Frecce ai lati dell'immagine e freccia verso il basso
        if (swipeDirection == 'all')
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Freccia sinistra
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Icon(
                      Icons.arrow_back,
                      size: 30, // Ridotto a 30
                      color: Colors.white,
                    ),
                  ),
                  // Freccia destra
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 30, // Ridotto a 30
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
        // Freccia verso il basso centrata sotto l'immagine
        if (swipeDirection == 'all')
          Positioned(
            bottom: 20,
            left: MediaQuery.of(context).size.width * 0.5 - 15, // Centra la freccia in base alla larghezza dello schermo
            child: Icon(
              Icons.arrow_downward,
              size: 30, // Ridotto a 30
              color: Colors.white,
            ),
          ),
      ],
    );
  }
}