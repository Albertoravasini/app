import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';

class CommentService {
  final CollectionReference commentCollection =
      FirebaseFirestore.instance.collection('comments');

  // Aggiungi una risposta a un commento
  Future<void> addReply(String parentCommentId, String content) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final username = userDoc.data()?['name'] ?? 'Anonimo';

    final reply = Comment(
      commentId: commentCollection.doc().id,
      userId: user.uid,
      username: username,
      videoId: '', // Il videoId viene ereditato dal commento principale
      content: content,
      timestamp: DateTime.now(),
    );

    try {
      final commentDoc = await commentCollection.doc(parentCommentId).get();
      if (commentDoc.exists) {
        final parentComment = Comment.fromMap(commentDoc.data() as Map<String, dynamic>);
        String? mentionedUserId;
        String? mentionedUsername;

        // Verifica se ci sono menzioni nel contenuto
        final mentionRegex = RegExp(r'@(\w+)');
        final matches = mentionRegex.allMatches(content);

        if (matches.isNotEmpty) {
          // Recupera il primo nome utente menzionato
          final firstMention = matches.first;
          final mentionedUsernameInContent = firstMention.group(1);

          if (mentionedUsernameInContent != null) {
            // Cerca l'utente menzionato nel database
            final mentionedUserQuery = await FirebaseFirestore.instance
                .collection('users')
                .where('name', isEqualTo: mentionedUsernameInContent)
                .get();

            if (mentionedUserQuery.docs.isNotEmpty) {
              final mentionedUserDoc = mentionedUserQuery.docs.first;
              mentionedUserId = mentionedUserDoc.id;
              mentionedUsername = mentionedUserDoc['name'];
            }
          }
        }

        // Aggiungi la risposta al commento principale
        await commentDoc.reference.update({
          'replies': FieldValue.arrayUnion([reply.toMap()]),
        });

        // Determina i destinatari delle notifiche
        final List<String> recipientUserIds = [];
        if (mentionedUserId != null) {
          recipientUserIds.add(mentionedUserId); // Aggiungi utente menzionato
        }
        if (parentComment.userId != user.uid && !recipientUserIds.contains(parentComment.userId)) {
          recipientUserIds.add(parentComment.userId); // Aggiungi autore del commento, se diverso dall'autore della risposta
        }

        // Invia le notifiche a tutti i destinatari
        for (final recipientUserId in recipientUserIds) {
          final notification = Notification(
            id: FirebaseFirestore.instance.collection('notifications').doc().id,
            message: '$username ha risposto: "${content.length > 20 ? content.substring(0, 20) + '...' : content}"',
            timestamp: DateTime.now(),
            isRead: false,
            videoId: parentComment.videoId, // Associa la notifica al video
          );

          await FirebaseFirestore.instance
              .collection('users')
              .doc(recipientUserId)
              .update({
            'notifications': FieldValue.arrayUnion([notification.toMap()]),
          });
        }
      }
    } catch (e) {
      print('Errore durante l\'aggiunta della risposta: $e');
    }
  } else {
    print('Utente non autenticato, impossibile aggiungere risposte');
  }
}

  // Recupera tutti i commenti con i relativi nomi utente
  Stream<List<Map<String, dynamic>>> getCommentsWithUsernames(String videoId) async* {
    yield* commentCollection
        .where('videoId', isEqualTo: videoId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final List<Map<String, dynamic>> commentsWithUsernames = [];
          for (var doc in snapshot.docs) {
            final comment = Comment.fromMap(doc.data() as Map<String, dynamic>);
            final userDoc = await FirebaseFirestore.instance.collection('users').doc(comment.userId).get();
            final userData = userDoc.data();
            final username = userData != null ? userData['name'] as String : 'Unknown';
            commentsWithUsernames.add({
              'comment': comment,
              'username': username,
            });
          }
          return commentsWithUsernames;
        });
  }

  // Recupera il numero di commenti per un video
  Stream<int> getCommentCount(String videoId) {
    return commentCollection
        .where('videoId', isEqualTo: videoId)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  // Verifica se un commento è piaciuto dall'utente corrente
  Future<bool> isCommentLiked(String commentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final likedComments = userData['LikedComments'] as List<dynamic>? ?? [];
        return likedComments.contains(commentId);
      }
    }
    return false;
  }

  // Aggiunge un like a un commento
  Future<void> likeComment(String commentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final commentRef = commentCollection.doc(commentId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(commentRef);
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>?;
          final currentLikes = data?['likeCount'] ?? 0;
          transaction.update(commentRef, {'likeCount': currentLikes + 1});
        } else {
          transaction.set(commentRef, {'likeCount': 1});
        }
      });

      // Aggiungi il commento alla lista dei commenti piaciuti dell'utente
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userDocRef.update({
        'LikedComments': FieldValue.arrayUnion([commentId])
      });
    }
  }

  // Rimuove un like da un commento
  Future<void> unlikeComment(String commentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final commentRef = commentCollection.doc(commentId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(commentRef);
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>?;
          final currentLikes = data?['likeCount'] ?? 0;
          if (currentLikes > 0) {
            transaction.update(commentRef, {'likeCount': currentLikes - 1});
          }
        }
      });

      // Rimuovi il commento dalla lista dei commenti piaciuti dell'utente
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userDocRef.update({
        'LikedComments': FieldValue.arrayRemove([commentId])
      });
    }
  }

 // Aggiungi un commento a un video
  Future<void> addComment(String videoId, String content) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final username = userDoc.data()?['name'] ?? 'Anonimo';

      final comment = Comment(
        commentId: commentCollection.doc().id,
        userId: user.uid,
        username: username, // Usa il nome utente
        videoId: videoId,
        content: content,
        timestamp: DateTime.now(),
      );

      try {
        await commentCollection.doc(comment.commentId).set(comment.toMap());
      } catch (e) {
        print('Errore durante l\'aggiunta del commento: $e');
      }
    } else {
      print('Utente non autenticato, impossibile aggiungere commenti');
    }
  }

  // Elimina un commento
  Future<void> deleteComment(String commentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Elimina il commento dal database
        await commentCollection.doc(commentId).delete();
      } catch (e) {
        print('Errore durante l\'eliminazione del commento: $e');
      }
    }
  }
}