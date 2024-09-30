import 'package:Just_Learn/models/user.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/comment_service.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

class CommentsScreen extends StatefulWidget {
  final String videoId;

  const CommentsScreen({super.key, required this.videoId});

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final CommentService _commentService = CommentService();

  String? _activeReplyCommentId; // Commento attualmente attivo per la risposta
  TextEditingController _replyController = TextEditingController(); // Controller per il campo di input della risposta
  
  // Mappa per tenere traccia dello stato di espansione delle risposte per ogni commento
  Map<String, bool> _showReplies = {}; 


  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26.0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _commentService.getCommentsWithUsernames(widget.videoId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('Errore nel caricamento dei commenti'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final comments = snapshot.data!;
                    if (comments.isEmpty) {
                      return const Center(child: Text('Nessun commento trovato'));
                    }
                    return ListView.builder(
  itemCount: comments.length,
  itemBuilder: (context, index) {
    final commentData = comments[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommentTile(
          commentData['comment'],
          commentData['username'],
        ),
      ],
    );
  },
);
                  },
                ),
              ),
              _buildCommentInput(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentTile(Comment comment, String username) {
  final user = FirebaseAuth.instance.currentUser;
  return FutureBuilder<bool>(
    future: _commentService.isCommentLiked(comment.commentId),
    builder: (context, snapshot) {
      final isLiked = snapshot.data ?? false;
      final hasReplies = comment.replies.isNotEmpty;

      return GestureDetector(
        onLongPress: () {
          if (comment.userId == user?.uid) {
            _showDeleteDialog(comment.commentId);
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8.0),
          margin: const EdgeInsets.symmetric(vertical: 10.0),
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: const BorderSide(width: 1, color: Color(0xFFEFEFEF)),
              borderRadius: BorderRadius.circular(16),
            ),
            shadows: const [
              BoxShadow(
                color: Color(0x3F000000),
                blurRadius: 4,
                offset: Offset(0, 4),
                spreadRadius: 0,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                username,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                  letterSpacing: 0.42,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTimestamp(comment.timestamp),
                              style: const TextStyle(
                                color: Color(0xFF9E9E9E),
                                fontSize: 10,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 60),
                          child: SingleChildScrollView(
                            child: Text(
                              comment.content.length > 150
                                  ? '${comment.content.substring(0, 147)}...'
                                  : comment.content,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                                letterSpacing: 0.36,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              // Se si clicca su "Rispondi" per un commento già attivo, chiudilo
                              _activeReplyCommentId = _activeReplyCommentId == comment.commentId
                                  ? null
                                  : comment.commentId;
                              _replyController.clear(); // Resetta il controller per una nuova risposta
                            });
                          },
                          child: const Text(
                            'Reply',
                            style: TextStyle(
                              color: Color(0xFF9E9E9E),
                              fontSize: 10,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        if (hasReplies)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                // Inverte lo stato di visualizzazione delle risposte
                                _showReplies[comment.commentId] = !(_showReplies[comment.commentId] ?? false);
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _showReplies[comment.commentId] ?? false
                                    ? 'Nascondi risposte'
                                    : 'Visualizza altre risposte',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 13),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          if (isLiked) {
                            await _commentService.unlikeComment(comment.commentId);
                          } else {
                            await _commentService.likeComment(comment.commentId);
                          }
                          setState(() {}); // Ricarica il widget per riflettere il nuovo stato
                        },
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return ScaleTransition(scale: animation, child: child);
                          },
                          child: isLiked
                              ? const Icon(
                                  Icons.favorite,
                                  key: ValueKey<int>(1),
                                  color: Colors.red,
                                  size: 24,
                                )
                              : const Icon(
                                  Icons.favorite_border,
                                  key: ValueKey<int>(2),
                                  color: Colors.grey,
                                  size: 24,
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${comment.likeCount}', // Mostra il numero di like del commento
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Mostra le risposte solo se l'utente ha cliccato su "Visualizza altre risposte"
              if (_showReplies[comment.commentId] ?? false)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 20.0),
                  child: Column(
                    children: comment.replies.map((reply) => _buildReplyTile(reply, comment.commentId)).toList(),
                  ),
                ),
              if (_activeReplyCommentId == comment.commentId)
                _buildReplyInput(comment.commentId, username), // Passa il nome utente qui
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildReplyTile(Comment reply, String parentCommentId) {
  final user = FirebaseAuth.instance.currentUser;
  return FutureBuilder<bool>(
    future: _commentService.isCommentLiked(reply.commentId),
    builder: (context, snapshot) {
      final isLiked = snapshot.data ?? false;
      return GestureDetector(
        onLongPress: () {
          if (reply.userId == user?.uid) {
            _showDeleteDialog(reply.commentId, isReply: true); // Passiamo true per identificare che è una risposta
          }
        },
        child: Container(
          margin: const EdgeInsets.only(top: 4.0),
          padding: const EdgeInsets.all(8.0),
          decoration: ShapeDecoration(
            color: const Color(0xFFF0F0F0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    reply.username, // Nome utente
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                                        onTap: () async {
                      if (isLiked) {
                        await _commentService.unlikeComment(reply.commentId);
                      } else {
                        await _commentService.likeComment(reply.commentId);
                      }
                      setState(() {}); // Ricarica lo stato
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: isLiked
                          ? const Icon(
                              Icons.favorite,
                              key: ValueKey<int>(1),
                              color: Colors.red,
                              size: 16,
                            )
                          : const Icon(
                              Icons.favorite_border,
                              key: ValueKey<int>(2),
                              color: Colors.grey,
                              size: 16,
                            ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${reply.likeCount}', // Mostra il numero di like della risposta
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                reply.content,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(reply.timestamp),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  setState(() {
                    // Se si clicca su "Rispondi" per una risposta già attiva, chiudilo
                    _activeReplyCommentId = _activeReplyCommentId == reply.commentId
                        ? null
                        : reply.commentId;
                    _replyController.clear(); // Resetta il controller per una nuova risposta
                  });
                },
                child: const Text(
                  'Rispondi',
                  style: TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 10,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (_activeReplyCommentId == reply.commentId)
                _buildReplyInput(parentCommentId, reply.username), // Aggiunta dell'input di risposta sotto la risposta stessa
            ],
          ),
        ),
      );
    },
  );
}

void _showDeleteDialog(String commentId, {bool isReply = false}) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: _dialogContent(context, commentId, isReply),
      );
    },
  );
}

Widget _dialogContent(BuildContext context, String commentId, bool isReply) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Delete Comment',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Chiude il dialogo
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (isReply) {
                    _deleteReply(commentId); // Elimina la risposta
                  } else {
                    _deleteComment(commentId); // Elimina il commento principale
                  }
                  Navigator.pop(context); // Chiude il dialogo dopo l'eliminazione
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Future<void> _deleteReply(String replyId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      print('Trying to delete reply with ID: $replyId');

      // Recupera tutti i commenti che potrebbero contenere la risposta
      final querySnapshot = await FirebaseFirestore.instance
          .collection('comments')
          .get();

      // Trova il commento padre che contiene la risposta specifica
      QueryDocumentSnapshot<Map<String, dynamic>>? parentComment;

      for (var doc in querySnapshot.docs) {
        final replies = doc.data().containsKey('replies') 
            ? doc['replies'] as List<dynamic> 
            : [];
        if (replies.any((reply) => reply['commentId'] == replyId)) {
          parentComment = doc;
          break;
        }
      }

      if (parentComment != null) {
        print('Found parent comment with ID: ${parentComment.id}');

        // Trova la risposta specifica da eliminare
        final replyToRemove = (parentComment['replies'] as List<dynamic>).firstWhere(
          (reply) => reply['commentId'] == replyId,
          orElse: () => null,  // Usa null come fallback
        );

        if (replyToRemove != null) {
          print('Reply to remove: $replyToRemove');

          // Rimuovi la risposta specifica dalla lista delle risposte
          await parentComment.reference.update({
            'replies': FieldValue.arrayRemove([replyToRemove]),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Risposta eliminata con successo')),
          );
        } else {
          print('No matching reply found in parent comment');
        }
      } else {
        print('No parent comment found for this reply');
      }
    } catch (e) {
      print('Errore durante l\'eliminazione della risposta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore durante l\'eliminazione della risposta')),
      );
    }
  }
}
Future<void> _deleteComment(String commentId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      // Elimina il commento dal database di Firestore
      await FirebaseFirestore.instance.collection('comments').doc(commentId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commento eliminato con successo')),
      );
    } catch (e) {
      print('Errore durante l\'eliminazione del commento: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore durante l\'eliminazione del commento')),
      );
    }
  }
}


  Widget _buildReplyInput(String parentCommentId, String username) {
  return Padding(
    padding: const EdgeInsets.only(top: 8.0, left: 20.0, right: 20.0),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _replyController,
            style: const TextStyle(color: Colors.black), // Imposta il testo a nero
            decoration: InputDecoration(
              hintText: 'Reply to @${username}...',
              hintStyle: const TextStyle(color: Colors.grey),
              border: InputBorder.none,
            ),
            onTap: () {
              // Imposta il testo iniziale con il tag del nome utente se il campo è vuoto
              if (_replyController.text.isEmpty) {
                _replyController.text = '@${username} ';
                _replyController.selection = TextSelection.fromPosition(TextPosition(offset: _replyController.text.length));
              }
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send, color: Colors.black),
          onPressed: () async {
            if (_replyController.text.isNotEmpty) {
              await _commentService.addReply(parentCommentId, _replyController.text);
              setState(() {
                _activeReplyCommentId = null; // Chiudi il campo di risposta dopo l'invio
              });
              _replyController.clear(); // Pulisci il campo di input
            }
          },
        ),
      ],
    ),
  );
}

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, -2),
          ),
        ],
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.black), // Imposta il testo a nero
              decoration: const InputDecoration(
                hintText: 'Aggiungi un commento...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.black),
            onPressed: () async {
              if (_commentController.text.isNotEmpty) {
                await _commentService.addComment(widget.videoId, _commentController.text);
                _commentController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
  String _formatTimestamp(DateTime timestamp) {
    final Duration difference = DateTime.now().difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} secondi fa';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minuti fa';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ore fa';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} giorni fa';
    } else {
      final int weeks = (difference.inDays / 7).floor();
      return '$weeks settimane fa';
    }
  }
}