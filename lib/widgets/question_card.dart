import 'package:flutter/material.dart';
import '../models/level.dart';

class QuestionCard extends StatefulWidget {
  final LevelStep step;
  final Function(bool) onAnswered;

  QuestionCard({required this.step, required this.onAnswered});

  @override
  _QuestionCardState createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  String? selectedChoice;

  void handleChoice(String choice) {
    setState(() {
      selectedChoice = choice;
    });

    bool isCorrect = choice == widget.step.correctAnswer;
    widget.onAnswered(isCorrect);
  }

  @override
  void didUpdateWidget(QuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.step != oldWidget.step) {
      setState(() {
        selectedChoice = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.step.content,
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          if (selectedChoice == null)
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
                        side: BorderSide(width: 1, color: Colors.white),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: Colors.white,
                    ),
                    child: Text(
                      choice,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.48,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                )).toList(),
              ),
            )
          else
            Expanded(
              child: ListView(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 24),
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(width: 1, color: Colors.white),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: selectedChoice == widget.step.correctAnswer ? Colors.white : Colors.black,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            selectedChoice!,
                            style: TextStyle(
                              color: selectedChoice == widget.step.correctAnswer ? Colors.black : Colors.white,
                              fontSize: 16,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.48,
                            ),
                          ),
                        ),
                        Icon(
                          selectedChoice == widget.step.correctAnswer ? Icons.check : Icons.close,
                          color: selectedChoice == widget.step.correctAnswer ? Colors.black : Colors.white,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (selectedChoice != widget.step.correctAnswer)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 24),
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(width: 1, color: Colors.white),
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
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.48,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.check,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    child: Text(
                      widget.step.explanation!,
                      style: TextStyle(
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