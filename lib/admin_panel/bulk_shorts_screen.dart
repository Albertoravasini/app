import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BulkShortsScreen extends StatefulWidget {
  @override
  _BulkShortsScreenState createState() => _BulkShortsScreenState();
}

class _BulkShortsScreenState extends State<BulkShortsScreen> {
  String? _selectedTopic;
  List<Map<String, dynamic>> _levels = [];
  List<String> _topics = [];
  Map<String, int> _levelCountBySubtopic = {};
  List<String> _subtopics = [];
  Map<String, int> _subtopicOrderMap = {}; // Mappa per subtopicOrder

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
    final levelsCollection = FirebaseFirestore.instance.collection('levels');
    final querySnapshot = await levelsCollection
        .where('topic', isEqualTo: topic)
        .orderBy('subtopicOrder') // Assicurati che Firestore abbia un indice per questa query
        .get();

    final fetchedSubtopics = querySnapshot.docs
        .map((doc) => doc['subtopic'] as String)
        .toSet()
        .toList();

    final Map<String, int> levelCountMap = {};
    final Map<String, int> subtopicOrderMap = {};
    int currentOrder = 1;

    for (var doc in querySnapshot.docs) {
      final subtopic = doc['subtopic'] as String;
      if (!subtopicOrderMap.containsKey(subtopic)) {
        subtopicOrderMap[subtopic] = currentOrder;
        currentOrder++;
      }

      if (levelCountMap.containsKey(subtopic)) {
        levelCountMap[subtopic] = levelCountMap[subtopic]! + 1;
      } else {
        levelCountMap[subtopic] = 1;
      }
    }

    setState(() {
      _subtopics = fetchedSubtopics;
      _levelCountBySubtopic = levelCountMap;
      _subtopicOrderMap = subtopicOrderMap;
    });
  }

  void _addLevel() {
    setState(() {
      _levels.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(), // Identificatore unico
        'subtopic': '',
        'title': '',
        'videoId': '',
        'levelNumber': 0, // Inizialmente 0, sarà aggiornato quando viene selezionato un subtopic
        'videoExists': false,
        'isShort': true, // Imposta isShort su true per default
        'thumbnailUrl': '', // Inizializza con stringa vuota
        'subtopicOrder': 0, // Inizialmente 0, sarà aggiornato
      });
    });
  }

  void _removeLevel(int index) {
    setState(() {
      final removedLevel = _levels.removeAt(index);
      final subtopic = removedLevel['subtopic'];
      if (_levelCountBySubtopic.containsKey(subtopic)) {
        _levelCountBySubtopic[subtopic] = _levelCountBySubtopic[subtopic]! - 1;
        if (_levelCountBySubtopic[subtopic]! <= 0) {
          _levelCountBySubtopic.remove(subtopic);
        }
      }

      // Se nessun livello rimane per questo subtopic, rimuovi anche il subtopicOrderMap
      if (!_levels.any((level) => level['subtopic'] == subtopic)) {
        _subtopicOrderMap.remove(subtopic);
        _subtopics.remove(subtopic);
      }
    });
  }

  // Funzione per controllare se un video ID esiste in tutto il database
  Future<void> _checkVideoExists(int index, String videoId) async {
    if (videoId.isEmpty) {
      setState(() {
        _levels[index]['videoExists'] = false;
      });
      return;
    }

    try {
      print("Controllo se esiste l'ID video: $videoId");

      // Recupera tutti i documenti dalla collezione 'levels'
      final querySnapshot = await FirebaseFirestore.instance.collection('levels').get();

      bool videoExists = false;

      for (var doc in querySnapshot.docs) {
        // Ottieni il campo 'steps' dal documento
        List<dynamic> steps = doc['steps'];

        // Controlla se uno degli step contiene il videoId specificato
        for (var step in steps) {
          if (step['type'] == 'video' && step['content'] == videoId) {
            videoExists = true;
            break;
          }
        }

        if (videoExists) break;
      }

      setState(() {
        _levels[index]['videoExists'] = videoExists;
      });

      print("L'ID video esiste? ${_levels[index]['videoExists']}");
    } catch (e) {
      print("Errore durante il controllo dell'ID video: $e");
    }
  }

  Future<void> _saveLevels() async {
    if (_selectedTopic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seleziona un topic')),
      );
      return;
    }

    for (var level in _levels) {
      if (level['subtopic'].isEmpty || level['title'].isEmpty || level['videoId'].isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Per favore completa tutti i campi per ogni livello')),
        );
        return;
      }
      if (level['videoExists']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ID video ${level['videoId']} esiste già')),
        );
        return;
      }
    }

    final batch = FirebaseFirestore.instance.batch();
    for (var level in _levels) {
      final videoId = level['videoId'];
      final thumbnailUrl = _getThumbnailUrl(videoId); // Genera l'URL della miniatura

      final levelData = {
        'topic': _selectedTopic,
        'subtopic': level['subtopic'],
        'title': level['title'],
        'levelNumber': level['levelNumber'],
        'subtopicOrder': level['subtopicOrder'], // Includi subtopicOrder
        'steps': [
          {
            'type': 'video',
            'content': videoId,
            'isShort': level['isShort'], // Imposta isShort
            'thumbnailUrl': thumbnailUrl, // Imposta l'URL della miniatura
          },
        ],
      };
      batch.set(FirebaseFirestore.instance.collection('levels').doc(), levelData);
    }

    try {
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Livelli aggiunti con successo')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante il salvataggio: $e')),
      );
      // Mantieni lo stato corrente per permettere all'utente di correggere eventuali errori
    }
  }

  Future<void> _createSubtopic(int index) async {
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
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(subtopicName),
              child: const Text('Crea'),
            ),
          ],
        );
      },
    );

    if (newSubtopic != null && newSubtopic.isNotEmpty) {
      setState(() {
        _subtopics.add(newSubtopic);
        _subtopicOrderMap[newSubtopic] = _subtopicOrderMap.length + 1; // Assegna il prossimo ordine disponibile
        _levels[index]['subtopic'] = newSubtopic;
        _levels[index]['levelNumber'] = 1; // Il primo livello per un nuovo subtopic
        _levelCountBySubtopic[newSubtopic] = 1; // Aggiungi alla mappa dei conteggi
        _levels[index]['subtopicOrder'] = _subtopicOrderMap[newSubtopic]!; // Imposta subtopicOrder
      });
    }
  }

  void _updateLevelNumber(int index, String subtopic) {
    setState(() {
      if (_levelCountBySubtopic.containsKey(subtopic)) {
        _levelCountBySubtopic[subtopic] = _levelCountBySubtopic[subtopic]! + 1;
      } else {
        _levelCountBySubtopic[subtopic] = 1;
      }
      _levels[index]['levelNumber'] = _levelCountBySubtopic[subtopic]!;
      _levels[index]['subtopicOrder'] = _subtopicOrderMap[subtopic]!; // Assegna subtopicOrder
    });
  }

  String _getThumbnailUrl(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/0.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aggiungi Livelli in Bulk', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveLevels,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Seleziona Topic',
                labelStyle: TextStyle(color: Colors.white),
              ),
              items: _topics.map((topic) {
                return DropdownMenuItem(
                  value: topic,
                  child: Text(topic),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTopic = value;
                  _levels.clear();
                  _subtopics.clear();
                  _subtopicOrderMap.clear(); // Resetta la mappa dell'ordine dei subtopics
                  _levelCountBySubtopic.clear(); // Resetta i conteggi
                });
                _loadSubtopics(value!);
              },
              value: _selectedTopic,
              style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
              dropdownColor: Colors.black,
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _levels.length,
                itemBuilder: (context, index) {
                  final level = _levels[index];
                  return Card(
                    key: ValueKey(level['id']), // Assegna la chiave unica
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(labelText: 'Subtopic'),
                                  items: [
                                    ..._subtopics.map((subtopic) {
                                      return DropdownMenuItem(
                                        value: subtopic,
                                        child: Text(subtopic),
                                      );
                                    }),
                                    DropdownMenuItem(
                                      value: 'new',
                                      child: Text('Crea nuovo subtopic'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == 'new') {
                                      _createSubtopic(index);
                                    } else {
                                      setState(() {
                                        _levels[index]['subtopic'] = value!;
                                        _updateLevelNumber(index, value); // Aggiorna il levelNumber e subtopicOrder
                                      });
                                    }
                                  },
                                  value: level['subtopic'].isEmpty ? null : level['subtopic'],
                                  style: TextStyle(color: Colors.black),
                                  dropdownColor: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Livello: ${level['levelNumber']}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Ordine Subtopic: ${level['subtopicOrder']}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          TextFormField(
                            decoration: InputDecoration(labelText: 'Titolo'),
                            style: TextStyle(color: Colors.black),
                            initialValue: level['title'],
                            onChanged: (value) {
                              setState(() {
                                _levels[index]['title'] = value;
                              });
                            },
                          ),
                          SizedBox(height: 10),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'ID Video',
                              errorText: level['videoExists'] ? 'ID video già esistente' : null,
                            ),
                            style: TextStyle(color: Colors.black),
                            initialValue: level['videoId'],
                            onChanged: (value) {
                              setState(() {
                                _levels[index]['videoId'] = value;
                                _levels[index]['thumbnailUrl'] = _getThumbnailUrl(value); // Aggiorna l'URL della miniatura
                              });
                              _checkVideoExists(index, value); // Verifica in tempo reale
                            },
                          ),
                          SizedBox(height: 10),
                          if (level['thumbnailUrl'].isNotEmpty)
                            Image.network(level['thumbnailUrl']),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _removeLevel(index),
                                color: Colors.red,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: _addLevel,
              icon: Icon(Icons.add),
              label: Text('Aggiungi Livello'),
            ),
          ],
        ),
      ),
    );
  }
}