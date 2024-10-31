import 'package:Just_Learn/widgets/course_question_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Just_Learn/models/level.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart'; // Importa il video player
import 'dart:math';

import 'package:youtube_player_flutter/youtube_player_flutter.dart'; // Per la selezione casuale

class QuestionScreen extends StatefulWidget {
  final String topic;
  final List<String>? videoIds; // Nuovo parametro

const QuestionScreen({Key? key, required this.topic, this.videoIds}) : super(key: key);

  @override
  _QuestionScreenState createState() => _QuestionScreenState();
}


class _QuestionScreenState extends State<QuestionScreen> {
  List<LevelStep> selectedQuestions = [];
  YoutubePlayerController? _youtubePlayerController;
  UserModel? currentUser;
  int currentIndex = 0;
  PageController _pageController = PageController();
  List<Map<String, dynamic>> selectedQuestionsWithLevels = []; // Lista per domande con livello

  VideoPlayerController? _videoPlayerController;
  bool _showVideoButton = false; // Stato per mostrare il pulsante video

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
void dispose() {
  _youtubePlayerController?.dispose(); // Smonta il controller YouTubePlayer
  _pageController.dispose();
  super.dispose();
}

Future<void> _loadQuestions() async {
    final user = FirebaseAuth.instance.currentUser;
    print("Caricamento delle domande iniziato...");

    if (user != null) {
      print("Utente autenticato: ${user.uid}");
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          currentUser = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        });
        print("Dati utente caricati correttamente: ${currentUser?.name}");
      } else {
        print("Documento utente non trovato!");
      }
    } else {
      print("Nessun utente autenticato.");
    }

    List<Map<String, dynamic>> allStepsWithLevels = [];

    if (widget.topic == 'Daily Quiz' && widget.videoIds != null && widget.videoIds!.isNotEmpty) {
      // Recupera tutti i livelli
      final levelsSnapshot = await FirebaseFirestore.instance.collection('levels').get();
      for (var levelDoc in levelsSnapshot.docs) {
        final level = Level.fromFirestore(levelDoc);
        for (int i = 0; i < level.steps.length; i++) {
          final step = level.steps[i];
          if (step.type == 'video' && widget.videoIds!.contains(step.content)) {
            if (i + 1 < level.steps.length) {
              final questionStep = level.steps[i + 1];
              if (questionStep.type == 'question') {
                allStepsWithLevels.add({'step': questionStep, 'level': level});
              }
            }
          }
        }
      }

      print("Numero totale di domande selezionate: ${allStepsWithLevels.length}");

      // Mescola le domande selezionate
      allStepsWithLevels.shuffle();

      // Prendi le prime 5 domande o quante ne sono disponibili
      setState(() {
        selectedQuestionsWithLevels = allStepsWithLevels.take(5).toList();
      });

      if (selectedQuestionsWithLevels.isEmpty) {
        print("Errore: Nessuna domanda selezionata per 'Daily Quiz'.");
      } else {
        print("Caricamento completato, domande pronte per essere mostrate.");
      }
    } else {
      // Logica esistente per altri topic
      QuerySnapshot querySnapshot;

      if (widget.topic == 'JustLearn') {
        querySnapshot = await FirebaseFirestore.instance.collection('levels').get();
        print("Tutti i livelli caricati per il topic 'JustLearn'.");
      } else {
        querySnapshot = await FirebaseFirestore.instance
            .collection('levels')
            .where('topic', isEqualTo: widget.topic)
            .get();
        print("Livelli caricati per il topic '${widget.topic}'.");
      }

      // Raccogli tutte le domande
      final allStepsWithLevelsOther = querySnapshot.docs
          .map((doc) {
            final level = Level.fromFirestore(doc);
            return level.steps
                .where((step) => step.type == 'question')
                .map((step) => {'step': step, 'level': level})
                .toList();
          })
          .expand((e) => e)
          .toList();

      print("Numero totale di domande trovate: ${allStepsWithLevelsOther.length}");

      if (allStepsWithLevelsOther.isEmpty) {
        print("Errore: Nessuna domanda trovata per il topic ${widget.topic}.");
      }

      allStepsWithLevelsOther.shuffle();

      // Filtra solo le domande non ancora risposte
      final unansweredSteps = allStepsWithLevelsOther.where((item) {
        final step = item['step'] as LevelStep;
        return !(currentUser?.answeredQuestions[widget.topic]?.contains(step.content) ?? false);
      }).toList();

      print("Domande non risposte trovate: ${unansweredSteps.length}");

      // Se ci sono meno di 5 domande non risposte, aggiungi altre domande
      final remainingStepsCount = 5 - unansweredSteps.length;
      if (remainingStepsCount > 0) {
        final answeredSteps = allStepsWithLevelsOther
            .where((item) => !unansweredSteps.contains(item))
            .toList();
        answeredSteps.shuffle();
        unansweredSteps.addAll(answeredSteps.take(remainingStepsCount));
      }

      print("Domande selezionate: ${unansweredSteps.take(5).length}");

      setState(() {
        selectedQuestionsWithLevels = unansweredSteps.take(5).toList();
      });

      if (selectedQuestionsWithLevels.isEmpty) {
        print("Errore: Nessuna domanda selezionata.");
      } else {
        print("Caricamento completato, domande pronte per essere mostrate.");
      }
    }
  }

  void _initializeVideo(Level currentLevel) {
  final videoStep = currentLevel.steps.firstWhere(
    (step) => step.type == 'video',
  );

  if (videoStep != null && videoStep.content.isNotEmpty) {
    if (_youtubePlayerController != null) {
      _youtubePlayerController!.dispose(); // Assicurati di smontare il controller esistente
    }

    _youtubePlayerController = YoutubePlayerController(
      initialVideoId: videoStep.content,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );

    setState(() {
      _showVideoButton = true;
    });
  }
}

  @override
Widget build(BuildContext context) {
  print("Costruzione della schermata delle domande...");

  return Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      title: Text(widget.topic, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.black,
      elevation: 0,
    ),
    body: selectedQuestionsWithLevels.isEmpty
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 0.0),
                child: Column(
                  children: [
                    Text(
                      "${currentIndex + 1} of ${selectedQuestionsWithLevels.length}",
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: LinearProgressIndicator(
                        value: (currentIndex + 1) / selectedQuestionsWithLevels.length,
                        backgroundColor: Colors.grey[800],
                        color: Colors.yellowAccent,
                        minHeight: 8.0,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
  setState(() {
    currentIndex = index;

    if (_youtubePlayerController != null) {
      if (_youtubePlayerController!.value.isPlaying) {
        _youtubePlayerController!.pause(); // Pausa il video corrente se sta ancora giocando
      }
      _youtubePlayerController?.dispose(); // Libera il controller esistente
      _youtubePlayerController = null; // Evita problemi accedendo a un controller nullo
    }

    _showVideoButton = false; // Nascondi il pulsante del video
  });
},
                  itemCount: selectedQuestionsWithLevels.length,
                  itemBuilder: (context, index) {
                    final currentQuestionWithLevel = selectedQuestionsWithLevels[index];
                    final currentStep = currentQuestionWithLevel['step'] as LevelStep;
                    final currentLevel = currentQuestionWithLevel['level'] as Level;

                    print("Mostrando domanda #${index + 1}: ${currentStep.content}");

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double value = 1.0;
                          if (_pageController.position.haveDimensions) {
                            value = _pageController.page! - index;
                            value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                          }
                          return Transform.scale(
                            scale: value,
                            child: Opacity(
                              opacity: value,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: CourseQuestionCard(
                                      step: currentStep,
                                      onAnswered: (isCorrect) {
                                        print("Domanda risposta: ${currentStep.content}");
                                        _initializeVideo(currentLevel); // Inizializza il video
                                      },
                                      onCompleteStep: () {
                                        // Gestisci il completamento della domanda
                                      },
                                      topic: widget.topic,
                                    ),
                                  ),
                                  // Se il video è pronto, mostra il pulsante per aprire il dialog
                                  if (_showVideoButton)
                                    IconButton(
  onPressed: () {
    _showVideoDialog(context); // Mostra il dialog con il video
  },
  icon: Container(
    decoration: BoxDecoration(
      color: Colors.grey[850], // Colore neutro scuro, minimale
      shape: BoxShape.circle, // Forma circolare che ricorda i pulsanti play/video
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3), // Ombra delicata per un effetto di profondità
          blurRadius: 8,
          spreadRadius: 2,
        ),
      ],
    ),
    padding: const EdgeInsets.all(16), // Spazio interno per mantenere il tocco comodo
    child: const Icon(
      Icons.play_arrow, // Icona del play
      size: 36, // Dimensione abbastanza grande da essere immediatamente visibile
      color: Colors.white, // Colore dell'icona per un contrasto chiaro
    ),
  ),
  splashRadius: 28, // Raggio dell'effetto splash quando il pulsante è premuto
)
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
  );
}

// Funzione per mostrare il dialog con il video
void _showVideoDialog(BuildContext context) {
  if (_youtubePlayerController == null) return; // Non aprire il dialog se il controller non è inizializzato

  _youtubePlayerController?.play();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: 9 / 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: YoutubePlayer(
                  controller: _youtubePlayerController!,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: Colors.white,
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () {
                  _youtubePlayerController?.pause(); // Metti in pausa prima di chiudere
                  Navigator.of(context).pop(); // Chiudi il dialog
                },
              ),
            ),
          ],
        ),
      );
    },
  ).then((_) {
    _youtubePlayerController?.pause(); // Assicurati che il video venga messo in pausa dopo la chiusura
  });
}}