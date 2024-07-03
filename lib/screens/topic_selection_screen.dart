import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TopicSelectionScreen extends StatefulWidget {
  final User user;

  TopicSelectionScreen({required this.user});

  @override
  _TopicSelectionScreenState createState() => _TopicSelectionScreenState();
}

class _TopicSelectionScreenState extends State<TopicSelectionScreen> {
  final List<String> topics = [
    'Finanza',
    'Legge',
    'Business',
    'Crescita Personale',
    'Storia',
    'Lingue',
    'Attualità',
  ];

  Map<String, bool> selectedTopics = {};

  @override
  void initState() {
    super.initState();
    _initializeTopics();
    _loadSelectedTopics();
  }

  void _initializeTopics() {
    topics.forEach((topic) {
      selectedTopics[topic] = false;
    });
  }

  Future<void> _loadSelectedTopics() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).get();
    if (doc.exists) {
      final userData = doc.data();
      if (userData != null) {
        final userTopics = List<String>.from(userData['topics'] ?? []);
        setState(() {
          userTopics.forEach((topic) {
            selectedTopics[topic] = true;
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seleziona i Topic'),
      ),
      body: ListView(
        children: topics.map((topic) {
          return CheckboxListTile(
            title: Text(
              topic, 
              style: Theme.of(context).textTheme.bodyLarge),
            value: selectedTopics[topic],
            onChanged: (bool? value) {
              setState(() {
                selectedTopics[topic] = value!;
              });
            },checkColor: Colors.black,
            activeColor: Colors.white,
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          List<String> selectedTopicsList = selectedTopics.keys
              .where((topic) => selectedTopics[topic]!)
              .toList();
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.user.uid)
              .update({
            'topics': selectedTopicsList,
          });
          Navigator.pushReplacementNamed(context, '/home');
        },
        child: Icon(Icons.check),
      ),
    );
  }
}