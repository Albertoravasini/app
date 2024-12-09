// lib/admin_panel/course_edit_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course.dart';
import '../models/level.dart';

class CourseEditScreen extends StatefulWidget {
  final Course? course;

  const CourseEditScreen({Key? key, this.course}) : super(key: key);

  @override
  _CourseEditScreenState createState() => _CourseEditScreenState();
}

class _CourseEditScreenState extends State<CourseEditScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedTopic;
  String? _courseTitle;
  String? _courseDescription;
  int? _courseCost;
  List<String> _topics = [];
  List<Section> _sections = [];
  bool _isEditing = false;
  String? _coverImageUrl;

  // Nuovi campi per fonti, ringraziamenti e approfondimenti
  List<String> _sources = [];
  List<String> _acknowledgments = [];
  List<String> _recommendedBooks = [];
  List<String> _recommendedPodcasts = [];
  List<String> _recommendedWebsites = [];

  @override
  void initState() {
    super.initState();
    _loadTopics();

    if (widget.course != null) {
      _isEditing = true;
      _selectedTopic = widget.course!.topic;
      _courseTitle = widget.course!.title;
      _courseDescription = widget.course!.description;
      _courseCost = widget.course!.cost;
      _sections = widget.course!.sections;
      _coverImageUrl = widget.course!.coverImageUrl;

      // Inizializza i nuovi campi
      _sources = List.from(widget.course!.sources);
      _acknowledgments = List.from(widget.course!.acknowledgments);
      _recommendedBooks = List.from(widget.course!.recommendedBooks);
      _recommendedPodcasts = List.from(widget.course!.recommendedPodcasts);
      _recommendedWebsites = List.from(widget.course!.recommendedWebsites);
    }
  }

  Future<void> _loadTopics() async {
    final topicsCollection = FirebaseFirestore.instance.collection('topics');
    final querySnapshot = await topicsCollection.get();
    setState(() {
      _topics = querySnapshot.docs.map((doc) => doc.id).toList();
    });
  }

  // Funzione per aggiungere elementi alle liste
  void _addItemDialog(String title, Function(String) onAdd) {
    String? newItem;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            title,
            style: TextStyle(color: Colors.white),
          ),
          content: TextFormField(
            decoration: InputDecoration(
              labelText: title,
              labelStyle: TextStyle(color: Colors.white),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blueAccent),
              ),
            ),
            style: TextStyle(color: Colors.white),
            onChanged: (value) {
              newItem = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annulla',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                if (newItem != null && newItem!.isNotEmpty) {
                  onAdd(newItem!);
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Aggiungi',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  // Funzione per rimuovere elementi dalle liste
  void _removeItem(List<String> list, int index) {
    setState(() {
      list.removeAt(index);
    });
  }

  void _addSection() {
    String? sectionTitle;
    String? imageUrl;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Aggiungi Capitolo',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Titolo Capitolo'),
                style: TextStyle(color: Colors.white),
                onChanged: (value) {
                  sectionTitle = value;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'URL Immagine (opzionale)'),
                style: TextStyle(color: Colors.white),
                onChanged: (value) {
                  imageUrl = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Annulla',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                if (sectionTitle != null && sectionTitle!.isNotEmpty) {
                  setState(() {
                    _sections.add(Section(
                      title: sectionTitle!,
                      steps: [],
                      imageUrl: imageUrl,
                      sectionNumber: _sections.length + 1,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Salva',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  void _editSection(Section section, int index) {
    String? sectionTitle = section.title;
    String? imageUrl = section.imageUrl;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Modifica Capitolo',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: section.title,
                decoration:
                    const InputDecoration(labelText: 'Titolo Capitolo'),
                style: TextStyle(color: Colors.white),
                onChanged: (value) {
                  sectionTitle = value;
                },
              ),
              TextFormField(
                initialValue: section.imageUrl,
                decoration: const InputDecoration(
                    labelText: 'URL Immagine (opzionale)'),
                style: TextStyle(color: Colors.white),
                onChanged: (value) {
                  imageUrl = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Eliminazione del capitolo
                _deleteSection(index);
              },
              child: Text(
                'Elimina',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            TextButton(
              onPressed: () {
                if (sectionTitle != null && sectionTitle!.isNotEmpty) {
                  setState(() {
                    _sections[index].title = sectionTitle!;
                    _sections[index].imageUrl = imageUrl;
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Salva',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteSection(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Elimina Capitolo',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Sei sicuro di voler eliminare questo capitolo?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annulla',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _sections.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Capitolo eliminato con successo')),
              );
            },
            child: Text(
              'Elimina',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _addStepDialog(Section section, int sectionIndex) {
    String? stepType;
    String? content;
    String? videoUrl;
    String? videoTitle;
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
              backgroundColor: Colors.grey[900],
              title: Text(
                'Aggiungi Step',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Tipo Step'),
                      dropdownColor: Colors.grey[900],
                      items: ['video', 'question'].map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(
                            type,
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          stepType = value;
                        });
                      },
                      style: TextStyle(color: Colors.white),
                    ),
                    if (stepType == 'video') ...[
                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: 'ID Video YouTube'),
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) {
                          videoUrl = value;
                          
                        },
                      ),
                      TextFormField(
                        decoration:
                            const InputDecoration(labelText: 'Titolo Video'),
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) {
                          videoTitle = value;
                        },
                      ),
                      if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Image.network(thumbnailUrl!),
                        ),
                    ] else if (stepType == 'question') ...[
                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: 'Contenuto Domanda'),
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) {
                          content = value;
                        },
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: 'Opzioni (separate da virgole)'),
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) {
                          choices =
                              value.split(',').map((e) => e.trim()).toList();
                        },
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: 'Risposta Corretta'),
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) {
                          correctAnswer = value;
                        },
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: 'Spiegazione'),
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) {
                          explanation = value;
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Annulla',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (stepType == 'video' &&
                        videoUrl != null &&
                        videoUrl!.isNotEmpty &&
                        videoTitle != null &&
                        videoTitle!.isNotEmpty) {
                      setState(() {
                        section.steps.add(LevelStep(
                          type: 'video',
                          content: videoTitle ?? section.title,
                          videoUrl: videoUrl,
                          thumbnailUrl: thumbnailUrl,
                        ));
                      });
                    } else if (stepType == 'question' &&
                        content != null &&
                        content!.isNotEmpty &&
                        correctAnswer != null &&
                        correctAnswer!.isNotEmpty &&
                        choices != null &&
                        choices!.isNotEmpty) {
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
                  child: Text(
                    'Aggiungi Step',
                    style: TextStyle(color: Colors.blueAccent),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editStepDialog(Section section, int sectionIndex, LevelStep step, int stepIndex) {
    String? stepType = step.type;
    String? content = step.content;
    String? videoUrl = step.videoUrl;
    String? videoTitle = step.type == 'video' ? step.content : null;
    String? correctAnswer = step.correctAnswer;
    List<String>? choices = step.choices;
    String? explanation = step.explanation;
    String? thumbnailUrl = step.thumbnailUrl;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text(
                'Modifica Step',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: stepType,
                      decoration: const InputDecoration(labelText: 'Tipo Step'),
                      dropdownColor: Colors.grey[900],
                      items: ['video', 'question'].map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(
                            type,
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          stepType = value;
                        });
                      },
                      style: TextStyle(color: Colors.white),
                    ),
                    if (stepType == 'video') ...[
                      TextFormField(
                        initialValue: videoUrl,
                        decoration: const InputDecoration(
                            labelText: 'ID Video YouTube'),
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) {
                          videoUrl = value;
                          setState(() {
                            thumbnailUrl =
                                'https://img.youtube.com/vi/$value/0.jpg';
                          });
                        },
                      ),
                      TextFormField(
                        initialValue: videoTitle,
                        decoration:
                            const InputDecoration(labelText: 'Titolo Video'),
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) {
                          videoTitle = value;
                        },
                      ),
                      if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Image.network(thumbnailUrl!),
                        ),
                    ] else if (stepType == 'question') ...[
                      TextFormField(
                        initialValue: content,
                        decoration: const InputDecoration(
                            labelText: 'Contenuto Domanda'),
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) {
                          content = value;
                        },
                      ),
                      TextFormField(
                        initialValue: choices?.join(', '),
                        decoration: const InputDecoration(
                            labelText: 'Opzioni (separate da virgole)'),
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) {
                          choices =
                              value.split(',').map((e) => e.trim()).toList();
                        },
                      ),
                      TextFormField(
                        initialValue: correctAnswer,
                        decoration: const InputDecoration(
                            labelText: 'Risposta Corretta'),
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) {
                          correctAnswer = value;
                        },
                      ),
                      TextFormField(
                        initialValue: explanation,
                        decoration: const InputDecoration(
                            labelText: 'Spiegazione'),
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) {
                          explanation = value;
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Eliminazione dello step
                    _deleteStep(sectionIndex, stepIndex);
                  },
                  child: Text(
                    'Elimina',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (stepType == 'video' &&
                        videoUrl != null &&
                        videoUrl!.isNotEmpty &&
                        videoTitle != null &&
                        videoTitle!.isNotEmpty) {
                      setState(() {
                        _sections[sectionIndex].steps[stepIndex] = LevelStep(
                          type: 'video',
                          content: videoTitle!,
                          videoUrl: videoUrl!,
                          thumbnailUrl: thumbnailUrl,
                        );
                      });
                    } else if (stepType == 'question' &&
                        content != null &&
                        content!.isNotEmpty &&
                        correctAnswer != null &&
                        correctAnswer!.isNotEmpty &&
                        choices != null &&
                        choices!.isNotEmpty) {
                      setState(() {
                        _sections[sectionIndex].steps[stepIndex] = LevelStep(
                          type: 'question',
                          content: content!,
                          choices: choices!,
                          correctAnswer: correctAnswer!,
                          explanation: explanation,
                        );
                      });
                    }
                    setState(() {}); // Aggiorna la UI
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Salva',
                    style: TextStyle(color: Colors.blueAccent),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteStep(int sectionIndex, int stepIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Elimina Step',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Sei sicuro di voler eliminare questo step?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annulla',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _sections[sectionIndex].steps.removeAt(stepIndex);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Step eliminato con successo')),
              );
            },
            child: Text(
              'Elimina',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

void _saveCourse() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Ottieni l'utente corrente
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Devi essere autenticato per salvare un corso')),
        );
        return;
      }

      // Ottieni i dati dell'utente da Firestore
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .then((userDoc) {
        if (!userDoc.exists) {
          throw Exception('User document not found');
        }

        final userData = userDoc.data()!;
        final courseData = {
          'title': _courseTitle!,
          'description': _courseDescription!,
          'cost': _courseCost!,
          'topic': _selectedTopic!,
          'visible': widget.course?.visible ?? true,
          'sections': _sections.map((section) => section.toMap()).toList(),
          'coverImageUrl': _coverImageUrl,
          'sources': _sources,
          'acknowledgments': _acknowledgments,
          'recommendedBooks': _recommendedBooks,
          'recommendedPodcasts': _recommendedPodcasts,
          'recommendedWebsites': _recommendedWebsites,
          // Aggiungi i campi dell'autore
          'authorId': user.uid,
          'authorName': userData['name'] ?? 'Unknown Author',
          'authorProfileUrl': userData['profileImageUrl'] ?? '',
        };

        if (_isEditing) {
          FirebaseFirestore.instance
              .collection('courses')
              .doc(widget.course!.id)
              .update(courseData)
              .then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Corso aggiornato con successo')),
            );
            Navigator.pop(context, true);
          }).catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Errore nell\'aggiornare il corso: $error')),
            );
          });
        } else {
          FirebaseFirestore.instance
              .collection('courses')
              .add(courseData)
              .then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Corso creato con successo')),
            );
            Navigator.pop(context, true);
          }).catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Errore nella creazione del corso: $error')),
            );
          });
        }
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel recuperare i dati dell\'utente: $error')),
        );
      });
    }
  }

  // Aggiungi questa funzione per migrare i corsi esistenti
  Future<void> migrateExistingCourses() async {
    try {
      final coursesRef = FirebaseFirestore.instance.collection('courses');
      final QuerySnapshot coursesSnapshot = await coursesRef.get();

      // Ottieni i dati dell'admin
      final adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc('YOUR_ADMIN_USER_ID') // Sostituisci con l'ID del tuo utente admin
          .get();

      if (!adminDoc.exists) {
        throw Exception('Admin user document not found');
      }

      final adminData = adminDoc.data()!;
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in coursesSnapshot.docs) {
        final courseData = doc.data() as Map<String, dynamic>;
        
        // Verifica se il corso ha già i campi dell'autore
        if (!courseData.containsKey('authorId')) {
          batch.update(doc.reference, {
            'authorId': adminDoc.id,
            'authorName': adminData['name'] ?? 'JustLearn Admin',
            'authorProfileUrl': adminData['profileImageUrl'] ?? '',
          });
        }
      }

      await batch.commit();
      print('Migrazione completata con successo');
    } catch (e) {
      print('Errore durante la migrazione: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Sfondo nero
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica Corso' : 'Crea Corso'),
        backgroundColor: Colors.grey[900],
      ),
      body: SingleChildScrollView( // Aggiunto per evitare overflow
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedTopic,
                hint: const Text(
                  'Seleziona un topic',
                  style: TextStyle(color: Colors.white),
                ),
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _topics.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedTopic = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Per favore seleziona un topic';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: _courseTitle,
                decoration: const InputDecoration(
                  labelText: 'Titolo Corso',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
                style: TextStyle(color: Colors.white),
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
              SizedBox(height: 16),
              TextFormField(
                initialValue: _courseDescription,
                decoration: const InputDecoration(
                  labelText: 'Descrizione Corso',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
                style: TextStyle(color: Colors.white),
                maxLines: 3,
                onSaved: (value) {
                  _courseDescription = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci una descrizione';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: _courseCost != null ? _courseCost.toString() : null,
                decoration: const InputDecoration(
                  labelText: 'Costo in coins',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.white),
                onSaved: (value) {
                  _courseCost = int.tryParse(value!);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci un costo';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Inserisci un numero valido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: _coverImageUrl,
                decoration: const InputDecoration(
                  labelText: 'URL Immagine di Copertina (opzionale)',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                ),
                style: TextStyle(color: Colors.white),
                onSaved: (value) {
                  _coverImageUrl = value;
                },
              ),
              SizedBox(height: 20),

              // Sezione per Fonti
              Text(
                'Fonti',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Column(
                children: _sources.asMap().entries.map((entry) {
                  int index = entry.key;
                  String source = entry.value;
                  return ListTile(
                    title: Text(source, style: TextStyle(color: Colors.white)),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _removeItem(_sources, index),
                    ),
                  );
                }).toList(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  iconColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _addItemDialog('Aggiungi Fonte', (value) {
                  setState(() {
                    _sources.add(value);
                  });
                }),
                child: const Text(
                  'Aggiungi Fonte',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Sezione per Ringraziamenti
              Text(
                'Ringraziamenti',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Column(
                children: _acknowledgments.asMap().entries.map((entry) {
                  int index = entry.key;
                  String acknowledgment = entry.value;
                  return ListTile(
                    title: Text(acknowledgment, style: TextStyle(color: Colors.white)),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _removeItem(_acknowledgments, index),
                    ),
                  );
                }).toList(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  iconColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _addItemDialog('Aggiungi Ringraziamento', (value) {
                  setState(() {
                    _acknowledgments.add(value);
                  });
                }),
                child: const Text(
                  'Aggiungi Ringraziamento',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Sezione per Approfondimenti
              Text(
                'Approfondimenti',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),

              // Libri
              Text(
                'Libri Consigliati',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Column(
                children: _recommendedBooks.asMap().entries.map((entry) {
                  int index = entry.key;
                  String book = entry.value;
                  return ListTile(
                    title: Text(book, style: TextStyle(color: Colors.white)),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _removeItem(_recommendedBooks, index),
                    ),
                  );
                }).toList(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  iconColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _addItemDialog('Aggiungi Libro', (value) {
                  setState(() {
                    _recommendedBooks.add(value);
                  });
                }),
                child: const Text(
                  'Aggiungi Libro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8),

              // Podcast
              Text(
                'Podcast Consigliati',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Column(
                children: _recommendedPodcasts.asMap().entries.map((entry) {
                  int index = entry.key;
                  String podcast = entry.value;
                  return ListTile(
                    title: Text(podcast, style: TextStyle(color: Colors.white)),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _removeItem(_recommendedPodcasts, index),
                    ),
                  );
                }).toList(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  iconColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _addItemDialog('Aggiungi Podcast', (value) {
                  setState(() {
                    _recommendedPodcasts.add(value);
                  });
                }),
                child: const Text(
                  'Aggiungi Podcast',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8),

              // Siti Web
              Text(
                'Siti Web Consigliati',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Column(
                children: _recommendedWebsites.asMap().entries.map((entry) {
                  int index = entry.key;
                  String website = entry.value;
                  return ListTile(
                    title: Text(website, style: TextStyle(color: Colors.white)),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _removeItem(_recommendedWebsites, index),
                    ),
                  );
                }).toList(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  iconColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _addItemDialog('Aggiungi Sito Web', (value) {
                  setState(() {
                    _recommendedWebsites.add(value);
                  });
                }),
                child: const Text(
                  'Aggiungi Sito Web',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Sezione per Capitoli (esistente)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  iconColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _addSection,
                child: const Text(
                  'Aggiungi Capitolo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _sections.length,
                itemBuilder: (context, index) {
                  final section = _sections[index];
                  return ExpansionTile(
                    backgroundColor: Colors.grey[850],
                    title: Text(
                      section.title,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.edit, color: Colors.white),
                      onPressed: () {
                        _editSection(section, index);
                      },
                    ),
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          iconColor: Colors.blueAccent,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _addStepDialog(section, index),
                        child: const Text(
                          'Aggiungi Step',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: section.steps.length,
                        itemBuilder: (context, stepIndex) {
                          final step = section.steps[stepIndex];
                          return ListTile(
                            title: Text(
                              '${step.type == 'video' ? 'Video' : 'Domanda'}: ${step.content}',
                              style: TextStyle(color: Colors.white),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.white),
                                  onPressed: () {
                                    _editStepDialog(section, index, step, stepIndex);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () {
                                    _deleteStep(index, stepIndex);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    iconColor: Colors.orangeAccent,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveCourse,
                  child: Text(
                    _isEditing ? 'Salva Modifiche' : 'Crea Corso',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



}