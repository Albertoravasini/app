import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<void> _updateProfile() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .update({
        'name': _nameController.text,
        'bio': _bioController.text,
        'username': _usernameController.text,
      });

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
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181819),
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
                // Lista dei benefici
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
                        const Text(
                          "Full access to this user's content",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // Prezzo con lo stile del topic
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
                                      child: const Text(
                                        '\$ 9.99 / month',
                                        style: TextStyle(
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
                          const SnackBar(content: Text('Devi effettuare l\'accesso per iscriverti')),
                        );
                        return;
                      }

                      try {
                        // Implementa la logica di sottoscrizione
                        await _subscriptionController.subscribe(
                          subscriberId: currentUser.uid,
                          creatorId: widget.currentUser.uid,
                        );
                        
                        // Aggiorna lo stato di iscrizione nel database
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUser.uid)
                            .update({
                          'subscriptions': FieldValue.arrayUnion([widget.currentUser.uid]),
                        });

                        setState(() {
                          _isSubscribed = true;
                        });

                        Navigator.pop(context); // Chiudi il modal
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Iscrizione effettuata con successo!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Errore durante l\'iscrizione: $e')),
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
    );
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
                                        await ImageService.uploadProfileImage(
                                          userId: widget.currentUser.uid,
                                          isProfileImage: true,
                                          context: context,
                                        );
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
                                ...List.generate(5, (index) => const Icon(
                                  Icons.star,
                                  color: Colors.yellow,
                                  size: 18,
                                )),
                                const SizedBox(width: 8),
                                Text(
                                  '26 reviews',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.65),
                                    fontSize: 14,
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w500,
                                  ),
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
                                      child: const Text(
                                        '\$ 9.99 / mo',
                                        style: TextStyle(
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
                        Tab(text: 'Community'),
                        Tab(text: 'Calendar'),
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
                FirebaseAuth.instance.currentUser?.uid != widget.currentUser.uid
                  ? PrivateChatTab(
                      currentUser: FirebaseAuth.instance.currentUser!,
                      profileUser: widget.currentUser,
                    )
                  : const Center(
                      child: Text(
                        'Questa è la tua chat personale',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                Container(), // Calendar tab
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
                        onPressed: _updateProfile,
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