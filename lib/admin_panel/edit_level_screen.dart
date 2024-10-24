// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/level.dart';

class EditLevelScreen extends StatefulWidget {
  final Level level;

  const EditLevelScreen({super.key, required this.level});

  @override
  // ignore: library_private_types_in_public_api
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
    
    // Supponiamo che tu abbia salvato l'ID del documento Firestore da qualche parte
    String documentId = widget.level.id!;  // Usa '!' per fare il cast a String
    
    final docRef = FirebaseFirestore.instance.collection('levels').doc(documentId);
    final docSnapshot = await docRef.get();
    
    if (docSnapshot.exists) {
      // Aggiorna il documento se esiste
      await docRef.update({
        'title': _title,
        'steps': _steps.map((step) => step.toMap()).toList(),
      }).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Livello aggiornato con successo', style: TextStyle(color: Colors.white))
        ));
        Navigator.pop(context);
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Errore nell\'aggiornamento del livello: $error', style: const TextStyle(color: Colors.white))
        ));
      });
    } else {
      // Gestisci il caso in cui il documento non esiste
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Errore: documento non trovato', style: TextStyle(color: Colors.white))
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
      builder: (context) =>
          AddStepDialog(getThumbnailUrl: _getThumbnailUrl, step: step),
    );
    if (result != null) {
      _editStep(index, result);
    }
  }

  String _getThumbnailUrl(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/0.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifica Livello'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(labelText: 'Titolo'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Per favore inserisci un titolo';
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
                  title: Text(step.type == 'video' ? 'Video' : 'Domanda'),
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
                    builder: (context) =>
                        AddStepDialog(getThumbnailUrl: _getThumbnailUrl),
                  );
                  if (result != null) {
                    _addStep(result);
                  }
                },
                child: const Text('Aggiungi Step'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('Salva modifiche'),
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

  const AddStepDialog({super.key, required this.getThumbnailUrl, this.step});

  @override
  // ignore: library_private_types_in_public_api
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
      title: Text(widget.step != null ? 'Modifica Step' : 'Aggiungi Step', style: const TextStyle(color: Colors.black)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tipo',
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
                    return 'Per favore seleziona un tipo';
                  }
                  return null;
                },
                style: const TextStyle(color: Colors.black),  // Colore del testo del Dropdown
              ),
              if (_type == 'video') ...[
                TextFormField(
                  initialValue: _content,
                  decoration: const InputDecoration(
                    labelText: 'ID Video',
                    labelStyle: TextStyle(color: Colors.black),
                  ),
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
                  style: const TextStyle(color: Colors.black),  // Colore del testo
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'URL Miniatura',
                    labelStyle: TextStyle(color: Colors.black),
                  ),
                  initialValue: _thumbnailUrl,
                  enabled: false,
                  style: const TextStyle(color: Colors.black),  // Colore del testo
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
                  initialValue: _content,
                  decoration: const InputDecoration(
                    labelText: 'Contenuto',
                    labelStyle: TextStyle(color: Colors.black),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Per favore inserisci un contenuto';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _content = value;
                  },
                  style: const TextStyle(color: Colors.black),  // Colore del testo
                ),
                TextFormField(
                  initialValue: _choices?.join(', '),
                  decoration: const InputDecoration(
                    labelText: 'Scelte (separate da virgola)',
                    labelStyle: TextStyle(color: Colors.black),
                  ),
                  onSaved: (value) {
                    if (value != null && value.isNotEmpty) {
                      _choices = value.split(',').map((choice) => choice.trim()).toList();
                    }
                  },
                  style: const TextStyle(color: Colors.black),  // Colore del testo
                ),
                TextFormField(
                  initialValue: _correctAnswer,
                  decoration: const InputDecoration(
                    labelText: 'Risposta Corretta',
                    labelStyle: TextStyle(color: Colors.black),
                  ),
                  onSaved: (value) {
                    _correctAnswer = value;
                  },
                  style: const TextStyle(color: Colors.black),  // Colore del testo
                ),
                TextFormField(
                  initialValue: _explanation,
                  decoration: const InputDecoration(
                    labelText: 'Spiegazione',
                    labelStyle: TextStyle(color: Colors.black),
                  ),
                  onSaved: (value) {
                    _explanation = value;
                  },
                  style: const TextStyle(color: Colors.black),  // Colore del testo
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
                isShort: _isShort,
              );
              Navigator.of(context).pop(newStep);
            }
          },
          child: Text(widget.step != null ? 'Salva' : 'Aggiungi', style: const TextStyle(color: Colors.black)),
        ),
      ],
    );
  }
}