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
                padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    widget.step.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
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
          children: widget.step.choices?.asMap().entries.map((entry) {
            final int index = entry.key;
            final String choice = entry.value;
            
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 200 + (index * 100)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: GestureDetector(
                        onTap: () => _onAnswered(choice),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + index), // A, B, C, D...
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontFamily: 'Montserrat',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    choice,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w700,
                                      height: 1.4,
                                      letterSpacing: 0.3,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
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
            // Top feedback banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: isCorrect 
                  ? Colors.yellowAccent.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
                border: Border(
                  left: BorderSide(
                    color: isCorrect ? Colors.yellowAccent : Colors.red,
                    width: 4,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? Colors.yellowAccent : Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isCorrect ? 'Correct!' : 'Wrong',
                    style: TextStyle(
                      color: isCorrect ? Colors.yellowAccent : Colors.red,
                      fontSize: 18,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Given answer (if wrong)
            if (!isCorrect)
              GestureDetector(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withOpacity(0.1),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          selectedAnswer ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (!isCorrect) const SizedBox(height: 20),
            
            // Correct answer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.yellowAccent.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.yellowAccent.withOpacity(0.1),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.check,
                        color: Colors.yellowAccent,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.step.correctAnswer ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Explanation
            if (widget.step.explanation != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.yellowAccent.withOpacity(0.8),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Explanation',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.step.explanation!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
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
      _animationController?.forward();

      await Future.wait([
        _saveAnsweredQuestion(),
        _addCoinsToUser(),
      ]);
    } else {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 200); // Vibrazione più lunga per l'errore
      }
      _audioPlayer?.play(AssetSource('Error Sound Effect.mp3'));
    }
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