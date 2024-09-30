import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Just_Learn/models/level.dart';
import 'package:Just_Learn/models/user.dart';

class ShortsQuestionCard extends StatefulWidget {
  final LevelStep step; // La domanda (o "step") attuale che viene visualizzata
  final Function(bool) onAnswered; // Callback per notificare quando l'utente ha risposto correttamente o meno

  const ShortsQuestionCard({super.key, required this.step, required this.onAnswered});

  @override
  _ShortsQuestionCardState createState() => _ShortsQuestionCardState();
}

class _ShortsQuestionCardState extends State<ShortsQuestionCard> {
  String? selectedChoice; // Tiene traccia della scelta selezionata dall'utente
  bool hasAnswered = false; // Tiene traccia se l'utente ha risposto o meno

  @override
  void initState() {
    super.initState();
    selectedChoice = null; // Resetta la scelta selezionata all'inizio
    hasAnswered = false; // Resetta lo stato della risposta
  }

  @override
  void didUpdateWidget(covariant ShortsQuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Resetta la scelta selezionata se cambia la domanda
    if (oldWidget.step != widget.step) {
      setState(() {
        selectedChoice = null;
        hasAnswered = false;
      });
    }
  }

  // Funzione chiamata quando l'utente seleziona una risposta
  void handleChoice(String choice) async {
    setState(() {
      selectedChoice = choice;
      hasAnswered = true; // L'utente ha risposto
    });

    bool isCorrect = choice == widget.step.correctAnswer;

    // Salva la domanda risolta nel database
    await saveAnsweredQuestion();

    // Notifica il risultato della risposta alla callback
    widget.onAnswered(isCorrect);
  }

  // Funzione che salva la domanda risolta e aggiorna il documento dell'utente
  Future<void> saveAnsweredQuestion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        final userModel = UserModel.fromMap(userData);

        // Aggiungi la domanda alla lista delle domande risposte
        userModel.answeredQuestions[widget.step.content] ??= [];
        userModel.answeredQuestions[widget.step.content]!.add(widget.step.content);

        // Aggiorna l'utente nel database con la nuova domanda risolta
        await docRef.update(userModel.toMap());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mostra il testo della domanda
          Text(
            widget.step.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          if (!hasAnswered)
            // Mostra le scelte solo se l'utente non ha ancora risposto
            Expanded(
              child: ListView(
                children: widget.step.choices!.map((choice) => GestureDetector(
                  onTap: () => handleChoice(choice),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 24),
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(width: 1, color: Colors.white),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: Colors.white,
                    ),
                    child: Text(
                      choice,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.48,
                      ),
                    ),
                  ),
                )).toList(),
              ),
            )
          else
            // Mostra il risultato una volta che l'utente ha risposto
            Expanded(
              child: ListView(
                children: [
                  // Mostra la scelta selezionata
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 24),
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color: selectedChoice == widget.step.correctAnswer
                              ? Colors.white
                              : Colors.white,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: selectedChoice == widget.step.correctAnswer
                          ? Colors.white
                          : Colors.black,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            selectedChoice!,
                            style: TextStyle(
                              color: selectedChoice == widget.step.correctAnswer
                                  ? Colors.black
                                  : Colors.white,
                              fontSize: 16,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.48,
                            ),
                          ),
                        ),
                        Icon(
                          selectedChoice == widget.step.correctAnswer
                              ? Icons.check
                              : Icons.close,
                          color: selectedChoice == widget.step.correctAnswer
                              ? Colors.black
                              : Colors.white,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (selectedChoice != widget.step.correctAnswer)
                    // Mostra la risposta corretta se l'utente ha sbagliato
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 24),
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(width: 1, color: Colors.white),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.step.correctAnswer!,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.48,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.check,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Mostra una spiegazione della risposta, se disponibile
                  if (widget.step.explanation != null)
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        widget.step.explanation!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.48,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}