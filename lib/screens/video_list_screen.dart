import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/level.dart';
import 'level_screen.dart';

class VideoListScreen extends StatefulWidget {
  @override
  _VideoListScreenState createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  List<LevelStep> allVideoSteps = [];
  List<Level> allLevels = [];

  @override
  void initState() {
    super.initState();
    _loadAllVideoSteps();
  }

  Future<void> _loadAllVideoSteps() async {
    final levelsCollection = FirebaseFirestore.instance.collection('levels');
    final querySnapshot = await levelsCollection.get();
    final levels = querySnapshot.docs.map((doc) => Level.fromFirestore(doc)).toList();

    final videoSteps = levels.expand((level) => level.steps.where((step) => step.type == 'video')).toList();

    setState(() {
      allVideoSteps = videoSteps;
      allLevels = levels;
    });

    allVideoSteps.shuffle(); // Randomizza i video
  }

  void _navigateToLevel(LevelStep step) {
    final level = allLevels.firstWhere((level) => level.steps.contains(step));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LevelScreen(
          level: level,
          onLevelCompleted: () {
            // Puoi implementare la logica di completamento del livello qui se necessario
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: allVideoSteps.length,
        itemBuilder: (context, index) {
          final step = allVideoSteps[index];
          return GestureDetector(
            onTap: () => _navigateToLevel(step),
            child: Container(
              margin: EdgeInsets.all(8.0), // Imposta il margine per spaziatura
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0), // Imposta il raggio degli angoli arrotondati
                      image: DecorationImage(
                        image: NetworkImage(
                          step.thumbnailUrl ?? "https://via.placeholder.com/108x86",
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    width: double.infinity,
                    height: 200.0, // Imposta l'altezza desiderata per l'immagine
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}