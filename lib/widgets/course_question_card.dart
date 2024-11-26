import 'package:Just_Learn/models/level.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Just_Learn/models/course.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

class CourseQuestionCard extends StatefulWidget {
  final LevelStep step;
  final ValueChanged<bool> onAnswered;
  final VoidCallback onCompleteStep;
  final String topic;

  const CourseQuestionCard({
    Key? key,
    required this.step,
    required this.onAnswered,
    required this.onCompleteStep,
    required this.topic,
  }) : super(key: key);

  @override
  _CourseQuestionCardState createState() => _CourseQuestionCardState();
}

class _CourseQuestionCardState extends State<CourseQuestionCard> with SingleTickerProviderStateMixin {
  String? selectedAnswer;
  bool isCorrect = false;
  bool hasAnswered = false;
  AnimationController? _animationController;
  AudioPlayer? _audioPlayer;
  bool _showCoins = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CourseQuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step != widget.step) {
      setState(() {
        selectedAnswer = null;
        isCorrect = false;
        hasAnswered = false;
        _showCoins = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: ShapeDecoration(
            color: const Color(0xFF121212),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 10.0),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    widget.step.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.left,
                    maxLines: null,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
              Expanded(
                child: hasAnswered ? _buildAnswerFeedback() : _buildChoices(),
              ),
            ],
          ),
        ),
        if (_showCoins)
          Positioned(
            bottom: 50,
            left: MediaQuery.of(context).size.width / 2 - 30,
            child: AnimatedBuilder(
              animation: _animationController!,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -150 * _animationController!.value),
                  child: Opacity(
                    opacity: 1 - _animationController!.value,
                    child: child,
                  ),
                );
              },
              child: Icon(
                Icons.stars_rounded,
                size: 60,
                color: Colors.yellow,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChoices() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 15),
      child: SingleChildScrollView(
        child: Column(
          children: widget.step.choices?.map((choice) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: GestureDetector(
                onTap: () => _onAnswered(choice),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 28),
                  decoration: ShapeDecoration(
                    color: const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    choice,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: 0.48,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
            );
          }).toList() ?? [],
        ),
      ),
    );
  }

  Widget _buildAnswerFeedback() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 15),
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (!isCorrect) ...[
              _buildSelectedAnswer(),
              const SizedBox(height: 24),
            ],
            _buildCorrectAnswer(),
            const SizedBox(height: 24),
            _buildExplanation(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedAnswer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 24),
      decoration: ShapeDecoration(
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selectedAnswer ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          if (!isCorrect)
            const Icon(Icons.close, color: Colors.red, size: 24),
        ],
      ),
    );
  }

  Widget _buildCorrectAnswer() {
    final correctAnswer = widget.step.correctAnswer ?? 'Risposta corretta non disponibile';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 24),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              correctAnswer,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Icon(Icons.check, color: Colors.green, size: 24),
        ],
      ),
    );
  }

  Widget _buildExplanation() {
    return SizedBox(
      width: double.infinity,
      child: Text(
        widget.step.explanation ?? 'Nessuna spiegazione disponibile.',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
      ),
    );
  }

 Future<void> _onAnswered(String choice) async {
  setState(() {
    selectedAnswer = choice;
    isCorrect = _checkAnswer(choice);
    hasAnswered = true;
    widget.onAnswered(isCorrect);
  });

  // Traccia la risposta dell'utente
  Posthog().capture(
    eventName: 'question_answered',
    properties: {
      'topic': widget.topic,
      'question': widget.step.content,
      'selected_answer': choice,
      'is_correct': isCorrect,
      'timestamp': DateTime.now().toIso8601String(),
    },
  );

  if (isCorrect) {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }
    _audioPlayer?.play(AssetSource('success_sound.mp3'));
    setState(() {
      _showCoins = true;
    });
    _animationController?.forward(from: 0);

    await _addCoinsToUser();
  }

  await _saveAnsweredQuestion();
}

  Future<void> _addCoinsToUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        final userModel = UserModel.fromMap(userData);

        userModel.coins += 5;

        await docRef.update({'coins': userModel.coins});

        final updateCoins = ModalRoute.of(context)?.settings.arguments as Function(int)?;
        if (updateCoins != null) {
          updateCoins(userModel.coins);
        }
      }
    }
  }

  Future<void> _saveAnsweredQuestion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        final userModel = UserModel.fromMap(userData);

        // Verifica se esiste già una lista di domande risposte per il topic corrente
        userModel.answeredQuestions[widget.topic] ??= [];

        // Controlla se la domanda è già stata risolta
        if (!userModel.answeredQuestions[widget.topic]!.contains(widget.step.content)) {
          // Se non è presente, la aggiungiamo
          userModel.answeredQuestions[widget.topic]!.add(widget.step.content);

          // Aggiorna l'utente nel database con la nuova domanda risolta
          await docRef.update(userModel.toMap());
        }
      }
    }
  }

  bool _checkAnswer(String choice) {
    return widget.step.correctAnswer == choice;
  }
}