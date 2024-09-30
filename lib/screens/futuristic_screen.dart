import 'package:flutter/material.dart';

class ComingSoonAI extends StatefulWidget {
  const ComingSoonAI({super.key});

  @override
  _ComingSoonAIState createState() => _ComingSoonAIState();
}

class _ComingSoonAIState extends State<ComingSoonAI> {
  bool _isUpdated = false; // Variabile per gestire lo stato

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600), // Durata della transizione
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: _isUpdated
                ? _buildSuccessCheck() // Mostra l'animazione del check
                : _buildInitialContent(), // Mostra il contenuto iniziale
          ),
        ),
      ),
    );
  }

  // Costruisce l'interfaccia iniziale con l'icona, il testo e il pulsante
  Widget _buildInitialContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
  'assets/mingcute_ai-fill.png', // Immagine che rappresenta l'AI
  width: 80,
  height: 80,
),
        const SizedBox(height: 20),
        Text(
          'AI POWERED',
          style: TextStyle(
            fontSize: 35,
            fontFamily: 'SF Pro Display',
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'A new era of intelligence is coming soon.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'SF Pro Text',
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _isUpdated = true; // Cambia stato quando il pulsante viene cliccato
            });
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Stay Updated',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // Costruisce l'animazione del check di successo
  Widget _buildSuccessCheck() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline, // Icona del check
            size: 100,
            color: Colors.greenAccent, // Colore verde per successo
          ),
          const SizedBox(height: 20),
          Text(
            'You\'re Updated!',
            style: TextStyle(
              fontSize: 24,
              fontFamily: 'SF Pro Display',
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}