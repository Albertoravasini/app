import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class TopicSelectionScreen extends StatefulWidget {
  final User user;
  final bool isRegistration;

  TopicSelectionScreen({required this.user, this.isRegistration = false});

  @override
  _TopicSelectionScreenState createState() => _TopicSelectionScreenState();
}

class _TopicSelectionScreenState extends State<TopicSelectionScreen> {
  final List<String> allTopics = [];
  String? selectedTopic;

  @override
  void initState() {
    super.initState();
    _loadAllTopics();
  }

  Future<void> _loadAllTopics() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('topics').get();
    setState(() {
      allTopics.addAll(querySnapshot.docs.map((doc) => doc.id).toList());
    });
    _loadSelectedTopic();
  }

  Future<void> _loadSelectedTopic() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).get();
    if (doc.exists) {
      final userData = doc.data();
      if (userData != null) {
        final userTopics = List<String>.from(userData['topics'] ?? []);
        setState(() {
          if (userTopics.isNotEmpty) {
            selectedTopic = userTopics.first;
          }
        });
      }
    }
  }

  Future<void> _saveSelectedTopic() async {
    await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
      'topics': [selectedTopic],
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
        child: Column(
          children: [
            const SizedBox(height: 30), // Aggiunto spazio extra per abbassare il titolo
            Container(
              width: 324,
              child: Text(
                'Seleziona degli argomenti',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 45,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: allTopics.map((topic) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTopic = topic;
                      });
                    },
                    child: Container(
                      width: 324,
                      height: 56,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 17),
                      decoration: ShapeDecoration(
                        color: selectedTopic == topic ? Colors.white : Colors.transparent,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(width: 1, color: Colors.white),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          topic,
                          style: TextStyle(
                            color: selectedTopic == topic ? Colors.black : Colors.white,
                            fontSize: 16,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                if (selectedTopic != null) {
                  await _saveSelectedTopic();
                  if (widget.isRegistration) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                  } else {
                    Navigator.pop(context, true); // Indica che abbiamo aggiornato i topic
                  }
                }
              },
              child: Container(
                width: 324,
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 1, color: Colors.white),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Inizia',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.48,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}