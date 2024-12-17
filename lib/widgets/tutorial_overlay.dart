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

class _TutorialOverlayState extends State<TutorialOverlay> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

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

  void _nextStep() {
    _fadeController.reverse().then((_) {
      setState(() {
        _currentStep++;
      });
      _fadeController.forward();
    });
  }

  Widget _buildTutorialContent() {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep();
      case 1:
        return _buildCourseNavigationStep();
      case 2:
        return _buildArticlesStep();
      case 3:
        return _buildCommentsStep();
      case 4:
        return _buildNotesStep();
      default:
        return Container();
    }
  }

  Widget _buildWelcomeStep() {
    return Stack(
      children: [
        Container(color: Colors.black.withOpacity(0.8)),
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.yellowAccent, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.swipe_up, color: Colors.yellowAccent, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Welcome!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Swipe up to browse courses and tap "Start Course" to begin.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildNavigationButtons(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseNavigationStep() {
    return Stack(
      children: [
        Container(color: Colors.black.withOpacity(0.8)),
        Positioned(
          bottom: 10,
          left: 5,
          child: Container(
            width: 160,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Colors.yellowAccent, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Course Navigation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Track progress and navigate chapters through this menu.',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildNavigationButtons(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArticlesStep() {
    return Stack(
      children: [
        Container(color: Colors.black.withOpacity(0.8)),
        Positioned(
          right: 11,
          bottom: 120,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Colors.yellowAccent, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.article, color: Colors.yellowAccent, size: 36),
                const SizedBox(height: 16),
                const Text(
                  'Related Articles',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Access additional resources for this lesson.',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildNavigationButtons(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsStep() {
    return Stack(
      children: [
        Container(color: Colors.black.withOpacity(0.8)),
        Positioned(
          right: 11,
          bottom: 70,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Colors.yellowAccent, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble, color: Colors.yellowAccent, size: 36),
                const SizedBox(height: 16),
                const Text(
                  'AI Chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Get instant answers to your questions.',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildNavigationButtons(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesStep() {
    return Stack(
      children: [
        Container(color: Colors.black.withOpacity(0.8)),
        Positioned(
          right: 11,
          bottom: 20,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Colors.yellowAccent, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit_note, color: Colors.yellowAccent, size: 36),
                const SizedBox(height: 16),
                const Text(
                  'Notes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Save key points while watching.',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildNavigationButtons(isLastStep: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons({bool isLastStep = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(5, (index) => Container(
          width: _currentStep == index ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _currentStep == index 
              ? Colors.yellowAccent 
              : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        )),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: isLastStep ? _markTutorialAsComplete : _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellowAccent,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: Text(
            isLastStep ? 'Start!' : 'Next',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildTutorialContent(),
    );
  }
} 