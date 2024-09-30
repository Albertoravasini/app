import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Just_Learn/models/user.dart';
import '../models/level.dart';

class ShortsController {
  // Metodo per segnare un video come visto
  Future<void> markVideoAsWatched(String videoId, String title, String topic) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      final userModel = UserModel.fromMap(userData);

      // Se il video non è già segnato come visto nel topic corrente
      userModel.WatchedVideos[topic] ??= [];
      final alreadyWatched = userModel.WatchedVideos[topic]!.any((video) => video.videoId == videoId);

      if (!alreadyWatched) {
        // Aggiungi il video visto
        userModel.WatchedVideos[topic]!.add(VideoWatched(
          videoId: videoId,
          title: title,
          watchedAt: DateTime.now(),
        ));

        // Aggiorna l'utente nel database
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update(userModel.toMap());
      }
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

  // Metodo per caricare tutti i video brevi (shorts) con paginazione
  Future<List<Map<String, dynamic>>> loadAllShortSteps({
    required String? selectedTopic,
    required String? selectedSubtopic,
    required bool showSavedVideos,
    required int limit,
    required int offset,
  }) async {
    final levelsCollection = FirebaseFirestore.instance.collection('levels');
    Query query = levelsCollection;

    // Filtra per topic selezionato
    if (selectedTopic != null && selectedTopic != 'Just Learn') {
      query = query.where('topic', isEqualTo: selectedTopic);
    }

    // Filtra per subtopic selezionato
    if (selectedSubtopic != null && selectedSubtopic != 'tutti') {
      query = query.where('subtopic', isEqualTo: selectedSubtopic);
    }

    // Ordina i livelli per ordine di subtopic e numero di livello, e imposta il limite per la paginazione
    query = query.orderBy('subtopicOrder').orderBy('levelNumber').limit(limit);

    // Applica la paginazione con il documento di partenza
    if (offset > 0) {
      final lastDocument = await _getDocumentAfter(offset);
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
    }

    final querySnapshot = await query.get();
    final levels = querySnapshot.docs.map((doc) => Level.fromFirestore(doc)).toList();

    List<LevelStep> shortSteps = levels
        .expand((level) => level.steps.where((step) => step.type == 'video' && step.isShort))
        .toList();

    final user = FirebaseAuth.instance.currentUser;
    List<VideoWatched> allWatchedVideos = [];
    List<dynamic> savedVideos = [];
    Map<String, int> likeCounts = {}; // Mappa per i conteggi dei like

    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;

        // Carica i video salvati
        savedVideos = userData['SavedVideos'] ?? [];

        if (showSavedVideos) {
          // Mostra solo i video salvati
          final savedVideoIds = savedVideos.map((video) => video['videoId']).toSet();
          shortSteps = shortSteps.where((step) => savedVideoIds.contains(step.content)).toList();
        } else {
          final userModel = UserModel.fromMap(userData);

          if (selectedTopic == 'Just Learn') {
            for (var watchedVideosByTopic in userModel.WatchedVideos.values) {
              allWatchedVideos.addAll(watchedVideosByTopic);
            }
          } else {
            allWatchedVideos = userModel.WatchedVideos[selectedTopic] ?? [];
          }

          final watchedVideoIds = allWatchedVideos.map((video) => video.videoId).toSet();
          final unWatchedSteps = shortSteps.where((step) => !watchedVideoIds.contains(step.content)).toList();
          final watchedSteps = shortSteps.where((step) => watchedVideoIds.contains(step.content)).toList();

          // Popola la mappa dei conteggi di like
          for (var step in shortSteps) {
            final likeCount = await getLikeCount(step.content);
            likeCounts[step.content] = likeCount;
          }

          // Ordina i video non visti per numero di like in modo decrescente
          unWatchedSteps.sort((a, b) {
            final likeCountA = likeCounts[a.content] ?? 0;
            final likeCountB = likeCounts[b.content] ?? 0;
            return likeCountB.compareTo(likeCountA);
          });

          // Ordina i video già visti per numero di like in modo decrescente e poi mescola casualmente
          watchedSteps.sort((a, b) {
            final likeCountA = likeCounts[a.content] ?? 0;
            final likeCountB = likeCounts[b.content] ?? 0;
            return likeCountB.compareTo(likeCountA);
          });
          watchedSteps.shuffle();

          shortSteps = [...unWatchedSteps, ...watchedSteps];
        }
      }
    }

    final shortStepsWithLevel = shortSteps.map((step) {
      final level = levels.firstWhere((l) => l.steps.contains(step));
      return {
        'step': step,
        'level': level,
        'showQuestion': false,
      };
    }).toList();

    return shortStepsWithLevel;
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