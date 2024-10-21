import 'package:Just_Learn/models/level.dart';
import 'package:Just_Learn/screens/comments_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/comment_service.dart';

class VideoPlayerWidget extends StatefulWidget {
  final YoutubePlayerController controller;
  final bool isLiked;
  final int likeCount;
  final LevelStep? questionStep; // La domanda associata al video
  final Function() onShowQuestion; // Callback per mostrare la domanda

  const VideoPlayerWidget({
    Key? key,
    required this.controller,
    this.isLiked = false,
    this.likeCount = 0,
    this.questionStep,
    required this.onShowQuestion,
  }) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with SingleTickerProviderStateMixin {
  bool isLiked = false;
  int likeCount = 0;
  int commentCount = 0;
  bool showQuestionIcon = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final CommentService _commentService = CommentService();

  @override
void initState() {
  super.initState();
  widget.controller.addListener(_videoListener);
  isLiked = widget.isLiked;
  likeCount = widget.likeCount;

  // Inizializza il conteggio dei commenti
  _fetchCommentsCount();

  // Inizializza l'AnimationController per l'icona della domanda
  _animationController = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );
  _scaleAnimation = CurvedAnimation(
    parent: _animationController,
    curve: Curves.linear,
  );
  if (widget.questionStep != null) {
    showQuestionIcon = true;
    _animationController.forward();
  }
}

// Funzione per ottenere il numero di commenti
Future<void> _fetchCommentsCount() async {
  final videoId = widget.controller.metadata.videoId;
  if (videoId.isNotEmpty) {
    final count = await _commentService.getCommentsCount(videoId);
    setState(() {
      commentCount = count;
    });
  }
}

  @override
  void dispose() {
    widget.controller.removeListener(_videoListener);
    _animationController.dispose();
    super.dispose();
  }

  void _videoListener() {
    if (mounted) {
      setState(() {
        // Non serve più tracciare il progresso o la fine del video
      });
    }
  }

  void _onQuestionIconTap() {
  // Reverse the scale animation for a quick shrinking effect before showing the question
  _animationController.reverse().then((_) {
    _animationController.forward();
    // Callback to show the question after the animation
    widget.onShowQuestion();
  });
}

  // Funzione per ottenere lo stato e il conteggio dei like da Firestore
  Future<void> _fetchLikeStatusAndCount() async {
    final videoId = widget.controller.metadata.videoId;
    if (videoId.isNotEmpty) {
      try {
        final videoDoc = await FirebaseFirestore.instance.collection('videos').doc(videoId).get();

        if (videoDoc.exists) {
          final videoData = videoDoc.data();
          if (videoData != null) {
            setState(() {
              likeCount = videoData['likes'] ?? 0; // Imposta il conteggio dei like
            });
          }
        }

        // Controlla lo stato del like per l'utente corrente
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final likedVideos = userData['LikedVideos'] as List<dynamic>? ?? [];
            setState(() {
              isLiked = likedVideos.contains(videoId); // Aggiorna lo stato di like
            });
          }
        }
      } catch (e) {
        print('Errore durante il recupero dello stato e del conteggio dei like: $e');
      }
    } else {
      print("Errore: ID video è vuoto"); // Messaggio di debug
    }
  }
  

  // Funzione per aggiornare lo stato del like
  Future<void> _toggleLike() async {
    final videoId = widget.controller.metadata.videoId;
    final user = FirebaseAuth.instance.currentUser;

    if (videoId.isNotEmpty && user != null) {
      setState(() {
        isLiked = !isLiked;
        likeCount += isLiked ? 1 : -1;
      });

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
          } else {
            // Se il documento del video non esiste, crealo con il conteggio iniziale
            transaction.set(videoDocRef, {'likes': isLiked ? 1 : 0});
          }
        });
      }
    } else {
      print("Errore: ID video è vuoto o l'utente non è loggato"); // Messaggio di debug
    }
  }

  // Funzione per aprire i commenti
  void _openComments(BuildContext context) {
    final videoId = widget.controller.metadata.videoId;
    if (videoId.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
        builder: (context) => CommentsScreen(videoId: videoId),
      );
    } else {
      print("Errore: ID video è vuoto"); // Messaggio di debug
    }
  }

  @override
Widget build(BuildContext context) {
  final videoId = widget.controller.metadata.videoId;

  return Column(
    children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Invisible layer for tapping (it won't interfere with the video controls)
                GestureDetector(
                  onTap: () {
                    if (widget.controller.value.isPlaying) {
                      widget.controller.pause();
                    } else {
                      widget.controller.play();
                    }
                  },
                  child: Container(
                    color: Colors.transparent,  // Invisible layer over the video
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                  ),
                ),
                // YoutubePlayer widget
                IgnorePointer(
                  ignoring: true,  // Ensures the user can tap without triggering the video player UI
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 1,
                    height: MediaQuery.of(context).size.height * 1,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        child: YoutubePlayer(
                          controller: widget.controller,
                          showVideoProgressIndicator: false,
                        ),
                      ),
                    ),
                  ),
                ),
                // Like, comment buttons and other overlays remain unchanged
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Column(
                    children: [
                      // Icona della domanda
                      if (showQuestionIcon && widget.questionStep != null)
                        GestureDetector(
                          onTap: _onQuestionIconTap,
                          child: AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _scaleAnimation.value,
                                child: SvgPicture.asset(
                                  'assets/ai_icon.svg',
                                  color: Colors.white,
                                  width: 25,
                                  height: 40,
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 20),
                      // Bottone like
                      GestureDetector(
                        onTap: _toggleLike,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return ScaleTransition(scale: animation, child: child);
                          },
                          child: isLiked
                              ? Icon(
                                  Icons.favorite,
                                  key: ValueKey<int>(1),
                                  color: Colors.red,
                                  size: 40,
                                )
                              : Icon(
                                  Icons.favorite_border,
                                  key: ValueKey<int>(2),
                                  color: Colors.white,
                                  size: 40,
                                ),
                        ),
                      ),
                      Text(
                        likeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Bottone commenti
                      GestureDetector(
                        onTap: () => _openComments(context),
                        child: Column(
                          children: [
                            SvgPicture.asset(
                              'assets/comment_icon.svg',
                              color: Colors.white,
                              width: 25,
                              height: 30,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                '$commentCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}}
class CommentService {
  // Metodo per ottenere il numero di commenti per un video
  Future<int> getCommentsCount(String videoId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('comments')
        .where('videoId', isEqualTo: videoId)
        .get();
    return querySnapshot.size;
  }
}