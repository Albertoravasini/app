import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';

class TutorialOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const TutorialOverlay({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  _TutorialOverlayState createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  Future<void> _markTutorialAsComplete() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'hasSeenTutorial': true});
      
      widget.onComplete();
    }
  }

  Widget _buildTutorialItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.yellowAccent, width: 2),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.yellowAccent,
            size: 30,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to Just Learn!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
              const SizedBox(height: 40),
              
              _buildTutorialItem(
                Icons.monetization_on,
                'Your coins are shown here at the top.\nEarn them by watching videos and answering questions!',
              ),
              
              const SizedBox(height: 30),
              
              _buildTutorialItem(
                Icons.school,
                'Click here to change the video topic',
              ),
              
              const SizedBox(height: 30),
              
              _buildTutorialItem(
                Icons.touch_app,
                'Use these buttons to:\n- Read related articles\n- Save the video\n- Comment\n- Take notes',
              ),
              
              const SizedBox(height: 50),
              
              ElevatedButton(
                onPressed: _markTutorialAsComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellowAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Got it!',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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