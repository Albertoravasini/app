import 'package:Just_Learn/admin_panel/course_management_screen.dart';
import 'package:Just_Learn/models/certification.dart';
import 'package:Just_Learn/models/experience.dart';
import 'package:Just_Learn/models/review.dart';
import 'package:Just_Learn/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import '../models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../services/image_service.dart';
import '../models/course.dart';
import '../widgets/profile_feed_tab.dart';
import '../controllers/follow_controller.dart';
import '../controllers/subscription_controller.dart';
import '../widgets/private_chat_tab.dart';
import '../controllers/profile_controller.dart';
import '../widgets/about_tab.dart';
import '../widgets/experience_manager.dart';
import '../widgets/certification_manager.dart';
import '../widgets/social_contacts_manager.dart';
import '../widgets/review_manager.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel currentUser;

  const ProfileScreen({super.key, required this.currentUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  bool isEditing = false;
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<Course> userCourses = [];
  bool isLoading = true;
  final FollowController _followController = FollowController();
  final SubscriptionController _subscriptionController = SubscriptionController();
  bool _isFollowing = false;
  bool _isSubscribed = false;
  final ProfileController _profileController = ProfileController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _nameController.text = widget.currentUser.name;
    _bioController.text = widget.currentUser.bio ?? 'No bio yet';
    _usernameController.text = widget.currentUser.username ?? 'username';
    _loadUserCourses();
    _checkFollowStatus();
    _checkSubscriptionStatus();
    
    // Traccia l'arrivo nella schermata profilo
    Posthog().screen(
      screenName: 'profile_screen',
      properties: {
        'profile_user_id': widget.currentUser.uid,
        'is_own_profile': widget.currentUser.uid == FirebaseAuth.instance.currentUser?.uid,
      },
    );

    // Ascolta i cambi di tab
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        String tabName = '';
        switch (_tabController.index) {
          case 0:
            tabName = 'feed';
            break;
          case 1:
            tabName = 'about';
            break;
          case 2:
            tabName = 'chat';
            break;
        }

        Posthog().capture(
          eventName: 'profile_tab_selected',
          properties: {
            'tab_name': tabName,
            'profile_user_id': widget.currentUser.uid,
          },
        );
      }
    });
  }

  Future<void> _loadUserCourses() async {
    try {
      final coursesSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('authorId', isEqualTo: widget.currentUser.uid)
          .get();

      if (mounted) {
        setState(() {
          userCourses = coursesSnapshot.docs
              .map((doc) => Course.fromFirestore(doc))
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Errore nel caricamento dei corsi: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _checkFollowStatus() async {
    if (FirebaseAuth.instance.currentUser?.uid != null) {
      final isFollowing = await _followController.isFollowing(
        followerId: FirebaseAuth.instance.currentUser!.uid,
        followedId: widget.currentUser.uid,
      );
      setState(() {
        _isFollowing = isFollowing;
      });
    }
  }

  Future<void> _checkSubscriptionStatus() async {
    if (FirebaseAuth.instance.currentUser?.uid != null) {
      final isSubscribed = await _subscriptionController.isSubscribed(
        subscriberId: FirebaseAuth.instance.currentUser!.uid,
        creatorId: widget.currentUser.uid,
      );
      setState(() {
        _isSubscribed = isSubscribed;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devi effettuare l\'accesso per seguire questo utente')),
      );
      return;
    }

    try {
      if (_isFollowing) {
        await _followController.unfollowUser(
          followerId: currentUser.uid,
          followedId: widget.currentUser.uid,
        );
      } else {
        await _followController.followUser(
          followerId: currentUser.uid,
          followedId: widget.currentUser.uid,
        );
      }
      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    }
  }

  Future<void> _toggleSubscription() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devi effettuare l\'accesso per iscriverti')),
      );
      return;
    }

    try {
      if (_isSubscribed) {
        await _subscriptionController.unsubscribe(
          subscriberId: currentUser.uid,
          creatorId: widget.currentUser.uid,
        );
      } else {
        await _subscriptionController.subscribe(
          subscriberId: currentUser.uid,
          creatorId: widget.currentUser.uid,
        );
      }
      setState(() {
        _isSubscribed = !_isSubscribed;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isSubscribed ? 'Iscrizione effettuata!' : 'Iscrizione annullata')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile(Map<String, dynamic> updates) async {
    try {
      await _profileController.updateProfile(
        userId: widget.currentUser.uid,
        updates: updates,
      );

      setState(() {
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profilo aggiornato con successo!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nell\'aggiornamento: $e')),
      );
    }
  }

  void _showSubscriptionModal(BuildContext context) {
    // Controllers per i benefici
    final benefitControllers = [
      TextEditingController(text: widget.currentUser.subscriptionDescription1),
      TextEditingController(text: widget.currentUser.subscriptionDescription2),
      TextEditingController(text: widget.currentUser.subscriptionDescription3),
    ];
    final priceController = TextEditingController(
      text: widget.currentUser.subscriptionPrice.toString()
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Immagine del profilo con bordo giallo
                    Stack(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(
                                widget.currentUser.profileImageUrl ?? 'https://via.placeholder.com/60',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.yellowAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF181819), width: 2),
                            ),
                            child: const Icon(
                              Icons.percent,
                              color: Colors.black,
                              size: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Just Learn',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '@${widget.currentUser.username ?? 'theunderdog'}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 2,
                  color: Colors.white.withOpacity(0.1),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Subscribe to this creator and unlock more benefits!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                // Lista dei benefici con icone
                ...List.generate(3, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Colors.yellowAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.black,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: isEditing
                              ? CustomTextField(
                                  controller: benefitControllers[index],
                                  label: 'Benefit ${index + 1}',
                                )
                              : Text(
                                  index == 0 ? widget.currentUser.subscriptionDescription1 :
                                  index == 1 ? widget.currentUser.subscriptionDescription2 :
                                  widget.currentUser.subscriptionDescription3,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // Prezzo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: isEditing
                      ? CustomTextField(
                          controller: priceController,
                          label: 'Subscription Price',
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                        )
                      : Text(
                          widget.currentUser.subscriptionPrice == 0 
                            ? 'FREE' 
                            : '\$ ${widget.currentUser.subscriptionPrice.toStringAsFixed(2)} / mo',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // Pulsante Subscribe
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('You must be logged in to subscribe')),
                        );
                        return;
                      }

                      try {
                        if (_isSubscribed) {
                          // Logica di disiscrizione
                          await _subscriptionController.unsubscribe(
                            subscriberId: currentUser.uid,
                            creatorId: widget.currentUser.uid,
                          );
                          
                          // Rimuovi la subscription dal database
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(currentUser.uid)
                              .update({
                            'subscriptions': FieldValue.arrayRemove([widget.currentUser.uid]),
                          });

                          // Traccia la cancellazione con PostHog
                          Posthog().capture(
                            eventName: 'subscription_cancelled',
                            properties: {
                              'creator_id': widget.currentUser.uid,
                              'subscriber_id': currentUser.uid,
                              'subscription_price': widget.currentUser.subscriptionPrice,
                            },
                          );

                          setState(() {
                            _isSubscribed = false;
                          });

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Subscription cancelled')),
                          );
                        } else {
                          // Logica di iscrizione esistente
                          await _subscriptionController.subscribe(
                            subscriberId: currentUser.uid,
                            creatorId: widget.currentUser.uid,
                          );
                          
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(currentUser.uid)
                              .update({
                            'subscriptions': FieldValue.arrayUnion([widget.currentUser.uid]),
                          });

                          Posthog().capture(
                            eventName: 'subscription_created',
                            properties: {
                              'creator_id': widget.currentUser.uid,
                              'subscriber_id': currentUser.uid,
                              'subscription_price': widget.currentUser.subscriptionPrice,
                              'subscription_benefits': [
                                widget.currentUser.subscriptionDescription1,
                                widget.currentUser.subscriptionDescription2,
                                widget.currentUser.subscriptionDescription3,
                              ],
                            },
                          );

                          setState(() {
                            _isSubscribed = true;
                          });

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Subscription successful!')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellowAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isSubscribed ? 'Unsubscribe' : 'Subscribe',
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      // Salva i valori quando il modal viene chiuso
      if (isEditing) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUser.uid)
            .update({
          'subscriptionPrice': double.tryParse(priceController.text) ?? 9.99,
          'subscriptionDescription1': benefitControllers[0].text,
          'subscriptionDescription2': benefitControllers[1].text,
          'subscriptionDescription3': benefitControllers[2].text,
        }).then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscription settings updated!')),
          );
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating subscription: $error')),
          );
        });
      }
    });
  }

  void _showExperienceManager() async {
    final experiences = await _getExperiences();
    if (!mounted) return;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Color(0xFF181819),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ExperienceManager(
          userId: widget.currentUser.uid,
          experiences: experiences,
        ),
      ),
    );
  }

  Future<List<Experience>> _getExperiences() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUser.uid)
        .collection('experiences')
        .orderBy('startDate', descending: true)
        .get();

    return snapshot.docs.map((doc) => Experience.fromFirestore(doc)).toList();
  }

  void _showCertificationManager() async {
    final certifications = await _getCertifications();
    if (!mounted) return;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Color(0xFF181819),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: CertificationManager(
          userId: widget.currentUser.uid,
          certifications: certifications,
        ),
      ),
    );
  }

  void _showSocialManager() async {
    final contacts = await _getSocialContacts();
    if (!mounted) return;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Color(0xFF181819),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SocialContactsManager(
          userId: widget.currentUser.uid,
          contacts: contacts,
        ),
      ),
    );
  }

  Future<List<SocialContact>> _getSocialContacts() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUser.uid)
        .collection('contacts')
        .get();

    return snapshot.docs
        .map((doc) => SocialContact.fromMap(doc.data()))
        .toList();
  }

  Future<List<Certification>> _getCertifications() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUser.uid)
        .collection('certifications')
        .get();

    return snapshot.docs
        .map((doc) => Certification.fromFirestore(doc))
        .toList();
  }

  void _showReviewManager() async {
    final reviews = await _getReviews();
    if (!mounted) return;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Color(0xFF181819),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ReviewManager(
          userId: widget.currentUser.uid,
          reviews: reviews,
        ),
      ),
    );
  }

  Future<List<Review>> _getReviews() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUser.uid)
        .collection('reviews')
        .get();

    return snapshot.docs
        .map((doc) => Review.fromFirestore(doc))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    bool isTeacher = widget.currentUser.role == 'teacher';

    return Scaffold(
      backgroundColor: const Color(0xFF181819),
      body: Stack(
        children: [
          // Contenuto principale con NestedScrollView
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Container(
                    height: 294, // Altezza totale per immagine + spazio per foto profilo
                    child: Stack(
                      children: [
                        // Immagine di copertina
                        GestureDetector(
                          onTap: isEditing ? () async {
                            await ImageService.uploadProfileImage(
                              userId: widget.currentUser.uid,
                              isProfileImage: false,
                              context: context,
                            );
                          } : null,
                          child: Container(
                            width: double.infinity,
                            height: 241,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              image: DecorationImage(
                                image: NetworkImage(
                                  widget.currentUser.coverImageUrl ?? 
                                  'https://picsum.photos/375/241'
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),

                        // Foto profilo e pulsante Follow
                        Positioned(
                          left: 20,
                          bottom: 0,
                          right: 20,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Foto profilo con bordo staccato
                              Stack(
                                children: [
                                  Container(
                                    width: 106,
                                    height: 106,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:  Colors.yellowAccent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 5,
                                    top: 5,
                                    child: GestureDetector(
                                      onTap: isEditing ? () async {
                                        try {
                                          await ImageService.uploadProfileImage(
                                            userId: widget.currentUser.uid,
                                            isProfileImage: true,
                                            context: context,
                                          );
                                          
                                          // Aggiorniamo lo stato dopo il caricamento
                                          if (mounted) {
                                            setState(() {
                                              // Forza l'aggiornamento dell'UI
                                            });
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Errore nel caricamento dell\'immagine: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      } : null,
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: 96,
                                            height: 96,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                image: NetworkImage(
                                                  widget.currentUser.profileImageUrl ?? 
                                                  'https://via.placeholder.com/96',
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          if (isEditing)
                                            Container(
                                              width: 96,
                                              height: 96,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.black.withOpacity(0.3),
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.camera_alt,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 8,
                                    bottom: 8,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF51B152),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Pulsante Follow e statistiche
                              Container(
                                margin: const EdgeInsets.only(top: 32.5),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _buildFollowButton(),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        StreamBuilder<DocumentSnapshot>(
                                          stream: FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(widget.currentUser.uid)
                                              .snapshots(),
                                          builder: (context, snapshot) {
                                            int followersCount = 0;
                                            if (snapshot.hasData && snapshot.data != null) {
                                              var userData = snapshot.data!.data() as Map<String, dynamic>;
                                              followersCount = (userData['followers'] as List?)?.length ?? 0;
                                            }
                                            return Text(
                                              '$followersCount Students',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                                fontFamily: 'Montserrat',
                                                fontWeight: FontWeight.w600,
                                              ),
                                            );
                                          },
                                        ),
                                        Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 10),
                                          width: 4,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.5),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        StreamBuilder<QuerySnapshot>(
                                          stream: FirebaseFirestore.instance
                                              .collection('courses')
                                              .where('authorId', isEqualTo: widget.currentUser.uid)
                                              .snapshots(),
                                          builder: (context, snapshot) {
                                            int coursesCount = 0;
                                            if (snapshot.hasData) {
                                              coursesCount = snapshot.data!.docs.length;
                                            }
                                            return Text(
                                              '$coursesCount Courses',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                                fontFamily: 'Montserrat',
                                                fontWeight: FontWeight.w600,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
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
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Informazioni profilo
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (isEditing)
                                  Expanded(
                                    child: TextField(
                                      controller: _nameController,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 25,
                                        fontFamily: 'Montserrat',
                                        fontWeight: FontWeight.w700,
                                      ),
                                      decoration: const InputDecoration(
                                        border: UnderlineInputBorder(),
                                        hintText: 'Il tuo nome',
                                        hintStyle: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  )
                                else
                                  Text(
                                    widget.currentUser.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 25,
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                if (!isEditing)
                                  const SizedBox(width: 8),
                                if (!isEditing)
                                  const Icon(
                                    Icons.verified,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (isEditing)
                              TextField(
                                controller: _usernameController,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 14,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: const InputDecoration(
                                  border: UnderlineInputBorder(),
                                  hintText: '@username',
                                  hintStyle: TextStyle(color: Colors.grey),
                                ),
                              )
                            else
                              Text(
                                '@${widget.currentUser.username ?? 'username'}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 14,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            const SizedBox(height: 16),
                            if (isEditing)
                              TextField(
                                controller: _bioController,
                                maxLines: 3,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 14,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: const InputDecoration(
                                  border: UnderlineInputBorder(),
                                  hintText: 'Scrivi qualcosa su di te...',
                                  hintStyle: TextStyle(color: Colors.grey),
                                ),
                              )
                            else
                              Text(
                                widget.currentUser.bio ?? 'No bio yet',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 14,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            const SizedBox(height: 24),
                            // Rating stars
                            Row(
                              children: [
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(widget.currentUser.uid)
                                      .collection('reviews')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return Row(
                                        children: [
                                          ...List.generate(5, (index) => const Icon(
                                            Icons.star,
                                            color: Colors.yellowAccent,
                                            size: 18,
                                          )),
                                          const SizedBox(width: 8),
                                          Text(
                                            '0 reviews',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.65),
                                              fontSize: 14,
                                              fontFamily: 'Montserrat',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      );
                                    }

                                    final reviews = snapshot.data!.docs;
                                    final averageRating = reviews.isEmpty 
                                        ? 0.0 
                                        : reviews.map((doc) => doc['rating'] as num).reduce((a, b) => a + b) / reviews.length;

                                    return Row(
                                      children: [
                                        ...List.generate(5, (index) => Icon(
                                          index < averageRating.round() ? Icons.star : Icons.star_border,
                                          color: Colors.yellowAccent,
                                          size: 18,
                                        )),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${reviews.length} reviews',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.65),
                                            fontSize: 14,
                                            fontFamily: 'Montserrat',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Subscribe button
                            GestureDetector(
                              onTap: () => _showSubscriptionModal(context),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF282828),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.yellowAccent.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.only(right: 12),
                                            child: Icon(
                                              Icons.discount_outlined,
                                              color: Colors.yellowAccent.withOpacity(0.8),
                                              size: 22,
                                            ),
                                          ),
                                          Text(
                                            'Subscribe',
                                            style: TextStyle(
                                              color: Colors.yellowAccent.withOpacity(0.8),
                                              fontSize: 14,
                                              fontFamily: 'Montserrat',
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E1E1E),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.1),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        widget.currentUser.subscriptionPrice == 0 
                                          ? 'FREE' 
                                          : '\$ ${widget.currentUser.subscriptionPrice.toStringAsFixed(2)} / mo',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontFamily: 'Montserrat',
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      indicatorColor:  Colors.yellowAccent,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withOpacity(0.5),
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: const [
                        Tab(text: 'Feed'),
                        Tab(text: 'Chat'),
                        Tab(text: 'About'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                ProfileFeedTab(
                  userCourses: userCourses,
                  isLoading: isLoading,
                ),
                PrivateChatTab(
                  profileUser: widget.currentUser,
                  currentUser: FirebaseAuth.instance.currentUser!,
                ),
                AboutTab(
                  profileUser: widget.currentUser,
                  currentUser: FirebaseAuth.instance.currentUser!,
                ),
              ],
            ),
          ),

          // Pulsanti superiori
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 23,
            right: 23,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircularButton(
                  Icons.arrow_back,
                  onPressed: () => Navigator.pop(context),
                ),
                isEditing
                    ? _buildCircularButton(
                        Icons.save,
                        onPressed: () => _updateProfile({
                          'name': _nameController.text,
                          'bio': _bioController.text,
                          'username': _usernameController.text,
                        }),
                      )
                    : _buildCircularButton(
                        Icons.more_horiz,
                        onPressed: () {
                          if (FirebaseAuth.instance.currentUser?.uid == widget.currentUser.uid) {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: const Color(0xFF282828),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (context) => Container(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.edit, color: Colors.white),
                                      title: const Text(
                                        'Modifica Profilo',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        setState(() {
                                          isEditing = true;
                                        });
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.work_outline, color: Colors.white),
                                      title: const Text(
                                        'Gestisci Esperienze',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showExperienceManager();
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.verified, color: Colors.white),
                                      title: const Text(
                                        'Gestisci Certificazioni',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showCertificationManager();
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.group, color: Colors.white),
                                      title: const Text(
                                        'Gestisci Social e Contatti',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _showSocialManager();
                                      },
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.add_box_outlined, color: Colors.white),
                                      title: Text(
                                        'Courses',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context); // Chiude il bottom sheet
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CourseManagementScreen(
                                              userId: widget.currentUser.uid,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularButton(IconData icon, {required VoidCallback onPressed}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xEA282828),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildFollowButton() {
    return Hero(
      tag: 'followButton${widget.currentUser.uid}',
      child: SizedBox(
        height: 45, // Altezza fissa del pulsante
        child: ElevatedButton.icon(
          onPressed: () {
            HapticFeedback.mediumImpact();
            _toggleFollow();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _isFollowing ? Colors.yellowAccent : const Color(0xFF282828),
            foregroundColor: _isFollowing ? Colors.black : Colors.yellowAccent,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            minimumSize: const Size(120, 45), // Dimensione minima
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Colors.yellowAccent.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          icon: Icon(_isFollowing ? Icons.check : Icons.add),
          label: Text(
            _isFollowing ? 'Following' : 'Follow',
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionButton() {
    // Se il prezzo è 0, mostra "FREE" invece di "€0.00"
    String priceText = widget.currentUser.subscriptionPrice == 0 
        ? 'FREE' 
        : '€${widget.currentUser.subscriptionPrice.toStringAsFixed(2)}';

    return Hero(
      tag: 'subscriptionButton${widget.currentUser.uid}',
      child: SizedBox(
        height: 45,
        child: ElevatedButton.icon(
          onPressed: () {
            HapticFeedback.mediumImpact();
            _toggleSubscription();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _isSubscribed ? Colors.yellowAccent : const Color(0xFF282828),
            foregroundColor: _isSubscribed ? Colors.black : Colors.yellowAccent,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            minimumSize: const Size(120, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Colors.yellowAccent.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          icon: Icon(_isSubscribed ? Icons.check : Icons.add),
          label: Text(
            _isSubscribed ? 'Subscribed' : priceText, // Usa priceText qui
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF181819),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
} 