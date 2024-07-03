import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QuestionCard extends StatefulWidget {
  final dynamic video;

  QuestionCard({required this.video});

  @override
  _QuestionCardState createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  String? question;
  List<String>? choices;
  String? correctAnswer;
  bool loading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    generateQuestion();
  }

  Future<void> generateQuestion() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/generate_question'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'videoUrl': 'https://www.youtube.com/watch?v=${widget.video['id']}'}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['question'] != null && data['question']['question'] != null && data['question']['choices'] != null) {
          if (mounted) {
            setState(() {
              question = data['question']['question'];
              choices = List<String>.from(data['question']['choices']);
              correctAnswer = data['question']['correctAnswer'];
              loading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              loading = false;
              errorMessage = 'Failed to generate question: invalid response data';
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            loading = false;
            errorMessage = 'Failed to generate question: ${response.statusCode} ${response.reasonPhrase}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          errorMessage = 'Failed to generate question: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(child: CircularProgressIndicator());
    }
    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage));
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            question ?? 'No question available',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          ...choices?.map((choice) => ElevatedButton(
            onPressed: () {
              if (choice == correctAnswer) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Correct!')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Wrong!')));
              }
            },
            child: Text(choice),
          )) ?? [],
        ],
      ),
    );
  }
}