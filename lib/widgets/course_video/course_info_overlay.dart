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
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:Just_Learn/utils/platform_helper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CourseInfoOverlay extends StatefulWidget {
  final Course? course;
  final bool isInCourse;
  final CourseVideoController controller;
  final Section? currentSection;
  final String topic;
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

class _CourseInfoOverlayState extends State<CourseInfoOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _buttonController;
  late Animation<double> _scaleAnimation;
  bool _showUnlockOptions = false;
  bool _isAnimating = false;

  final List<Map<String, IconData>> _availableIcons = [
    {'link': FontAwesomeIcons.link},
    {'book': FontAwesomeIcons.book},
    {'video': FontAwesomeIcons.video},
    {'file': FontAwesomeIcons.file},
    {'github': FontAwesomeIcons.github},
    {'youtube': FontAwesomeIcons.youtube},
    {'article': FontAwesomeIcons.newspaper},
    {'code': FontAwesomeIcons.code},
    {'download': FontAwesomeIcons.download},
    {'web': FontAwesomeIcons.globe},
  ];

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    super.dispose();
  }

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
    return FutureBuilder<bool>(
      future: _isCourseStarted(),
      builder: (context, snapshot) {
        final bool isStarted = snapshot.data ?? false;
        
        return Hero(
          tag: 'startCourse${widget.course!.id}',
          child: GestureDetector(
            onTapDown: (_) => _buttonController.forward(),
            onTapUp: (_) {
              _buttonController.reverse();
              if (!_showUnlockOptions) _handleStartCourse();
            },
            onTapCancel: () => _buttonController.reverse(),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 38,
                decoration: BoxDecoration(
                  color: _showUnlockOptions 
                    ? Colors.transparent 
                    : isStarted 
                      ? const Color(0xFFFFFF28).withOpacity(0.15)
                      : const Color(0xFFFFFF28),
                  borderRadius: BorderRadius.circular(8),
                  border: isStarted 
                    ? Border.all(
                        color: const Color(0xFFFFFF28),
                        width: 2,
                      ) 
                    : null,
                ),
                child: _showUnlockOptions
                  ? _buildUnlockOptions()
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isStarted ? 'Continue' : 'Start Course',
                            style: TextStyle(
                              color: isStarted ? const Color(0xFFFFFF28) : Colors.black,
                              fontSize: 14,
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: isStarted ? const Color(0xFFFFFF28) : Colors.black,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildUnlockOptions() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.purpleAccent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextButton(
        onPressed: _handleSubscribe,
        child: const Text(
          'Subscribe to Access',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<bool> _isCourseStarted() async {
    if (widget.course == null) return false;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return false;

      final startedCourses = List<Map<String, dynamic>>.from(
        userDoc.data()?['startedCourses'] ?? []
      );

      return startedCourses.any((course) => course['courseId'] == widget.course!.id);
    } catch (e) {
      print('Error checking if course is started: $e');
      return false;
    }
  }

  void _handleStartCourse() async {
    if (widget.course != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final hasSubscription = await widget.controller.hasSubscription(widget.course!.authorId);
          
          if (widget.course!.isSubscriptionRequired && !hasSubscription) {
            setState(() {
              _showUnlockOptions = true;
            });
            return;
          }

          // Recupera i dati dell'utente
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
              
          if (!userDoc.exists) return;
          
          final userModel = UserModel.fromMap(userDoc.data()!);
          
          // Trova l'ultimo step completato
          int lastCompletedSectionIndex = 0;
          int lastCompletedStepIndex = 0;
          bool foundLastCompleted = false;

          // Itera attraverso le sezioni e gli step per trovare l'ultimo completato
          for (int sectionIndex = 0; sectionIndex < widget.course!.sections.length; sectionIndex++) {
            final section = widget.course!.sections[sectionIndex];
            
            for (int stepIndex = 0; stepIndex < section.steps.length; stepIndex++) {
              final step = section.steps[stepIndex];
              bool isCompleted = false;

              if (step.type == 'video') {
                // Controlla se il video è stato completato
                final videoId = step.videoUrl ?? step.content;
                isCompleted = userModel.WatchedVideos[widget.course!.topic]?.any(
                  (video) => video.videoId.contains(videoId) && video.completed
                ) ?? false;
              } else if (step.type == 'question') {
                // Controlla se la domanda è stata risposta
                isCompleted = userModel.answeredQuestions[widget.course!.topic]?.contains(step.content) ?? false;
              }

              if (isCompleted) {
                lastCompletedSectionIndex = sectionIndex;
                lastCompletedStepIndex = stepIndex + 1; // Punta al prossimo step
                foundLastCompleted = true;
              }
            }
          }

          // Registra il corso come iniziato se non lo è già
          final startedCourses = List<Map<String, dynamic>>.from(
            (userDoc.data()?['startedCourses'] ?? [])
          );

          if (!startedCourses.any((course) => course['courseId'] == widget.course!.id)) {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'startedCourses': FieldValue.arrayUnion([
                {
                  'courseId': widget.course!.id,
                  'startDate': Timestamp.now(),
                  'completed': false
                }
              ])
            });

            await widget.course!.enrollStudent(user.uid);
          }

          // Avvia il corso dall'ultimo punto completato o dall'inizio
          if (foundLastCompleted && 
              lastCompletedSectionIndex < widget.course!.sections.length &&
              lastCompletedStepIndex < widget.course!.sections[lastCompletedSectionIndex].steps.length) {
            widget.controller.onStartCourse(
              widget.course,
              widget.course!.sections[lastCompletedSectionIndex],
              initialStepIndex: lastCompletedStepIndex,
            );
          } else {
            // Se non ci sono step completati o siamo alla fine, parti dall'inizio
            widget.controller.onStartCourse(widget.course, null);
          }

          // Tracciamento analytics
          Posthog().capture(
            eventName: foundLastCompleted ? 'continue_course' : 'start_course',
            properties: {
              'course_id': widget.course!.id,
              'course_title': widget.course!.title,
              'author_id': widget.course!.authorId,
              'enrollment_date': DateTime.now().toIso8601String(),
            },
          );

        } catch (e) {
          print('Error starting course: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Errore nell\'avvio del corso. Riprova.'),
              backgroundColor: Colors.red,
            ),
          );
        }
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

  void _showResourceLinks() {
    print('DEBUG - Course: ${widget.course?.title}');
    print('DEBUG - Is in course: ${widget.isInCourse}');
    print('DEBUG - currentSection: ${widget.currentSection?.title}');
    print('DEBUG - currentSection links: ${widget.currentSection?.links}');
    print('DEBUG - currentSection links length: ${widget.currentSection?.links.length}');
    
    if (widget.currentSection == null || widget.currentSection!.links.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No resources available for this chapter'),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF282828),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.yellowAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.link,
                        color: Colors.yellowAccent,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Risorse Capitolo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.white12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: widget.currentSection!.links.length,
                  itemBuilder: (context, index) {
                    final link = widget.currentSection!.links[index];
                    return InkWell(
                      onTap: () async {
                        final url = Uri.parse(link.url);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            FaIcon(
                              _availableIcons.firstWhere(
                                (i) => i.containsKey(link.icon),
                                orElse: () => {'link': FontAwesomeIcons.link},
                              ).values.first,
                              color: Colors.yellowAccent,
                              size: 20,
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                link.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white24,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformHelper.isWeb) {
      return const SizedBox.shrink(); // Non mostrare nulla su web
    }

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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.72,
                    height: 1.2,
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
                            onSelectSection: (selectedSection, stepIndex) {
                              widget.controller.onStartCourse(
                                widget.course, 
                                selectedSection,
                                initialStepIndex: stepIndex,
                              );
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
                      padding: const EdgeInsets.symmetric(horizontal: 7),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.isInCourse 
                                        ? "Section ${widget.currentSection?.sectionNumber ?? 1}: ${widget.currentSection?.title ?? 'Section 1'}"
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
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 16,
                                ),
                              ],
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
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 16,
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
                onTap: _showResourceLinks,
                child: Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      child: Icon(
                        Icons.link_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    Text(
                      '${widget.currentSection?.links.length ?? 0}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            
              GestureDetector(
                onTap: () => widget.onShowArticles(true),
                child: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/fluent_preview-link-24-filled.svg',
                      color: Colors.white,
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
                      color: Colors.white,
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
                      color: Colors.white,
                      width: 27,
                      height: 27,
                    ),
                    const SizedBox(height: 57),
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