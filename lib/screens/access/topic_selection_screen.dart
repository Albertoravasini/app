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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          image: DecorationImage(
            image: AssetImage('assets/pattern_bg.png'),
            opacity: 0.05,
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // Header con back button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main content
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF181819),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    // Titolo animato
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, double value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: const Text(
                              'Choose\nYour Path',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select a topic to start learning',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Lista topics
                    Expanded(
                      child: ListView.builder(
                        itemCount: allTopics.length,
                        itemBuilder: (context, index) {
                          final topic = allTopics[index];
                          return _buildTopicItem(topic);
                        },
                      ),
                    ),

                    // Continue Button
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: _buildPrimaryButton(
                        onTap: () async {
                          if (selectedTopic != null) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.user.uid)
                                .update({
                              'topics': [selectedTopic],
                            });

                            final userDoc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.user.uid)
                                .get();

                            if (userDoc.exists) {
                              final userModel = UserModel.fromMap(userDoc.data()!);
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MainScreen(userModel: userModel),
                                ),
                                (route) => false,
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a topic to continue'),
                              ),
                            );
                          }
                        },
                        text: 'Continue',
                        isEnabled: selectedTopic != null,
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

  Widget _buildTopicItem(String topic) {
    final isSelected = selectedTopic == topic;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTopic = topic;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.yellowAccent.withOpacity(0.1)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.yellowAccent.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          topic,
          style: TextStyle(
            color: isSelected ? Colors.yellowAccent : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback onTap,
    required String text,
    required bool isEnabled,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.yellowAccent : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isEnabled ? Colors.black : Colors.white.withOpacity(0.5),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Montserrat',
            ),
          ),
        ),
      ),
    );
  }
}