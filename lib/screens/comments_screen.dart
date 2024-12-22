import 'package:Just_Learn/models/user.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import '../services/comment_service.dart';
import '../services/ai_chat_service.dart';
import '../widgets/ai_chat_widget.dart';

class CommentsScreen extends StatefulWidget {
  final String videoId;

  const CommentsScreen({super.key, required this.videoId});

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final CommentService _commentService = CommentService();
  final AIChatService _aiChatService = AIChatService();
  bool _showAiChat = false; // Nuovo stato per gestire la visualizzazione

  String? _activeReplyCommentId; // Commento attualmente attivo per la risposta
  TextEditingController _replyController = TextEditingController(); // Controller per il campo di input della risposta

  // Mappa per tenere traccia dello stato di espansione delle risposte per ogni commento
  Map<String, bool> _showReplies = {};

  // Aggiungi una chiave globale per accedere allo stato del widget AI chat
  final GlobalKey<AIChatWidgetState> _aiChatKey = GlobalKey<AIChatWidgetState>();

  String? _replyingTo; // Nuovo: tiene traccia del commento a cui stiamo rispondendo
  String? _replyingToUsername; // Nuovo: tiene traccia dell'username

  @override
  void initState() {
    super.initState();
    // Usa screen() per la visualizzazione della schermata
    Posthog().screen(
      screenName: 'Comments Screen',
      properties: {
        'videoId': widget.videoId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> _addComment(String content) async {
    await _commentService.addComment(widget.videoId, content);
    // Usa capture() per l'azione di aggiungere un commento
    Posthog().capture(
      eventName: 'Comment Added',
      properties: {
        'videoId': widget.videoId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

        return Container(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: bottomPadding + 16.0,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linea estetica e pulsante AI
              Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.yellowAccent,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _showAiChat ? Icons.chat : Icons.smart_toy,
                      color: Colors.yellowAccent,
                    ),
                    onPressed: () {
                      setState(() {
                        _showAiChat = !_showAiChat;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 0),
              
              // Contenuto principale
              Expanded(
                child: _showAiChat 
                    ? AIChatWidget(
                        key: _aiChatKey,
                        videoId: widget.videoId,
                        levelId: 'default',
                        aiChatKey: _aiChatKey,
                      )
                    : StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _commentService.getCommentsWithUsernames(widget.videoId),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Center(
                              child: Text(
                                'Error loading comments',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          }
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator(color: Colors.yellowAccent));
                          }
                          final comments = snapshot.data!;
                          if (comments.isEmpty) {
                            return const Center(
                              child: Text(
                                'No comments found',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          }
                          return ListView.builder(
                            controller: scrollController,
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
              
              // Input field comune
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
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header più compatto
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: AssetImage('assets/images/default_avatar.png'),
                      backgroundColor: Colors.grey[800],
                    ),
                    const SizedBox(width: 8),
                    // Username e timestamp sulla stessa riga
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTimestamp(comment.timestamp),
                            style: const TextStyle(
                              color: Color(0xFFB3B3B3),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Menu opzioni più compatto
                    if (comment.userId == user?.uid)
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white70, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showDeleteDialog(comment.commentId),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // Testo del commento
                Text(
                  comment.content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                // Azioni più compatte
                Row(
                  children: [
                    // Reply text only
                    TextButton(
                      onPressed: () => _handleReply(comment.commentId, username),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Reply',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (hasReplies)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showReplies[comment.commentId] = !(_showReplies[comment.commentId] ?? false);
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          _showReplies[comment.commentId] ?? false
                              ? 'Hide replies'
                              : 'Show replies',
                          style: const TextStyle(
                            color: Colors.yellowAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                // Risposte con padding ridotto
                if (_showReplies[comment.commentId] ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, left: 32.0),
                    child: Column(
                      children: comment.replies
                          .map((reply) => _buildReplyTile(reply, comment.commentId))
                          .toList(),
                    ),
                  ),
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
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          margin: const EdgeInsets.only(top: 4.0, bottom: 4.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14, // Ancora più piccolo per le risposte
                    backgroundColor: Colors.grey[800],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          reply.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTimestamp(reply.timestamp),
                          style: const TextStyle(
                            color: Color(0xFFB3B3B3),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (reply.userId == user?.uid)
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white70, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showDeleteDialog(reply.commentId, isReply: true),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                reply.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _handleReply(parentCommentId, reply.username),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Reply',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mostra l'indicatore di risposta
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Replying to @$_replyingToUsername',
                    style: const TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _replyingTo = null;
                        _replyingToUsername = null;
                        _commentController.clear();
                      });
                    },
                    child: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: _replyingTo != null ? 'Write a reply...' : 'Add a comment...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                color: Colors.yellowAccent,
                onPressed: () async {
                  final message = _commentController.text.trim();
                  if (message.isEmpty) return;

                  if (_replyingTo != null) {
                    // Aggiungi la menzione dell'utente all'inizio della risposta
                    final replyWithMention = '@$_replyingToUsername $message';
                    await _commentService.addReply(_replyingTo!, replyWithMention);
                    setState(() {
                      _replyingTo = null;
                      _replyingToUsername = null;
                    });
                  } else {
                    await _addComment(message);
                  }
                  _commentController.clear();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String commentId, {bool isReply = false}) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: _dialogContent(context, commentId, isReply),
        );
      },
    );
  }

  Widget _dialogContent(BuildContext context, String commentId, bool isReply) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isReply ? 'Delete Reply' : 'Delete Comment',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isReply
                ? 'Are you sure you want to delete this reply?'
                : 'Are you sure you want to delete this comment?',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3A3A3A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (isReply) {
                      _deleteReply(commentId);
                    } else {
                      _deleteComment(commentId);
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellowAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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
          // Trova la risposta specifica da eliminare
          final replyToRemove = (parentComment['replies'] as List<dynamic>).firstWhere(
            (reply) => reply['commentId'] == replyId,
            orElse: () => null,
          );

          if (replyToRemove != null) {
            // Rimuovi la risposta specifica dalla lista delle risposte
            await parentComment.reference.update({
              'replies': FieldValue.arrayRemove([replyToRemove]),
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reply successfully deleted'),
                backgroundColor: Colors.yellowAccent,
              ),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error deleting reply'),
            backgroundColor: Colors.redAccent,
          ),
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
          const SnackBar(
            content: Text('Comment successfully deleted'),
            backgroundColor: Colors.yellowAccent,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error deleting comment'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final Duration difference = DateTime.now().difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      final int weeks = (difference.inDays / 7).floor();
      return '$weeks weeks ago';
    }
  }

  // Modifica la funzione che gestisce il tap sul pulsante reply
  void _handleReply(String commentId, String username) {
    setState(() {
      _replyingTo = commentId;
      _replyingToUsername = username;
      FocusScope.of(context).requestFocus(FocusNode()); // Apre la tastiera
    });
  }
}