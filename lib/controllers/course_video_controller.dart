import 'package:Just_Learn/controllers/video_player_manager.dart';
import 'package:Just_Learn/models/course.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:Just_Learn/screens/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Just_Learn/services/firebase_service.dart';

class CourseVideoController {
  final VideoPlayerManager videoManager;
  final Course? course;
  final Function(Course?, Section?) onStartCourse;
  final Function(bool) onUnlockOptionsChanged;
  final Function(int) onCoinsUpdate;
  final FirebaseService _firebaseService = FirebaseService();

  CourseVideoController({
    required this.videoManager,
    this.course,
    required this.onStartCourse,
    required this.onUnlockOptionsChanged,
    required this.onCoinsUpdate,
  });

  Future<void> handleStartCourse(BuildContext context) async {
    if (course == null) return;
    
    try {
      final hasSubscription = await _firebaseService.hasSubscription(course!.authorId);
      final hasCourseAccess = await _firebaseService.hasCourseAccess(course!.id);
      
      if (hasSubscription || hasCourseAccess) {
        videoManager.pauseCurrentVideo();
        onStartCourse(course, null);
      } else {
        onUnlockOptionsChanged(true);
      }
    } catch (e) {
      // Gestione errori
    }
  }

  Future<void> handleUnlockCourse(BuildContext context) async {
    if (course == null) return;
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) throw Exception('User document not found');

        final userData = UserModel.fromMap(doc.data()!);
        if (userData.coins < course!.cost) {
          throw InsufficientCoinsException();
        }

        final updatedCoins = userData.coins - course!.cost;
        transaction.update(docRef, {
          'coins': updatedCoins,
          'unlockedCourses': FieldValue.arrayUnion([course!.id])
        });

        // Aggiorna il contatore delle monete nell'UI
        onCoinsUpdate(updatedCoins);
      });

      videoManager.pauseCurrentVideo();
      onStartCourse(course, null);
      onUnlockOptionsChanged(false);
      
    } on InsufficientCoinsException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Non hai abbastanza coins'))
      );
    } catch (e) {
      print('Error unlocking course: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Si è verificato un errore'))
      );
    }
  }

  Future<void> handleSubscribe(BuildContext context) async {
    videoManager.pauseCurrentVideo();
    // ... implementazione della navigazione al profilo
  }

  bool get showUnlockOptions => onUnlockOptionsChanged(true);

  void handleQuitCourse() {
    onStartCourse(null, null);
  }

  Future<void> navigateToAuthorProfile(BuildContext context) async {
    videoManager.pauseCurrentVideo();
    
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(course?.authorId)
        .get();
    
    if (!userDoc.exists || !context.mounted) return;

    final author = UserModel.fromMap(userDoc.data()!);
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(currentUser: author),
      ),
    );

    videoManager.playCurrentVideo();
  }

  Future<bool> hasSubscription(String authorId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final userData = UserModel.fromMap(doc.data()!);
        return userData.subscriptions.contains(authorId);
      }
    }
    return false;
  }
} 