import 'package:Just_Learn/main.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:Just_Learn/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TopicSelectionScreen extends StatefulWidget {
  final User user;

  const TopicSelectionScreen({Key? key, required this.user}) : super(key: key);

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
  }

  Future<void> _saveSelectedTopic() async {
    if (selectedTopic != null) {
      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
        'topics': [selectedTopic],
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.only(top: 60, bottom: 0),
        decoration: const BoxDecoration(
          color: Colors.black, // Sfondo nero
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 26,
                  left: 26,
                  right: 25,
                  bottom: 23,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05), // Colore semi-trasparente bianco
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(31),
                    topRight: Radius.circular(31),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(
                      width: double.infinity,
                      child: Text(
                        'What do you want to Improve?',
                        style: TextStyle(
                          color: Colors.white, // Testo bianco
                          fontSize: 45,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: ListView.builder(
                        itemCount: allTopics.length,
                        itemBuilder: (context, index) {
                          final topic = allTopics[index];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedTopic = topic;
                              });
                            },
                            child: Container(
                              height: 56,
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 17),
                              decoration: BoxDecoration(
                                color: selectedTopic == topic ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.05), // Colore del contenitore cambiato
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  width: 1,
                                  color: selectedTopic == topic ? Colors.white : Colors.white12, // Bordi simili a quelli nel login_screen
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  topic,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selectedTopic == topic ? Colors.white : Colors.white70, // Colore del testo cambiato
                                    fontSize: 16,
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    GestureDetector(
                      onTap: () async {
                        if (selectedTopic != null) {
                          await _saveSelectedTopic();
                          final user = FirebaseAuth.instance.currentUser;

                          if (user != null && selectedTopic != null) {
                            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                              'topics': [selectedTopic],
                            });

                            final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

                            if (userDoc.exists) {
                              final updatedUserModel = UserModel.fromMap(userDoc.data()!);

                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MainScreen(userModel: updatedUserModel),
                                ),
                                (Route<dynamic> route) => false,
                              );
                            }
                          }
                        }
                      },
                      child: Container(
                        width: 324,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
                        decoration: BoxDecoration(
                          color: Colors.white, // Bottone bianco
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(width: 1, color: Colors.white12), // Bordi semi-trasparenti
                        ),
                        child: const Center(
                          child: Text(
                            'Continue',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black, // Testo nero
                              fontSize: 16,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}