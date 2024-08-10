import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/level.dart';

class LevelManagementScreen extends StatefulWidget {
  @override
  _LevelManagementScreenState createState() => _LevelManagementScreenState();
}

class _LevelManagementScreenState extends State<LevelManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedTopic;
  int? _levelNumber;
  String? _subtopic;
  String? _title;
  List<LevelStep> _steps = [];
  List<Level> _levels = [];
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

  Future<void> _loadSubtopicsAndLevels(String topic) async {
    final levelsCollection = FirebaseFirestore.instance.collection('levels');
    final querySnapshot = await levelsCollection.where('topic', isEqualTo: topic).get();
    final fetchedLevels = querySnapshot.docs.map((doc) => Level.fromFirestore(doc)).toList();
    
    final subtopicsSet = Set<String>();
    for (var level in fetchedLevels) {
      subtopicsSet.add(level.subtopic);
    }

    setState(() {
      _levels = fetchedLevels;
      _subtopics = subtopicsSet.toList();
      _levelNumber = _levels.length + 1;
    });
  }

  void _createLevel() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newLevel = Level(
        levelNumber: _levelNumber!,
        topic: _selectedTopic!,
        subtopic: _subtopic!,
        title: _title!,
        steps: _steps,
      );
      FirebaseFirestore.instance.collection('levels')
        .add(newLevel.toMap())
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Livello creato con successo', style: TextStyle(color: Colors.white))));
          _formKey.currentState!.reset();
          setState(() {
            _steps = [];
            _selectedTopic = null;
            _subtopics = [];
            _levelNumber = null;
          });
          _loadSubtopicsAndLevels(_selectedTopic!);
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore nella creazione del livello: $error', style: TextStyle(color: Colors.white))));
        });
    }
  }

  void _deleteLevel(Level level) async {
    final levelsCollection = FirebaseFirestore.instance.collection('levels');

    // Trova il documento del livello da eliminare
    final levelQuery = await levelsCollection
        .where('topic', isEqualTo: level.topic)
        .where('levelNumber', isEqualTo: level.levelNumber)
        .get();

    if (levelQuery.docs.isNotEmpty) {
      // Elimina il livello specificato
      await levelQuery.docs.first.reference.delete();
      
      // Trova tutti i livelli successivi al livello eliminato
      final subsequentLevelsQuery = await levelsCollection
          .where('topic', isEqualTo: level.topic)
          .where('levelNumber', isGreaterThan: level.levelNumber)
          .orderBy('levelNumber')
          .get();

      // Decrementa il levelNumber per ciascuno dei livelli successivi
      for (var doc in subsequentLevelsQuery.docs) {
        final levelData = doc.data() as Map<String, dynamic>;
        final updatedLevelNumber = levelData['levelNumber'] - 1;

        await doc.reference.update({'levelNumber': updatedLevelNumber});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Livello eliminato con successo e numeri aggiornati.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );

      // Ricarica i livelli e subtopic
      await _loadSubtopicsAndLevels(_selectedTopic!);
    }
  }

  void _addStep(LevelStep step) {
    setState(() {
      _steps.add(step);
    });
  }

  String _getThumbnailUrl(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/0.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestione Livelli', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seleziona Topic:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedTopic,
                    hint: Text('Seleziona un topic', style: TextStyle(color: Colors.white)),
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
                      await _loadSubtopicsAndLevels(newValue!);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Per favore seleziona un topic';
                      }
                      return null;
                    },
                    style: TextStyle(color: Colors.black),
                    dropdownColor: Colors.white,
                  ),
                  if (_selectedTopic != null)
                    DropdownButtonFormField<String>(
                      value: _subtopic,
                      hint: Text('Seleziona un subtopic o creane uno nuovo', style: TextStyle(color: Colors.white)),
                      items: [
                        ..._subtopics.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        DropdownMenuItem<String>(
                          value: 'new',
                          child: Text('Crea nuovo subtopic'),
                        ),
                      ],
                      onChanged: (newValue) async {
                        if (newValue == 'new') {
                          final newSubtopic = await showDialog<String>(
                            context: context,
                            builder: (context) {
                              String? subtopicName;
                              return AlertDialog(
                                title: Text('Crea nuovo subtopic'),
                                content: TextFormField(
                                  decoration: InputDecoration(labelText: 'Nome Subtopic'),
                                  onChanged: (value) {
                                    subtopicName = value;
                                  },
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(subtopicName);
                                    },
                                    child: Text('Crea'),
                                  ),
                                ],
                              );
                        });
                          if (newSubtopic != null && newSubtopic.isNotEmpty) {
                            setState(() {
                              _subtopics.add(newSubtopic);
                              _subtopic = newSubtopic;
                            });
                          }
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
                      style: TextStyle(color: Colors.black),
                      dropdownColor: Colors.white,
                    ),
                  if (_selectedTopic != null)
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Numero Livello', labelStyle: TextStyle(color: Colors.white)),
                      initialValue: _levelNumber?.toString(),
                      enabled: false,
                      style: TextStyle(color: Colors.white),
                    ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Titolo', labelStyle: TextStyle(color: Colors.white)),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Per favore inserisci un titolo';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _title = value;
                    },
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 20),
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
                    child: Text('Aggiungi Step'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _createLevel,
                    child: Text('Crea Livello'),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Steps aggiunti:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  ..._steps.map((step) => ListTile(
                    title: Text(step.type, style: TextStyle(color: Colors.white)),
                    subtitle: Text(step.content, style: TextStyle(color: Colors.white)),
                  )),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Livelli esistenti:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            ..._levels.map((level) => ListTile(
              title: Text(level.title, style: TextStyle(color: Colors.white)),
              subtitle: Text('Topic: ${level.topic}, Subtopic: ${level.subtopic}', style: TextStyle(color: Colors.white)),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.white),
                onPressed: () => _deleteLevel(level),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class AddStepDialog extends StatefulWidget {
  final String Function(String) getThumbnailUrl;

  AddStepDialog({required this.getThumbnailUrl});

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Aggiungi Step', style: TextStyle(color: Colors.black)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Tipo', labelStyle: TextStyle(color: Colors.black)),
                items: ['video', 'question'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _type = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Per favore seleziona un tipo';
                  }
                  return null;
                },
              ),
              if (_type == 'video') ...[
                TextFormField(
                  decoration: InputDecoration(labelText: 'ID Video', labelStyle: TextStyle(color: Colors.black)),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Per favore inserisci un ID video';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _content = value;
                      _thumbnailUrl = widget.getThumbnailUrl(value);
                    });
                  },
                  style: TextStyle(color: Colors.black),
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'URL Miniatura', labelStyle: TextStyle(color: Colors.black)),
                  initialValue: _thumbnailUrl,
                  enabled: false,
                  style: TextStyle(color: Colors.black),
                ),
              ] else if (_type == 'question') ...[
                TextFormField(
                  decoration: InputDecoration(labelText: 'Contenuto', labelStyle: TextStyle(color: Colors.black)),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Per favore inserisci un contenuto';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _content = value;
                  },
                  style: TextStyle(color: Colors.black),
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Scelte (separate da virgola)', labelStyle: TextStyle(color: Colors.black)),
                  onSaved: (value) {
                    if (value != null && value.isNotEmpty) {
                      _choices = value.split(',').map((choice) => choice.trim()).toList();
                    }
                  },
                  style: TextStyle(color: Colors.black),
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Risposta Corretta', labelStyle: TextStyle(color: Colors.black)),
                  onSaved: (value) {
                    _correctAnswer = value;
                  },
                  style: TextStyle(color: Colors.black),
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Spiegazione', labelStyle: TextStyle(color: Colors.black)),
                  onSaved: (value) {
                    _explanation = value;
                  },
                  style: TextStyle(color: Colors.black),
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
          child: Text('Annulla', style: TextStyle(color: Colors.black)),
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
              );
              Navigator.of(context).pop(newStep);
            }
          },
          child: Text('Aggiungi', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }
}