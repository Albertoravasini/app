import 'package:flutter/material.dart';

class AnswerSummaryScreen extends StatelessWidget {
  final String selectedChoice;
  final String correctAnswer;
  final String question;
  final bool isCorrect;
  final String explanation;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  AnswerSummaryScreen({
    required this.selectedChoice,
    required this.correctAnswer,
    required this.question,
    required this.isCorrect,
    required this.explanation,
    required this.onContinue,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riepilogo Risposte'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 24),
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 1, color: selectedChoice == correctAnswer ? Colors.green : Colors.red),
                  borderRadius: BorderRadius.circular(20),
                ),
                color: selectedChoice == correctAnswer ? Colors.green[100] : Colors.red[100],
              ),
              child: Text(
                selectedChoice,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.48,
                ),
              ),
            ),
            if (selectedChoice != correctAnswer) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 24),
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 1, color: Colors.green),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: Colors.green[100],
                ),
                child: Text(
                  correctAnswer,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.48,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Container(
              child: Text(
                explanation,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.48,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!isCorrect)
                  ElevatedButton(
                    onPressed: onRetry,
                    child: Text('Riprova'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: Size(150, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ElevatedButton(
                  onPressed: isCorrect ? onContinue : null,
                  child: Text('Continua'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: Size(150, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}