import 'package:flutter/material.dart';
import 'package:Just_Learn/models/course.dart';
import 'package:Just_Learn/widgets/course_question_card.dart'; // Import del widget personalizzato
import 'package:youtube_player_flutter/youtube_player_flutter.dart'; // Import del lettore video
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Just_Learn/models/level.dart'; // Importa il modello aggiornato LevelStep

class LevelScreen extends StatefulWidget {
  final Section section;

  const LevelScreen({super.key, required this.section});

  @override
  _LevelScreenState createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  int _currentStep = 0;
  bool sectionCompleted = false;
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    _initializePlayer(widget.section.steps[_currentStep]);
    _loadUserProgress(); // Carica il progresso dell'utente
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  // Inizializza il lettore video se lo step è un video
  // Inizializza il lettore video se lo step è un video
  void _initializePlayer(LevelStep step) {
    if (step.type == 'video' && step.content.isNotEmpty) { // Usa 'content' per l'URL del video
      _youtubeController = YoutubePlayerController(
        initialVideoId: YoutubePlayer.convertUrlToId(step.content)!, // Usa 'content' come URL del video
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
        ),
      );
    }
  }

  // Carica il progresso dell'utente da Firestore
  Future<void> _loadUserProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshot = await userDoc.get();

      if (snapshot.exists) {
        final userData = snapshot.data()!;
        setState(() {
          _currentStep = userData['currentSteps'][widget.section.title] ?? 0;
          sectionCompleted = (userData['completedSections'] ?? []).contains(widget.section.title);
        });
      }
    }
  }

  // Salva il progresso dell'utente su Firestore
  Future<void> _saveUserProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

      await userDoc.update({
        'currentSteps.${widget.section.title}': _currentStep,
        if (sectionCompleted) 'completedSections': FieldValue.arrayUnion([widget.section.title]),
      });
    }
  }

  // Gestione del completamento di uno step
  void _onCompleteStep() {
    setState(() {
      _currentStep += 1;
      if (_currentStep >= widget.section.steps.length) {
        sectionCompleted = true;
        _saveUserProgress(); // Salva il completamento della sezione
      } else {
        _saveUserProgress(); // Salva il progresso corrente
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.section.steps;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 30),

          // Barra di progresso personalizzata con pulsante "back"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 10), // Spazio tra il pulsante e la barra di progresso

                Expanded(
                  child: Container(
                    height: 15,
                    decoration: ShapeDecoration(
                      color: const Color(0xFF181819),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          // Solo il cambio di pagina incrementa la larghezza della barra
                          width: (312 * (_currentStep + 1) / steps.length).clamp(0, 312),
                          height: 15,
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 0),

          // Titolo della sezione
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: ShapeDecoration(
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Center(
              child: Text(
                widget.section.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: 0.66,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 5),

          // Corpo principale della pagina con PageView verticale
          Expanded(
            child: PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: steps.length,
              controller: PageController(initialPage: _currentStep),
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index; // Aggiorna il passo corrente solo quando cambia pagina
                  _initializePlayer(steps[index]); // Inizializza il video per il nuovo step
                  _saveUserProgress(); // Salva il progresso ogni volta che cambia pagina
                });
              },
              itemBuilder: (context, index) {
                final step = steps[index];

                return Center();
              },
            ),
          ),
        ],
      ),
    );
  }
}
