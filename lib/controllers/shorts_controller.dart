import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Just_Learn/models/user.dart';
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

  // Metodo per ottenere lo stato del like di un video
  Future<bool> getLikeStatus(String videoId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final likedVideos = userData['LikedVideos'] as List<dynamic>? ?? [];
        return likedVideos.contains(videoId);
      }
    }
    return false;
  }

  // Metodo per aggiornare lo stato del like di un video
  Future<void> updateLikeStatus(String videoId, bool isLiked) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final likedVideos = userData['LikedVideos'] as List<dynamic>? ?? [];

        if (isLiked) {
          likedVideos.add(videoId);
        } else {
          likedVideos.remove(videoId);
        }

        await userDocRef.update({'LikedVideos': likedVideos});

        final videoDocRef = FirebaseFirestore.instance.collection('videos').doc(videoId);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final videoDoc = await transaction.get(videoDocRef);
          if (videoDoc.exists) {
            final videoData = videoDoc.data() as Map<String, dynamic>;
            final likes = videoData['likes'] as int? ?? 0;
            final newLikes = isLiked ? likes + 1 : likes - 1;
            transaction.update(videoDocRef, {'likes': newLikes});
          }
        });
      }
    }
  }

  // Metodo per ottenere il conteggio dei like di un video
  Future<int> getLikeCount(String videoId) async {
    if (videoId.isEmpty) {
      print('Errore: videoId è vuoto!');
      return 0;
    }

    try {
      final videoDoc = await FirebaseFirestore.instance.collection('videos').doc(videoId).get();
      if (videoDoc.exists) {
        final videoData = videoDoc.data() as Map<String, dynamic>;
        return videoData['likes'] as int? ?? 0;
      }
    } catch (e) {
      print('Errore durante il recupero del conteggio dei like: $e');
    }
    return 0;
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