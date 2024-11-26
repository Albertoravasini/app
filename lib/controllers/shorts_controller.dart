import 'package:Just_Learn/main.dart';
import 'package:Just_Learn/screens/quiz_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import '../models/level.dart';


class ShortsController {
  // Metodo per segnare un video come visto
  Future<void> markVideoAsWatched(String videoId, String title, String topic, {bool completed = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final userModel = UserModel.fromMap(userData);

        DateTime now = DateTime.now();

        // Imposta la data corrente e l'ultimo accesso a mezzanotte per il confronto
        DateTime todayAtMidnight = DateTime(now.year, now.month, now.day);
        DateTime lastAccessAtMidnight = DateTime(
          userModel.lastAccess.year,
          userModel.lastAccess.month,
          userModel.lastAccess.day,
        );

        // Verifica se è un nuovo giorno per resettare i contatori giornalieri
        if (todayAtMidnight.isAfter(lastAccessAtMidnight)) {
          userModel.dailyVideosCompleted = 0;
          userModel.dailyQuizFreeUses = 0;
        }

        // Se il video è completato, incrementa il conteggio giornaliero
        if (completed) {
          userModel.dailyVideosCompleted += 1;

          // Calcola il numero di video necessari per sbloccare il quiz
          int requiredVideosForNextFreeUnlock = 3 + (userModel.dailyQuizFreeUses * 5);

          // Controlla se dailyVideosCompleted ha raggiunto il requisito per sbloccare il quiz
          if (userModel.dailyVideosCompleted == requiredVideosForNextFreeUnlock) {
            // Mostra la notifica
            BuildContext? context = navigatorKey.currentContext;
            if (context != null) {
              showOverlayNotification(
                (context) {
                  return Material(
                    color: Colors.transparent,
                    child: SafeArea(
                      child: Center(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: ShapeDecoration(
                            color: Color(0x93333333),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                width: 1,
                                color: Colors.white.withOpacity(0.10000000149011612),
                              ),
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.stars_rounded,
                                  color: Colors.yellowAccent,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '''You've unlocked the Daily Quiz!''',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontFamily: 'Montserrat',
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.48,
                                        height: 1.2,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Click to start now.',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontFamily: 'Montserrat',
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                height: 32,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Traccia l'evento con Posthog
                                    Posthog().capture(
                                      eventName: 'daily_quiz_notification_clicked',
                                      properties: {
                                        'user_id': userModel.uid,
                                        'daily_videos_completed': userModel.dailyVideosCompleted,
                                        'daily_quiz_free_uses': userModel.dailyQuizFreeUses,
                                        'timestamp': DateTime.now().toIso8601String(),
                                      },
                                    );

                                    // Chiudi la notifica
                                    OverlaySupportEntry.of(context)?.dismiss();

                                    // Naviga alla QuizScreen con la BottomNavigationBar visibile
                                    navigatorKey.currentState?.pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => MainScreen(
                                          userModel: userModel,
                                          initialIndex: 2, // Indice per mostrare QuizScreen
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.yellowAccent,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                  ),
                                  child: Text(
                                    'Start',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.48,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                duration: Duration(seconds: 5),
              );
            }
          }
        }

      // Aggiorna la lista dei video visti
      userModel.WatchedVideos[topic] ??= [];
      final existingVideoIndex = userModel.WatchedVideos[topic]!.indexWhere((video) => video.videoId == videoId);

      if (existingVideoIndex != -1) {
        // Aggiorna il video esistente
        userModel.WatchedVideos[topic]![existingVideoIndex] = VideoWatched(
          videoId: videoId,
          title: title,
          watchedAt: now,
          completed: userModel.WatchedVideos[topic]![existingVideoIndex].completed || completed,
        );
      } else {
        // Aggiungi un nuovo video visto
        userModel.WatchedVideos[topic]!.add(VideoWatched(
          videoId: videoId,
          title: title,
          watchedAt: now,
          completed: completed,
        ));
      }

      // Aggiorna lastAccess con la data corrente
      userModel.lastAccess = now;

      // Aggiorna Firestore con i nuovi dati utente
      await userDocRef.update(userModel.toMap());
    }
  }
}
  // Metodo per ottenere il documento di partenza per la paginazione
  Future<DocumentSnapshot?> _getDocumentAfter(int offset) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('levels')
        .orderBy('subtopicOrder')
        .orderBy('levelNumber')
        .limit(offset)
        .get();
    return snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
  }

  // Metodo per salvare un video per un utente
  Future<void> saveVideo(String videoId, String title) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final savedVideos = userData['SavedVideos'] as List<dynamic>? ?? [];

        // Aggiungi il video salvato se non è già presente
        final isVideoSaved = savedVideos.any((video) => video['videoId'] == videoId);
        if (!isVideoSaved) {
          savedVideos.add({
            'videoId': videoId,
            'title': title,
            'savedAt': DateTime.now().toIso8601String(),
          });

          await userDocRef.update({'SavedVideos': savedVideos});
        }
      }
    }
  }

  // Metodo per rimuovere un video salvato per un utente
  Future<void> unsaveVideo(String videoId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final savedVideos = userData['SavedVideos'] as List<dynamic>? ?? [];

        // Rimuovi il video salvato se presente
        savedVideos.removeWhere((video) => video['videoId'] == videoId);

        await userDocRef.update({'SavedVideos': savedVideos});
      }
    }
  }

  // Metodo per verificare se un video è stato salvato
  Future<bool> isVideoSaved(String videoId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final savedVideos = userData['SavedVideos'] as List<dynamic>? ?? [];
        return savedVideos.any((video) => video['videoId'] == videoId);
      }
    }
    return false;
  }
}