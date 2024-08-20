import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/level.dart';

class EditLevelScreen extends StatefulWidget {
  final Level level;

  EditLevelScreen({required this.level});

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

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      FirebaseFirestore.instance
          .collection('levels')
          .doc(widget.level.levelNumber.toString())
          .update({
        'title': _title,
        'steps': _steps.map((step) => step.toMap()).toList(),
      }).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Livello aggiornato con successo',
                style: TextStyle(color: Colors.white))));
        Navigator.pop(context);
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Errore nell\'aggiornamento del livello: $error',
                style: TextStyle(color: Colors.white))));
      });
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
        title: Text('Modifica Livello'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(labelText: 'Titolo'),
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
              SizedBox(height: 20),
              Text('Steps:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        icon: Icon(Icons.edit),
                        onPressed: () => _showEditStepDialog(step, index),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
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
                child: Text('Aggiungi Step'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveChanges,
                child: Text('Salva modifiche'),
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

  AddStepDialog({required this.getThumbnailUrl, this.step});

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
      title: Text(widget.step != null ? 'Modifica Step' : 'Aggiungi Step', style: TextStyle(color: Colors.black)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Tipo',
                  labelStyle: TextStyle(color: Colors.black),
                ),
                value: _type,
                items: ['video', 'question'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: TextStyle(color: Colors.black)),
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
                style: TextStyle(color: Colors.black),  // Colore del testo del Dropdown
              ),
              if (_type == 'video') ...[
                TextFormField(
                  initialValue: _content,
                  decoration: InputDecoration(
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
                  style: TextStyle(color: Colors.black),  // Colore del testo
                ),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'URL Miniatura',
                    labelStyle: TextStyle(color: Colors.black),
                  ),
                  initialValue: _thumbnailUrl,
                  enabled: false,
                  style: TextStyle(color: Colors.black),  // Colore del testo
                ),
                CheckboxListTile(
                  title: Text('È uno short?', style: TextStyle(color: Colors.black)),
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
                  decoration: InputDecoration(
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
                  style: TextStyle(color: Colors.black),  // Colore del testo
                ),
                TextFormField(
                  initialValue: _choices?.join(', '),
                  decoration: InputDecoration(
                    labelText: 'Scelte (separate da virgola)',
                    labelStyle: TextStyle(color: Colors.black),
                  ),
                  onSaved: (value) {
                    if (value != null && value.isNotEmpty) {
                      _choices = value.split(',').map((choice) => choice.trim()).toList();
                    }
                  },
                  style: TextStyle(color: Colors.black),  // Colore del testo
                ),
                TextFormField(
                  initialValue: _correctAnswer,
                  decoration: InputDecoration(
                    labelText: 'Risposta Corretta',
                    labelStyle: TextStyle(color: Colors.black),
                  ),
                  onSaved: (value) {
                    _correctAnswer = value;
                  },
                  style: TextStyle(color: Colors.black),  // Colore del testo
                ),
                TextFormField(
                  initialValue: _explanation,
                  decoration: InputDecoration(
                    labelText: 'Spiegazione',
                    labelStyle: TextStyle(color: Colors.black),
                  ),
                  onSaved: (value) {
                    _explanation = value;
                  },
                  style: TextStyle(color: Colors.black),  // Colore del testo
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
                isShort: _isShort,
              );
              Navigator.of(context).pop(newStep);
            }
          },
          child: Text(widget.step != null ? 'Salva' : 'Aggiungi', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }
}