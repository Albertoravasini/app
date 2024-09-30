import 'package:Just_Learn/admin_panel/edit_level_screen.dart';
import 'package:Just_Learn/admin_panel/level_drag_drop_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/level.dart';

class LevelManagementScreen extends StatefulWidget {
  const LevelManagementScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LevelManagementScreenState createState() => _LevelManagementScreenState();
}

class _LevelManagementScreenState extends State<LevelManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedTopic;
  int? _levelNumber;
  String? _subtopic;
  String? _title;
  final List<LevelStep> _steps = [];
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

  // Ordina per subtopicOrder e levelNumber
  final querySnapshot = await levelsCollection
      .where('topic', isEqualTo: topic)
      .orderBy('subtopicOrder')  // Ordina per subtopicOrder
      .orderBy('levelNumber')    // Ordina per levelNumber
      .get();

  final fetchedLevels = querySnapshot.docs.map((doc) => Level.fromFirestore(doc)).toList();

  final subtopicsSet = <String>{};
  for (var level in fetchedLevels) {
    subtopicsSet.add(level.subtopic);
  }

  setState(() {
    _levels = fetchedLevels;
    _subtopics = subtopicsSet.toList();
    _levelNumber = _levels.length + 1;
  });
}
Future<void> _renameTopic(String oldTopic, String newTopic) async {
  if (newTopic.isEmpty) return;

  final batch = FirebaseFirestore.instance.batch();

  // Ottieni tutti i livelli con il topic vecchio e aggiorna il topic
  final levelsQuery = await FirebaseFirestore.instance
      .collection('levels')
      .where('topic', isEqualTo: oldTopic)
      .get();

  for (var levelDoc in levelsQuery.docs) {
    batch.update(levelDoc.reference, {'topic': newTopic});
  }

  // Aggiorna anche il nome del topic nella collezione dei topic (se esiste)
  final topicDoc = FirebaseFirestore.instance.collection('topics').doc(oldTopic);
  final topicSnapshot = await topicDoc.get();

  if (topicSnapshot.exists) {
    batch.delete(topicDoc);
    batch.set(FirebaseFirestore.instance.collection('topics').doc(newTopic), <String, dynamic>{});
  }

  await batch.commit();

  // Aggiorna lo stato locale e carica di nuovo i topic
  setState(() {
    _topics[_topics.indexOf(oldTopic)] = newTopic;
    _selectedTopic = newTopic;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Topic rinominato con successo')),
  );
}

Future<void> _showRenameTopicDialog(String oldTopic) async {
  final TextEditingController controller = TextEditingController(text: oldTopic);

  final newTopic = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Rinomina Topic'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Nuovo nome topic'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text('Salva'),
          ),
        ],
      );
    },
  );

  if (newTopic != null && newTopic.isNotEmpty && newTopic != oldTopic) {
    _renameTopic(oldTopic, newTopic);
  }
}
  Future<void> _createLevel() async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();

    // Controllo per evitare che _subtopic sia null
    if (_subtopic == null || _subtopic!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Per favore seleziona o crea un subtopic', style: TextStyle(color: Colors.white)),
      ));
      return;
    }

    // Calcola l'ordine del subtopic basato sull'indice del subtopic nell'array corrente
    final subtopicOrder = _subtopics.indexOf(_subtopic!) + 1;

    final newLevel = Level(
      levelNumber: _levelNumber!,
      topic: _selectedTopic!,
      subtopic: _subtopic!, // Qui siamo sicuri che _subtopic non è più null
      title: _title!,
      steps: _steps,
      subtopicOrder: subtopicOrder,
    );

    try {
      DocumentReference docRef = await FirebaseFirestore.instance.collection('levels').add(newLevel.toMap());
      String generatedId = docRef.id;

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Livello creato con successo con ID $generatedId', style: const TextStyle(color: Colors.white)),
      ));

      setState(() {
        _levels.add(newLevel);  // Aggiungi il nuovo livello alla lista
      });
    } catch (error) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Errore nella creazione del livello: $error', style: const TextStyle(color: Colors.white)),
      ));
    }
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
        final levelData = doc.data();
        final updatedLevelNumber = levelData['levelNumber'] - 1;

        await doc.reference.update({'levelNumber': updatedLevelNumber});
      }

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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

  void _addStep(LevelStep step) async {
  if (step.type == 'video') {
    // Effettua una query su Firestore per ottenere tutti i livelli
    final querySnapshot = await FirebaseFirestore.instance.collection('levels').get();

    // Itera su ogni documento per controllare se uno degli step ha lo stesso content (ID video)
    for (var doc in querySnapshot.docs) {
      List<dynamic> steps = doc.data()['steps'];
      for (var existingStep in steps) {
        if (existingStep['type'] == 'video' && existingStep['content'] == step.content) {
          // Se troviamo un duplicato, mostriamo un messaggio di errore e ritorniamo
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Questo ID video esiste già in un altro step', style: TextStyle(color: Colors.white)),
          ));
          return;
        }
      }
    }
  }

  // Se non esiste un duplicato, aggiungi lo step
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
        title: const Text('Gestione Livelli', style: TextStyle(color: Colors.white)),
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
                  const Text(
                    'Seleziona Topic:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Row(
  children: [
    Expanded(
      child: DropdownButtonFormField<String>(
        value: _selectedTopic,
        hint: const Text('Seleziona un topic', style: TextStyle(color: Colors.white)),
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
        style: const TextStyle(color: Colors.black),
        dropdownColor: Colors.white,
      ),
    ),
    IconButton(
      icon: Icon(Icons.edit, color: Colors.white),
      onPressed: _selectedTopic != null
          ? () => _showRenameTopicDialog(_selectedTopic!)
          : null,
    ),
  ],
),
                  if (_selectedTopic != null)
                    DropdownButtonFormField<String>(
                      value: _subtopic,
                      hint: const Text('Seleziona un subtopic o creane uno nuovo', style: TextStyle(color: Colors.white)),
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
                          final newSubtopic = await showDialog<String>(
                            context: context,
                            builder: (context) {
                              String? subtopicName;
                              return AlertDialog(
                                title: const Text('Crea nuovo subtopic'),
                                content: TextFormField(
                                  decoration: const InputDecoration(labelText: 'Nome Subtopic'),
                                  onChanged: (value) {
                                    subtopicName = value;
                                  },
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(subtopicName);
                                    },
                                    child: const Text('Crea'),
                                  ),
                                ],
                              );
                            },
                          );
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
                      style: const TextStyle(color: Colors.black),
                      dropdownColor: Colors.white,
                    ),
                  if (_selectedTopic != null)
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Numero Livello', labelStyle: TextStyle(color: Colors.white)),
                      initialValue: _levelNumber?.toString(),
                      enabled: false,
                      style: const TextStyle(color: Colors.white),
                    ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Titolo', labelStyle: TextStyle(color: Colors.white)),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Per favore inserisci un titolo';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _title = value;
                    },
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
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
                    child: const Text('Aggiungi Step'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
  onPressed: _createLevel,
  child: const Text('Crea Livello'),
),
const SizedBox(height: 20),  // Spazio tra i pulsanti
ElevatedButton(
  onPressed: () {
    if (_selectedTopic != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LevelReorderScreen(selectedTopic: _selectedTopic!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Seleziona un topic prima di riorganizzare i livelli.'),
      ));
    }
  },
  child: const Text('Riorganizza Livelli'),
),
                  const SizedBox(height: 20),
                  const Text(
                    'Steps aggiunti:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  ..._steps.map((step) => ListTile(
                    title: Text(step.type, style: const TextStyle(color: Colors.white)),
                                        subtitle: Text(step.content, style: const TextStyle(color: Colors.white)),
                    trailing: step.isShort
                        ? const Icon(Icons.short_text, color: Colors.white)
                        : const Icon(Icons.video_library, color: Colors.white),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Livelli esistenti:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            ..._levels.map((level) => ListTile(
  title: Text(level.title, style: const TextStyle(color: Colors.white)),
  subtitle: Text('Topic: ${level.topic}, Subtopic: ${level.subtopic}', style: const TextStyle(color: Colors.white)),
  trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: const Icon(Icons.edit, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditLevelScreen(level: level)),
          );
        },
      ),
      IconButton(
        icon: const Icon(Icons.delete, color: Colors.white),
        onPressed: () => _deleteLevel(level),
      ),
    ],
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

  const AddStepDialog({super.key, required this.getThumbnailUrl});

  @override
  // ignore: library_private_types_in_public_api
  _AddStepDialogState createState() => _AddStepDialogState();
}

class _AddStepDialogState extends State<AddStepDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _type;
  String? _content;
  String? _fullText; // Nuovo campo per il testo completo del video
  List<String>? _choices;
  String? _correctAnswer;
  String? _explanation;
  String? _thumbnailUrl;
  bool _isShort = true; // Nuovo campo per indicare se è uno short

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Aggiungi Step', style: TextStyle(color: Colors.black)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Tipo', labelStyle: TextStyle(color: Colors.black)),
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
                  decoration: const InputDecoration(labelText: 'ID Video', labelStyle: TextStyle(color: Colors.black)),
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
                  style: const TextStyle(color: Colors.black),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'URL Miniatura', labelStyle: TextStyle(color: Colors.black)),
                  initialValue: _thumbnailUrl,
                  enabled: false,
                  style: const TextStyle(color: Colors.black),
                ),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Testo Completo del Video', // Campo per il testo completo
                    labelStyle: TextStyle(color: Colors.black),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    setState(() {
                      _fullText = value; // Aggiorna il valore del testo completo
                    });
                  },
                  style: TextStyle(color: Colors.black),
                ),
                CheckboxListTile(
                  title: const Text('È uno short?', style: TextStyle(color: Colors.black)),
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
                  decoration: const InputDecoration(labelText: 'Contenuto', labelStyle: TextStyle(color: Colors.black)),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Per favore inserisci un contenuto';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _content = value;
                  },
                  style: const TextStyle(color: Colors.black),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Scelte (separate da virgola)', labelStyle: TextStyle(color: Colors.black)),
                  onSaved: (value) {
                    if (value != null && value.isNotEmpty) {
                      _choices = value.split(',').map((choice) => choice.trim()).toList();
                    }
                  },
                  style: const TextStyle(color: Colors.black),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Risposta Corretta', labelStyle: TextStyle(color: Colors.black)),
                  onSaved: (value) {
                    _correctAnswer = value;
                  },
                  style: const TextStyle(color: Colors.black),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Spiegazione', labelStyle: TextStyle(color: Colors.black)),
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
          child: const Text('Annulla', style: TextStyle(color: Colors.black)),
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
                isShort: _isShort,  // Imposta il valore di isShort
                fullText: _fullText, // Passa il testo completo al costruttore
              );
              Navigator.of(context).pop(newStep);
            }
          },
          child: const Text('Aggiungi', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }
}