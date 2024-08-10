import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/level.dart';

Future<void> createLevels() async {
  final levels = [
    
    
  ];

  final levelsCollection = FirebaseFirestore.instance.collection('levels');
    for (var level in levels) {
      await levelsCollection.doc(level.levelNumber.toString()).set(level.toMap());
    }
}