// edit_level_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/level.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditLevelScreen extends StatefulWidget {
  final Level level;

  const EditLevelScreen({Key? key, required this.level}) : super(key: key);

  @override
  _EditLevelScreenState createState() => _EditLevelScreenState();
}

class _EditLevelScreenState extends State<EditLevelScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late List<LevelStep> _steps;

  @override
  void initState() {
    super.initState();
    _title = widget.level.title;
    _steps = widget.level.steps;
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      String documentId = widget.level.id!;

      final docRef = FirebaseFirestore.instance.collection('levels').doc(documentId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        await docRef.update({
          'title': _title,
          'steps': _steps.map((step) => step.toMap()).toList(),
        }).then((_) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Level updated successfully', style: TextStyle(color: Colors.white)),
          ));
          Navigator.pop(context);
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error updating level: $error', style: const TextStyle(color: Colors.white)),
          ));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error: Document not found', style: TextStyle(color: Colors.white)),
        ));
      }
    }
  }

  void _addStep(LevelStep step) {
    setState(() {
      _steps.add(step);
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
    });
  }

  void _editStep(int index, LevelStep updatedStep) {
    setState(() {
      _steps[index] = updatedStep;
    });
  }

  Future<void> _showEditStepDialog(LevelStep step, int index) async {
    final result = await showDialog<LevelStep>(
      context: context,
      builder: (context) => AddStepDialog(getThumbnailUrl: _getThumbnailUrl, step: step),
    );
    if (result != null) {
      _editStep(index, result);
    }
  }

  String _getThumbnailUrl(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/0.jpg';
  }

  // Function to generate questions
  Future<void> _generateQuestions() async {
  final LevelStep? videoStep = _steps.firstWhere(
    (step) => step.type == 'video',
  );

  if (videoStep == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('No video step found in this level.'),
    ));
    return;
  }

  final videoId = videoStep.content;
  final videoUrl = 'https://www.youtube.com/watch?v=$videoId';

  // Show a loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    // Send a POST request to the backend server
    final response = await http.post(
      Uri.parse('http://localhost:3000/generate_questions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'videoUrl': videoUrl}),
    );

    Navigator.of(context).pop(); // Close the loading indicator

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final questions = data['questions'] as List<dynamic>;

      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No questions were generated.'),
        ));
        return;
      }

      // Prepare new steps from the generated questions
      List<LevelStep> newSteps = questions.map<LevelStep>((q) {
        return LevelStep(
          type: 'question',
          content: q['question'],
          choices: q['choices'] != null ? List<String>.from(q['choices']) : [],
          correctAnswer: q['correct_answer'],
          explanation: q['explanation'],
          thumbnailUrl: null,
          isShort: false,
          fullText: null,
        );
      }).toList();

      // Add the new steps to _steps
      setState(() {
        _steps.addAll(newSteps);
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Questions generated and added successfully.'),
      ));
    } else {
      final errorData = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${errorData['error']}'),
      ));
    }
  } catch (error) {
    Navigator.of(context).pop(); // Close the loading indicator
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('An error occurred: $error'),
    ));
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Level'),
        actions: [
          IconButton(
            icon: const Icon(Icons.question_answer),
            tooltip: 'Generate Questions',
            onPressed: _generateQuestions,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                onSaved: (value) {
                  _title = value!;
                },
              ),
              const SizedBox(height: 20),
              const Text('Steps:', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._steps.asMap().entries.map((entry) {
                int index = entry.key;
                LevelStep step = entry.value;
                return ListTile(
                  title: Text(step.type == 'video' ? 'Video' : 'Question'),
                  subtitle: Text(step.content),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditStepDialog(step, index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeStep(index),
                      ),
                    ],
                  ),
                );
              }),
              ElevatedButton(
                onPressed: () async {
                  final result = await showDialog<LevelStep>(
                    context: context,
                    builder: (context) => AddStepDialog(getThumbnailUrl: _getThumbnailUrl),
                  );
                  if (result != null) {
                    _addStep(result);
                  }
                },
                child: const Text('Add Step'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _generateQuestions,
                child: const Text('Generate Questions'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddStepDialog extends StatefulWidget {
  final String Function(String) getThumbnailUrl;
  final LevelStep? step;

  const AddStepDialog({Key? key, required this.getThumbnailUrl, this.step}) : super(key: key);

  @override
  _AddStepDialogState createState() => _AddStepDialogState();
}

class _AddStepDialogState extends State<AddStepDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _type;
  String? _content;
  List<String>? _choices;
  String? _correctAnswer;
  String? _explanation;
  String? _thumbnailUrl;
  bool _isShort = false;

  @override
  void initState() {
    super.initState();
    if (widget.step != null) {
      _type = widget.step!.type;
      _content = widget.step!.content;
      _choices = widget.step!.choices;
      _correctAnswer = widget.step!.correctAnswer;
      _explanation = widget.step!.explanation;
      _thumbnailUrl = widget.step!.thumbnailUrl;
      _isShort = widget.step!.isShort ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.step != null ? 'Edit Step' : 'Add Step', style: const TextStyle(color: Colors.black)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Type',
                  labelStyle: TextStyle(color: Colors.black),
                ),
                value: _type,
                items: ['video', 'question'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(color: Colors.black)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _type = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a type';
                  }
                  return null;
                },
                style: const TextStyle(color: Colors.black),
              ),
              if (_type == 'video') ...[
                TextFormField(
                  initialValue: _content,
                  decoration: const InputDecoration(
                    labelText: 'Video ID',
                    labelStyle: TextStyle(color: Colors.black),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a video ID';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _content = value;
                      _thumbnailUrl = widget.getThumbnailUrl(value);
                    });
                  },
                  style: const TextStyle(color: Colors.black),
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Thumbnail URL',
                    labelStyle: TextStyle(color: Colors.black),
                  ),
                  initialValue: _thumbnailUrl,
                  enabled: false,
                  style: const TextStyle(color: Colors.black),
                ),
                CheckboxListTile(
                  title: const Text('Is it a short?', style: TextStyle(color: Colors.black)),
                  value: _isShort,
                  onChanged: (value) {
                    setState(() {
                      _isShort = value!;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ] else if (_type == 'question') ...[
                TextFormField(
                  initialValue: _content,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    labelStyle: TextStyle(color: Colors.black),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter content';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _content = value;
                  },
                  style: const TextStyle(color: Colors.black),
                ),
                TextFormField(
                  initialValue: _choices?.join(', '),
                  decoration: const InputDecoration(
                    labelText: 'Choices (separated by commas)',
                    labelStyle: TextStyle(color: Colors.black),
                  ),
                  onSaved: (value) {
                    if (value != null && value.isNotEmpty) {
                      _choices = value.split(',').map((choice) => choice.trim()).toList();
                    }
                  },
                  style: const TextStyle(color: Colors.black),
                ),
                TextFormField(
                  initialValue: _correctAnswer,
                  decoration: const InputDecoration(
                    labelText: 'Correct Answer',
                    labelStyle: TextStyle(color: Colors.black),
                  ),
                  onSaved: (value) {
                    _correctAnswer = value;
                  },
                  style: const TextStyle(color: Colors.black),
                ),
                TextFormField(
                  initialValue: _explanation,
                  decoration: const InputDecoration(
                    labelText: 'Explanation',
                    labelStyle: TextStyle(color: Colors.black),
                  ),
                  onSaved: (value) {
                    _explanation = value;
                  },
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel', style: TextStyle(color: Colors.black)),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              final newStep = LevelStep(
                type: _type!,
                content: _content!,
                choices: _choices,
                correctAnswer: _correctAnswer,
                explanation: _explanation,
                thumbnailUrl: _thumbnailUrl,
                isShort: _isShort,
              );
              Navigator.of(context).pop(newStep);
            }
          },
          child: Text(widget.step != null ? 'Save' : 'Add', style: const TextStyle(color: Colors.black)),
        ),
      ],
    );
  }
}