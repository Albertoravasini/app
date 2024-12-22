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
        final parentUserId = parentComment['userId'] as String;

        // 3. Create reply
        final reply = Comment(
          commentId: commentCollection.doc().id,
          userId: user.uid,
          username: username,
          videoId: parentComment['videoId'],
          content: content,
          timestamp: DateTime.now(),
        );

        // 4. Add notification for original comment user
        if (parentUserId != user.uid) { // Don't send notification if user replies to their own comment
          final notification = {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'message': '@$username replied to your comment',
            'timestamp': DateTime.now().toIso8601String(),
            'isRead': false,
            'videoId': parentComment['videoId'],
            'senderId': user.uid,
            'type': 'commentReply'
          };

          await FirebaseFirestore.instance
              .collection('users')
              .doc(parentUserId)
              .update({
            'notifications': FieldValue.arrayUnion([notification])
          });
        }

        // 5. Update comment with reply
        await commentCollection.doc(parentCommentId).update({
          'replies': FieldValue.arrayUnion([reply.toMap()])
        });

        // Send push notification to original comment author
        final parentUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(parentUserId)
            .get();
        
        if (parentUserDoc.exists) {
          final fcmToken = parentUserDoc.data()?['fcmToken'];
          if (fcmToken != null) {
            final notificationService = NotificationService();
            await notificationService.sendSpecificNotification(
              fcmToken, 
              'comment_reply',
              username
            );
          }
        }
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