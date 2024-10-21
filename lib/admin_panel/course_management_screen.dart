import 'package:Just_Learn/models/level.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';

class CourseManagementScreen extends StatefulWidget {
  const CourseManagementScreen({super.key});

  @override
  _CourseManagementScreenState createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedTopic;
  String? _subtopic;
  String? _courseTitle;
  final List<Section> _sections = [];
  List<String> _topics = [];
  List<String> _subtopics = [];

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    final topicsCollection = FirebaseFirestore.instance.collection('topics');
    final querySnapshot = await topicsCollection.get();
    setState(() {
      _topics = querySnapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<void> _loadSubtopics(String topic) async {
  final subtopicsCollection = FirebaseFirestore.instance.collection('subtopics');
  final querySnapshot = await subtopicsCollection.where('topic', isEqualTo: topic).get();

  setState(() {
    _subtopics = querySnapshot.docs.map((doc) => doc['name'] as String).toList();
  });
}

Future<void> _addNewSubtopic() async {
  String? newSubtopic;
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Crea nuovo subtopic'),
        content: TextFormField(
          decoration: const InputDecoration(labelText: 'Nome Subtopic'),
          onChanged: (value) {
            newSubtopic = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              if (newSubtopic != null && newSubtopic!.isNotEmpty) {
                setState(() {
                  _subtopics.add(newSubtopic!);
                  _subtopic = newSubtopic;
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Crea'),
          ),
        ],
      );
    },
  );
}

  void _addSection() {
    String? sectionTitle;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Aggiungi Sezione'),
          content: TextFormField(
            decoration: const InputDecoration(labelText: 'Titolo Sezione'),
            onChanged: (value) {
              sectionTitle = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                if (sectionTitle != null && sectionTitle!.isNotEmpty) {
                  setState(() {
                    _sections.add(Section(title: sectionTitle!, steps: []));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  void _addStepDialog(Section section) {
    String? stepType;
    String? content;
    String? videoUrl;
    String? correctAnswer;
    List<String>? choices;
    String? explanation;
    String? thumbnailUrl;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Aggiungi Step'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Tipo Step'),
                    items: ['video', 'question'].map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        stepType = value;
                      });
                    },
                  ),
                  if (stepType == 'video') ...[
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'ID Video YouTube'),
                      onChanged: (value) {
                        videoUrl = value;
                        setState(() {
                          // Genera automaticamente l'URL della miniatura
                          thumbnailUrl = 'https://img.youtube.com/vi/$value/0.jpg';
                        });
                      },
                    ),
                    if (thumbnailUrl != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Image.network(thumbnailUrl!),
                      ),
                  ] else if (stepType == 'question') ...[
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Contenuto Domanda'),
                      onChanged: (value) {
                        content = value;
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Opzioni (separate da virgole)'),
                      onChanged: (value) {
                        choices = value.split(',').map((e) => e.trim()).toList();
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Risposta Corretta'),
                      onChanged: (value) {
                        correctAnswer = value;
                      },
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Spiegazione'),
                      onChanged: (value) {
                        explanation = value;
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Annulla'),
                ),
                TextButton(
  onPressed: () {
    if (stepType == 'video' && videoUrl != null) {
      setState(() {
        section.steps.add(LevelStep(
          type: 'video',
          content: videoUrl!,
          videoUrl: videoUrl,
          thumbnailUrl: thumbnailUrl,
        ));
      });
    } else if (stepType == 'question' && content != null && correctAnswer != null && choices != null) {
      setState(() {
        section.steps.add(LevelStep(
          type: 'question',
          content: content!,
          choices: choices,
          correctAnswer: correctAnswer,
          explanation: explanation,
        ));
      });
    }
    setState(() {}); // Aggiorna la UI
    Navigator.pop(context);
  },
  child: const Text('Aggiungi Step'),
),
              ],
            );
          },
        );
      },
    );
  }

  void _createCourse() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newCourse = Course(
        id: '',
        title: _courseTitle!,
        sections: _sections,
        topic: _selectedTopic!,
        subtopic: _subtopic!,
      );

      FirebaseFirestore.instance.collection('courses').add(newCourse.toMap()).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Corso creato con successo')),
        );
        Navigator.pop(context);
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nella creazione del corso: $error')),
        );
      });
    }
  }

  void _removeStep(Section section, int index) {
    setState(() {
      section.steps.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione Corsi'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedTopic,
                hint: const Text('Seleziona un topic'),
                items: _topics.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) async {
                  setState(() {
                    _selectedTopic = newValue;
                    _subtopic = null;
                  });
                  await _loadSubtopics(newValue!);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Per favore seleziona un topic';
                  }
                                    },
              ),
              if (_selectedTopic != null)
                DropdownButtonFormField<String>(
  value: _subtopic,
  hint: const Text('Seleziona un subtopic o creane uno nuovo'),
  items: [
    ..._subtopics.map((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value),
      );
    }),
    const DropdownMenuItem<String>(
      value: 'new',
      child: Text('Crea nuovo subtopic'),
    ),
  ],
  onChanged: (newValue) async {
    if (newValue == 'new') {
      await _addNewSubtopic();
    } else {
      setState(() {
        _subtopic = newValue;
      });
    }
  },
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Per favore seleziona o crea un subtopic';
    }
    return null;
  },
),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Titolo Corso'),
                onSaved: (value) {
                  _courseTitle = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci un titolo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addSection,
                child: const Text('Aggiungi Sezione'),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _sections.length,
                  itemBuilder: (context, index) {
                    final section = _sections[index];
                    return ExpansionTile(
                      title: Text(section.title),
                      children: [
                        ElevatedButton(
                          onPressed: () => _addStepDialog(section),
                          child: const Text('Aggiungi Step'),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: section.steps.length,
                          itemBuilder: (context, stepIndex) {
                            final step = section.steps[stepIndex];
                            return ExpansionTile(
                              title: Text(
                                  '${stepIndex + 1}. ${step.type == 'video' ? 'Video: ${step.content}' : 'Domanda: ${step.content}'}'),
                              children: [
                                if (step.type == 'video') ...[
                                  Image.network(step.thumbnailUrl ?? ''),
                                  Text('ID Video: ${step.videoUrl}'),
                                ] else if (step.type == 'question') ...[
                                  Text('Domanda: ${step.content}'),
                                  Text('Risposta Corretta: ${step.correctAnswer}'),
                                  if (step.explanation != null)
                                    Text('Spiegazione: ${step.explanation}'),
                                ],
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _removeStep(section, stepIndex),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _createCourse,
                child: const Text('Crea Corso'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}