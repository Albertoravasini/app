import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../services/notification_service.dart';

class CommentService {
  final CollectionReference commentCollection =
      FirebaseFirestore.instance.collection('comments');

  // Aggiungi una risposta a un commento
  Future<void> addReply(String parentCommentId, String content) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // 1. Get replying user data
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final username = userDoc.data()?['name'] ?? 'Anonymous';

        // 2. Get parent comment
        final commentDoc = await commentCollection.doc(parentCommentId).get();
        final parentComment = commentDoc.data() as Map<String, dynamic>;
        
        // Controlla se stiamo rispondendo a una risposta esistente
        String? replyToUserId;
        if (content.startsWith('@')) {
          // Estrai il nome utente menzionato
          final mentionedUsername = content.split(' ')[0].substring(1);
          
          // Cerca tra le risposte esistenti
          final replies = List<Map<String, dynamic>>.from(parentComment['replies'] ?? []);
          final replyTo = replies.firstWhere(
            (reply) => reply['username'] == mentionedUsername,
            orElse: () => {},
          );
          
          // Se troviamo la risposta, usa l'ID dell'utente di quella risposta
          if (replyTo.isNotEmpty) {
            replyToUserId = replyTo['userId'];
          }
        }

        // 3. Create reply
        final reply = Comment(
          commentId: commentCollection.doc().id,
          userId: user.uid,
          username: username,
          videoId: parentComment['videoId'],
          content: content,
          timestamp: DateTime.now(),
        );

        // 4. Add notification
        final notificationUserId = replyToUserId ?? parentComment['userId'];
        if (notificationUserId != user.uid) { // Non inviare notifica a se stessi
          final notification = {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'message': content,
            'timestamp': DateTime.now().toIso8601String(),
            'isRead': false,
            'videoId': parentComment['videoId'],
            'senderId': user.uid,
            'type': 'commentReply'
          };

          await FirebaseFirestore.instance
              .collection('users')
              .doc(notificationUserId)
              .update({
            'notifications': FieldValue.arrayUnion([notification])
          });

          // Send push notification
          final recipientDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(notificationUserId)
              .get();
          
          if (recipientDoc.exists) {
            final fcmToken = recipientDoc.data()?['fcmToken'];
            if (fcmToken != null) {
              final notificationService = NotificationService();
              await notificationService.sendSpecificNotification(
                fcmToken, 
                'comment_reply',
                username
              );
            }
          }
        }

        // 5. Update comment with reply
        await commentCollection.doc(parentCommentId).update({
          'replies': FieldValue.arrayUnion([reply.toMap()])
        });

      } catch (e) {
        print('Error adding reply: $e');
        rethrow;
      }
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

  // Elimina un commento e tutte le sue risposte
  Future<void> deleteComment(String commentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // 1. Ottieni il commento prima di eliminarlo per avere accesso alle risposte
        final commentDoc = await commentCollection.doc(commentId).get();
        if (!commentDoc.exists) return;

        final commentData = commentDoc.data() as Map<String, dynamic>;
        final replies = List<Map<String, dynamic>>.from(commentData['replies'] ?? []);

        // 2. Elimina il commento principale
        await commentCollection.doc(commentId).delete();

        // 3. Opzionalmente, puoi anche rimuovere le notifiche correlate a questo commento
        // e alle sue risposte da tutti gli utenti coinvolti
        final uniqueUserIds = <String>{
          commentData['userId'], // Autore del commento principale
          ...replies.map((reply) => reply['userId'] as String), // Autori delle risposte
        };

        // 4. Rimuovi le notifiche per tutti gli utenti coinvolti
        for (final userId in uniqueUserIds) {
          final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
          final userDoc = await userRef.get();
          if (userDoc.exists) {
            final notifications = List<dynamic>.from(userDoc.data()?['notifications'] ?? []);
            
            // Rimuovi le notifiche relative a questo commento
            notifications.removeWhere((notification) => 
              notification['videoId'] == commentData['videoId'] && 
              (notification['message'] == commentData['content'] || 
               replies.any((reply) => reply['content'] == notification['message']))
            );

            await userRef.update({'notifications': notifications});
          }
        }

      } catch (e) {
        print('Errore durante l\'eliminazione del commento e delle risposte: $e');
        rethrow;
      }
    }
  }
}