// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/level.dart';
import 'edit_level_screen.dart';

class LevelReorderScreen extends StatefulWidget {
  final String selectedTopic;

  const LevelReorderScreen({super.key, required this.selectedTopic});

  @override
  // ignore: library_private_types_in_public_api
  _LevelReorderScreenState createState() => _LevelReorderScreenState();
}

class _LevelReorderScreenState extends State<LevelReorderScreen> {
  List<String> subtopics = [];
  Map<String, List<Level>> levelsBySubtopic = {};
  Map<String, List<GlobalKey>> levelKeys = {};

  @override
  void initState() {
    super.initState();
    _loadSubtopicsAndLevels(widget.selectedTopic);
  }

  Future<void> _loadSubtopicsAndLevels(String topic) async {
    final levelsCollection = FirebaseFirestore.instance.collection('levels');

    final querySnapshot = await levelsCollection
        .where('topic', isEqualTo: topic)
        .orderBy('subtopicOrder')
        .orderBy('levelNumber')
        .get();

    final fetchedLevels = querySnapshot.docs.map((doc) => Level.fromFirestore(doc)).toList();

    Map<String, List<Level>> groupedLevels = {};
    Map<String, List<GlobalKey>> groupedKeys = {};
    for (var level in fetchedLevels) {
      if (!groupedLevels.containsKey(level.subtopic)) {
        groupedLevels[level.subtopic] = [];
        groupedKeys[level.subtopic] = [];
      }
      groupedLevels[level.subtopic]!.add(level);
      groupedKeys[level.subtopic]!.add(GlobalKey());
    }

    setState(() {
      subtopics = groupedLevels.keys.toList();
      levelsBySubtopic = groupedLevels;
      levelKeys = groupedKeys;
    });
  }

  void _onReorderSubtopics(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final subtopic = subtopics.removeAt(oldIndex);
      subtopics.insert(newIndex, subtopic);
    });
  }

  void _onReorderLevels(String oldSubtopic, int oldIndex, String newSubtopic, int newIndex) {
    setState(() {
      final levelsFrom = levelsBySubtopic[oldSubtopic]!;
      final keysFrom = levelKeys[oldSubtopic]!;

      final level = levelsFrom.removeAt(oldIndex);
      final key = keysFrom.removeAt(oldIndex);

      final levelsTo = levelsBySubtopic[newSubtopic]!;
      final keysTo = levelKeys[newSubtopic]!;

      levelsTo.insert(newIndex, level);
      keysTo.insert(newIndex, key);

      // Aggiorna il subtopic del livello spostato
      level.subtopic = newSubtopic;
    });
  }

  Future<void> _renameSubtopic(String oldSubtopic, String newSubtopic) async {
    if (newSubtopic.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();

    final levels = levelsBySubtopic[oldSubtopic]!;
    for (var level in levels) {
      level.subtopic = newSubtopic;
      final levelDoc = FirebaseFirestore.instance.collection('levels').doc(level.id);
      batch.update(levelDoc, {'subtopic': newSubtopic});
    }

    await batch.commit();

    setState(() {
      levelsBySubtopic[newSubtopic] = levelsBySubtopic.remove(oldSubtopic)!;
      subtopics[subtopics.indexOf(oldSubtopic)] = newSubtopic;
      levelKeys[newSubtopic] = levelKeys.remove(oldSubtopic)!;
    });

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subtopic rinominato con successo')));
  }

  Future<void> _showRenameDialog(String oldSubtopic) async {
    final TextEditingController controller = TextEditingController(text: oldSubtopic);

    final newSubtopic = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rinomina Subtopic'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Nuovo nome subtopic'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );

    if (newSubtopic != null && newSubtopic.isNotEmpty && newSubtopic != oldSubtopic) {
      _renameSubtopic(oldSubtopic, newSubtopic);
    }
  }

  Future<void> _saveChanges() async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (int i = 0; i < subtopics.length; i++) {
        final subtopic = subtopics[i];
        final levels = levelsBySubtopic[subtopic]!;

        for (int j = 0; j < levels.length; j++) {
          final level = levels[j];
          batch.update(FirebaseFirestore.instance.collection('levels').doc(level.id), {
            'subtopicOrder': i + 1,
            'levelNumber': j + 1,
            'subtopic': subtopic,
          });
        }
      }

      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Modifiche salvate con successo')));
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore nel salvataggio: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riorganizza Livelli e Subtopic'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: subtopics.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ReorderableListView(
              onReorder: _onReorderSubtopics,
              children: subtopics.map((subtopic) {
                return Card(
                  key: ValueKey(subtopic),
                  margin: const EdgeInsets.all(8.0),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Expanded(child: Text(subtopic, style: const TextStyle(fontWeight: FontWeight.bold))),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showRenameDialog(subtopic),
                        ),
                      ],
                    ),
                    children: [
                      ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        onReorder: (oldIndex, newIndex) => _onReorderLevels(subtopic, oldIndex, subtopic, newIndex),
                        children: levelsBySubtopic[subtopic]!.asMap().entries.map((entry) {
                          final level = entry.value;
                          final key = levelKeys[subtopic]![entry.key];
                          return LongPressDraggable<Level>(
                            key: key,
                            data: level,
                            feedback: Material(
                              elevation: 6.0,
                              child: Container(
                                width: MediaQuery.of(context).size.width - 16, // Full width feedback
                                child: ListTile(
                                  title: Text(level.title),
                                  subtitle: Text('Livello ${level.levelNumber}'),
                                  tileColor: Colors.blueAccent.withOpacity(0.8),
                                ),
                              ),
                            ),
                            childWhenDragging: Container(), // Leave an empty space when dragging
                            child: DragTarget<Level>(
                              onAccept: (receivedLevel) {
                                final oldSubtopic = receivedLevel.subtopic;
                                _onReorderLevels(
                                  oldSubtopic,
                                  levelsBySubtopic[oldSubtopic]!.indexOf(receivedLevel),
                                  subtopic,
                                  entry.key,
                                );
                              },
                              builder: (context, candidateData, rejectedData) {
                                return ListTile(
  title: Text(level.title),
  subtitle: Text('Livello ${level.levelNumber}'),
  trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '${level.numberOfQuestions}', // Numero di domande
        style: TextStyle(
          color: level.numberOfQuestions == 0 ? Colors.red : Colors.green, // Colore rosso se 0, verde se maggiore di 0
          fontWeight: FontWeight.bold,
        ),
      ),
      IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditLevelScreen(level: level),
            ),
          );
        },
      ),
    ],
  ),
);
                              },
                            ),
                          );
                        }).toList(),
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}