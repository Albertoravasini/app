import 'package:Just_Learn/models/user.dart';
import 'package:Just_Learn/screens/section_selection_sheet.dart';
import 'package:Just_Learn/screens/topic_selection_sheet.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Just_Learn/models/course.dart';
import 'package:Just_Learn/controllers/course_video_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:Just_Learn/screens/profile_screen.dart';

class CourseInfoOverlay extends StatefulWidget {
  final Course? course;
  final bool isInCourse;
  final CourseVideoController controller;
  final Section? currentSection;
  final String topic;
  final Function(int) onCoinsUpdate;
  final String videoTitle;
  final Function(String)? onTopicChanged;
  final List<String> allTopics;
  final Function(bool) onShowArticles;
  final Function(bool) onShowNotes;
  final Function(bool) openComments;

  const CourseInfoOverlay({
    Key? key,
    this.course,
    required this.isInCourse,
    required this.controller,
    this.currentSection,
    required this.topic,
    required this.onCoinsUpdate,
    required this.videoTitle,
    this.onTopicChanged,
    this.allTopics = const [],
    required this.onShowArticles,
    required this.onShowNotes,
    required this.openComments,
  }) : super(key: key);

  @override
  _CourseInfoOverlayState createState() => _CourseInfoOverlayState();
}

class _CourseInfoOverlayState extends State<CourseInfoOverlay> {
  bool _showUnlockOptions = false;
  bool _isAnimating = false;

  Widget _buildPlaceholder(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: isLoading ? Colors.grey[300] : Colors.grey[400],
        borderRadius: BorderRadius.circular(21),
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : const Icon(Icons.person, color: Colors.white),
    );
  }

  Widget _buildStartCourseButton() {
    return Hero(
      tag: 'startCourse${widget.course!.id}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 38,
        decoration: BoxDecoration(
          color: _showUnlockOptions ? Colors.transparent : const Color(0xFFFFFF28),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showUnlockOptions ? null : _handleStartCourse,
            child: _showUnlockOptions
                ? _buildUnlockOptions()
                : _buildDefaultStartButton(),
          ),
        ),
      ),
    );
  }

  Widget _buildUnlockOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: Colors.yellowAccent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: _handleSubscribe,
              child: const Text(
                'Subscribe',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.yellowAccent.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: TextButton(
              onPressed: _handleUnlockCourse,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stars_rounded, color: Colors.yellowAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.course!.cost}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
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

  Widget _buildDefaultStartButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Padding(
          padding: EdgeInsets.only(left: 16),
          child: Text(
            'Start Course',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: 12),
          child: Icon(Icons.arrow_forward, color: Colors.black),
        ),
      ],
    );
  }

  void _handleStartCourse() {
    if (widget.course != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        widget.controller.hasSubscription(widget.course!.authorId).then((hasSubscription) {
          if (hasSubscription) {
            widget.controller.onStartCourse(widget.course, null);
          } else {
            FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get()
                .then((doc) {
              if (doc.exists) {
                final userData = UserModel.fromMap(doc.data()!);
                if (userData.unlockedCourses.contains(widget.course!.id)) {
                  widget.controller.onStartCourse(widget.course, null);
                } else {
                  Posthog().capture(
                    eventName: 'initial_subscribe_click',
                    properties: {
                      'course_id': widget.course!.id,
                      'course_title': widget.course!.title,
                      'author_id': widget.course!.authorId,
                      'author_name': widget.course!.authorName,
                      'video_title': widget.videoTitle,
                    },
                  );
                  setState(() {
                    _showUnlockOptions = true;
                  });
                }
              }
            });
          }
        });
      }
    }
  }

  Future<void> _handleSubscribe() async {
    print('DEBUG: Tentativo di mettere in pausa il video prima della navigazione');
    
    try {
      widget.controller.videoManager.pauseCurrentVideo();
      print('DEBUG: Video messo in pausa con successo');
    } catch (e) {
      print('ERROR: Errore durante la pausa del video: $e');
    }
    
    print('DEBUG: Recupero dati utente da Firestore');
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.course?.authorId)
        .get();

    if (!userDoc.exists || !mounted) {
      print('DEBUG: Documento utente non trovato o widget non mounted');
      return;
    }

    final author = UserModel.fromMap(userDoc.data()!);
    print('DEBUG: Navigazione verso ProfileScreen');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(currentUser: author),
      ),
    );
  }

  Future<void> _handleUnlockCourse() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await docRef.get();
      
      if (doc.exists) {
        final userData = UserModel.fromMap(doc.data()!);
        
        if (userData.coins >= widget.course!.cost) {
          Posthog().capture(
            eventName: 'unlock_with_coins_click',
            properties: {
              'course_id': widget.course!.id,
              'course_title': widget.course!.title,
              'author_id': widget.course!.authorId,
              'author_name': widget.course!.authorName,
              'video_title': widget.videoTitle,
              'unlock_option': 'coins',
              'coins_cost': widget.course!.cost,
              'user_coins_before': userData.coins,
            },
          );

          await docRef.update({
            'coins': userData.coins - widget.course!.cost,
            'unlockedCourses': [...userData.unlockedCourses, widget.course!.id],
          });

          widget.onCoinsUpdate(userData.coins - widget.course!.cost);
          widget.controller.onStartCourse(widget.course, null);
          
          setState(() {
            _showUnlockOptions = false;
            _isAnimating = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Non hai abbastanza coins')),
          );
        }
      }
    }
  }

  Future<void> _handleAuthorTap() async {
    print('DEBUG: Tentativo di mettere in pausa il video (tap autore)');
    
    try {
      widget.controller.videoManager.pauseCurrentVideo();
      print('DEBUG: Video messo in pausa con successo (tap autore)');
    } catch (e) {
      print('ERROR: Errore durante la pausa del video (tap autore): $e');
    }
    
    print('DEBUG: Recupero dati utente da Firestore (tap autore)');
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.course?.authorId)
        .get();

    if (!userDoc.exists || !mounted) {
      print('DEBUG: Documento utente non trovato o widget non mounted (tap autore)');
      return;
    }

    final author = UserModel.fromMap(userDoc.data()!);
    print('DEBUG: Navigazione verso ProfileScreen (tap autore)');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(currentUser: author),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Titolo e Topic/Section
        Positioned(
          left: 16,
          bottom: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 274,
                child: Text(
                  widget.videoTitle,
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.72,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (widget.isInCourse) {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => SectionSelectionSheet(
                            course: widget.course!,
                            currentSection: widget.currentSection,
                            onSelectSection: (selectedSection) {
                              widget.controller.onStartCourse(widget.course, selectedSection);
                            },
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Start a course first to select a section'),
                            duration: Duration(seconds: 2),
                            backgroundColor: Colors.white
                          ),
                        );
                      }
                    },
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 240),
                      height: 23,
                      decoration: ShapeDecoration(
                        color: const Color(0x93333333),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.isInCourse 
                                  ? widget.currentSection?.title ?? "Section 1"
                                  : widget.topic,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.72,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.isInCourse) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.controller.handleQuitCourse,
                      child: Container(
                        height: 23,
                        decoration: ShapeDecoration(
                          color: const Color(0x93333333),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 1,
                              color: Colors.yellowAccent.withOpacity(0.5),
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Quit',
                              style: TextStyle(
                                color: Colors.yellowAccent,
                                fontSize: 12,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.72,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Profilo autore e info corso
        Positioned(
          left: 16,
          bottom: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _handleAuthorTap(),
                child: Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      padding: const EdgeInsets.all(2),
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            width: 1.5,
                            color: Colors.yellowAccent,
                          ),
                          borderRadius: BorderRadius.circular(23),
                        ),
                      ),
                      child: widget.course?.authorId != null
                          ? StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(widget.course!.authorId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return _buildPlaceholder(true);
                                }

                                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                                if (userData == null) {
                                  return _buildPlaceholder(false);
                                }

                                final authorProfileUrl = userData['profileImageUrl'] as String?;
                                
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(21),
                                  child: Image.network(
                                    authorProfileUrl ?? 'https://via.placeholder.com/45',
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return _buildPlaceholder(true);
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildPlaceholder(false);
                                    },
                                  ),
                                );
                              },
                            )
                          : _buildPlaceholder(false),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.course?.authorName ?? 'Unknown Author',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              
              if (!widget.isInCourse) ...[
                const SizedBox(height: 12),
                Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x93333333).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(
                                  widget.course?.coverImageUrl ?? 'https://picsum.photos/47'
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.course?.title ?? 'Corso non disponibile',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildStartCourseButton(),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Bottoni overlay
        Positioned(
          bottom: 5,
          right: 15,
          child: Column(
            children: [
              GestureDetector(
                onTap: () => widget.onShowArticles(true),
                child: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/fluent_preview-link-24-filled.svg',
                      color: Colors.white70,
                      width: 30,
                      height: 30,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => widget.openComments(true),
                child: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/ri_chat-ai-line.svg',
                      color: Colors.white70,
                      width: 30,
                      height: 30,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => widget.onShowNotes(true),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/solar_pen-bold.png',
                      color: Colors.white70,
                      width: 30,
                      height: 30,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 