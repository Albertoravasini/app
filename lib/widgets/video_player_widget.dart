import 'package:Just_Learn/screens/comments_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/comment_service.dart';

class VideoPlayerWidget extends StatefulWidget {
  final YoutubePlayerController controller;
  final bool isLiked; // Add back the isLiked parameter
  final int likeCount; // Add back the likeCount parameter

  const VideoPlayerWidget({
    super.key,
    required this.controller,
    this.isLiked = false, // Provide a default value if necessary
    this.likeCount = 0, // Provide a default value if necessary
  });

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  bool isLiked = false;
  int likeCount = 0;
  int commentCount = 0; // Variable to store the comment count
  final CommentService _commentService = CommentService(); // Initialize CommentService

   @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateState);
    // Imposta i valori iniziali con quelli passati dal genitore
    setState(() {
      isLiked = widget.isLiked;
      likeCount = widget.likeCount;
    });
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller.metadata.videoId != oldWidget.controller.metadata.videoId ||
        widget.likeCount != oldWidget.likeCount ||
        widget.isLiked != oldWidget.isLiked) {
      setState(() {
        isLiked = widget.isLiked;
        likeCount = widget.likeCount;
      });
    }
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateState);
    super.dispose();
  }

  // Function to fetch the current like status and count from Firestore
  Future<void> _fetchLikeStatusAndCount() async {
    final videoId = widget.controller.metadata.videoId;
    if (videoId.isNotEmpty) { // Ensure videoId is not empty
      try {
        final videoDoc = await FirebaseFirestore.instance.collection('videos').doc(videoId).get();

        if (videoDoc.exists) {
          final videoData = videoDoc.data();
          if (videoData != null) {
            setState(() {
              likeCount = videoData['likes'] ?? 0; // Set the like count
            });
          }
        }

        // Check the like status for the current user
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final likedVideos = userData['LikedVideos'] as List<dynamic>? ?? [];
            setState(() {
              isLiked = likedVideos.contains(videoId); // Update isLiked status
            });
          }
        }
      } catch (e) {
        print('Error fetching like status and count: $e');
      }
    } else {
      print("Error: Video ID is empty"); // Debug message
    }
  }


  // Function to update like status
  Future<void> _toggleLike() async {
    final videoId = widget.controller.metadata.videoId;
    final user = FirebaseAuth.instance.currentUser;

    if (videoId.isNotEmpty && user != null) { // Ensure videoId is not empty
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
            // If video document doesn't exist, create it with the initial count
            transaction.set(videoDocRef, {'likes': isLiked ? 1 : 0});
          }
        });
      }
    } else {
      print("Error: Video ID is empty or user is not logged in"); // Debug message
    }
  }

  // Function to open comments
  void _openComments(BuildContext context) {
    final videoId = widget.controller.metadata.videoId;
    if (videoId.isNotEmpty) { // Ensure videoId is not empty before using it
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
        builder: (context) => CommentsScreen(videoId: videoId), // Pass the video id
      );
    } else {
      print("Error: Video ID is empty"); // Debug message
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoId = widget.controller.metadata.videoId;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(7.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  IgnorePointer(
                    ignoring: true,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: MediaQuery.of(context).size.height * 0.8,
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
                  // Like and comment buttons
                  Positioned(
                    bottom: 5,
                    right: 5,
                    child: Column(
                      children: [
                        // Like button
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
                        const SizedBox(height: 10), // Space between like and comments
                        // Comment button
                        GestureDetector(
                          onTap: () => _openComments(context), // Open comments
                          child: Column(
                            children: [
                              SvgPicture.asset('assets/comment_icon.svg', // Your SVG icon path
            color: Colors.white, // Icon color
            width: 25, // SVG icon size
            height: 30,
          ),
                              StreamBuilder<int>(
                                stream: _commentService.getCommentCount(videoId),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    final newCommentCount = snapshot.data!;
                                    // Check if the count is different to avoid unnecessary rendering
                                    if (commentCount != newCommentCount) {
                                      commentCount = newCommentCount;
                                    }
                                  }
                                  // Show the comment count or 0 if no data
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      '$commentCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
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
  }
}