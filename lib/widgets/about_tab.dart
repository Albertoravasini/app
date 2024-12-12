import 'package:Just_Learn/models/certification.dart';
import 'package:Just_Learn/models/experience.dart';
import 'package:Just_Learn/models/review.dart';
import 'package:Just_Learn/widgets/social_contacts_manager.dart';
import 'package:flutter/material.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutTab extends StatefulWidget {
  final UserModel profileUser;
  final User currentUser;

  const AboutTab({
    Key? key,
    required this.profileUser,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<AboutTab> createState() => _AboutTabState();
}

class _AboutTabState extends State<AboutTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sezione Presentazione
          _buildPresentationSection(),
          const SizedBox(height: 24),

          // Sezione Esperienza
          _buildExperienceSection(),
          const SizedBox(height: 24),

          // Sezione Statistiche
          _buildStatsSection(),
          const SizedBox(height: 24),

          // Sezione Competenze
          _buildTopicsSection(),
          const SizedBox(height: 24),

          // Sezione Certificazioni
          _buildCertificationsSection(),
          const SizedBox(height: 24),

          // Sezione Social e Contatti
          _buildSocialSection(),
          const SizedBox(height: 24),

          // Sezione Recensioni
          _buildReviewsSection(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPresentationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.yellowAccent,
                child: CircleAvatar(
                  radius: 38,
                  backgroundImage: NetworkImage(
                    widget.profileUser.profileImageUrl ?? 'https://via.placeholder.com/80',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.profileUser.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    Text(
                      '@${widget.profileUser.username}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.profileUser.location ?? 'Location not specified',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            widget.profileUser.bio ?? 'No biography available',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              height: 1.5,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.work_outline,
            title: 'Experience',
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Experience>>(
            future: _getExperiences(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
                  ),
                );
              }

              final experiences = snapshot.data ?? [];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: experiences.map((exp) => _ExperienceItem(
                  title: exp.title,
                  company: exp.company,
                  period: exp.period,
                  description: exp.description,
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.verified_outlined,
            title: 'Certifications',
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Certification>>(
            future: _getCertifications(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
                  ),
                );
              }

              final certifications = snapshot.data ?? [];
              return Column(
                children: certifications.map((cert) => _CertificationItem(
                  title: cert.title,
                  issuer: cert.issuer,
                  date: DateFormat('MMM yyyy').format(cert.date),
                  imageUrl: cert.imageUrl,
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.link,
            title: 'Social e Contatti',
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<SocialContact>>(
            future: _getSocialContacts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
                  ),
                );
              }

              final contacts = snapshot.data ?? [];
              return Column(
                children: contacts.map((contact) => _SocialContactItem(
                  type: contact.type,
                  value: contact.value,
                  url: contact.url,
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<List<SocialContact>> _getSocialContacts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.profileUser.uid)
          .collection('contacts')
          .get();

      return snapshot.docs
          .map((doc) => SocialContact.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error retrieving social contacts: $e');
      return [];
    }
  }

  Widget _buildReviewsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionTitle(
                icon: Icons.star_outline,
                title: 'Reviews',
              ),
              // Mostra pulsanti diversi in base al ruolo
              if (widget.currentUser.uid == widget.profileUser.uid)
                // Proprietario del profilo
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.yellowAccent.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showReviewManager(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.settings,
                              color: Colors.yellowAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Manage Reviews',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else
                // Visitatore del profilo
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.yellowAccent.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showAddReviewDialog(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.rate_review,
                              color: Colors.yellowAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Write Review',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Review>>(
            future: _getReviews(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
                  ),
                );
              }

              final reviews = snapshot.data ?? [];
              if (reviews.isEmpty) {
                return const Center(
                  child: Text(
                    'No reviews available',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                );
              }

              return Column(
                children: reviews.map((review) => _ReviewItem(
                  userName: review.userName,
                  rating: review.rating,
                  comment: review.comment,
                  date: review.date,
                  userImage: review.userImage,
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showReviewManager(BuildContext context) async {
    final reviews = await _getReviews();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Manage Reviews',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return Dismissible(
                    key: Key(review.id ?? ''),
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.red),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _deleteReview(review.id ?? ''),
                    child: Card(
                      color: const Color(0xFF282828),
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: review.userImage != null
                              ? NetworkImage(review.userImage!)
                              : null,
                          child: review.userImage == null
                              ? Text(review.userName[0].toUpperCase())
                              : null,
                        ),
                        title: Text(
                          review.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          review.comment,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              review.rating.toString(),
                              style: const TextStyle(
                                color: Colors.yellowAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(
                              Icons.star,
                              color: Colors.yellowAccent,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteReview(String reviewId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.profileUser.uid)
          .collection('reviews')
          .doc(reviewId)
          .delete();
      
      // Mostra feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error deleting review'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showAddReviewDialog(BuildContext context) async {
    final _commentController = TextEditingController();
    double _rating = 5.0;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Write a Review',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rating',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return IconButton(
                              onPressed: () => setState(() => _rating = index + 1),
                              icon: Icon(
                                index < _rating ? Icons.star : Icons.star_border,
                                color: Colors.yellowAccent,
                                size: 32,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: TextField(
                      controller: _commentController,
                      maxLines: 4,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Montserrat',
                      ),
                      decoration: InputDecoration(
                        hintText: 'Share your experience...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontFamily: 'Montserrat',
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_commentController.text.isNotEmpty) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.profileUser.uid)
                              .collection('reviews')
                              .add({
                            'userName': widget.currentUser.displayName ?? 'User',
                            'userImage': widget.currentUser.photoURL,
                            'rating': _rating,
                            'comment': _commentController.text,
                            'date': DateTime.now(),
                          });
                          if (context.mounted) {
                            Navigator.pop(context);
                            // Show success feedback
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Review posted successfully!'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellowAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Post Review',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ... (altri metodi esistenti) ...

  Future<List<Experience>> _getExperiences() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.profileUser.uid)
          .collection('experiences')
          .orderBy('startDate', descending: true)
          .get();

      return snapshot.docs.map((doc) => Experience.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error retrieving experiences: $e');
      return [];
    }
  }

  Future<List<Certification>> _getCertifications() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.profileUser.uid)
          .collection('certifications')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) => Certification.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error retrieving certifications: $e');
      return [];
    }
  }

  Future<List<Review>> _getReviews() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.profileUser.uid)
          .collection('reviews')
          .orderBy('date', descending: true)
          .limit(5)
          .get();

      return snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error retrieving reviews: $e');
      return [];
    }
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.analytics_outlined,
            title: 'Statistics',
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.people_outline,
                value: widget.profileUser.followers.length.toString(),
                label: 'Followers',
              ),
              _buildStatItem(
                icon: Icons.school_outlined,
                value: widget.profileUser.unlockedCourses.length.toString(),
                label: 'Courses',
              ),
              _buildStatItem(
                icon: Icons.euro_outlined,
                value: widget.profileUser.subscriptionPrice.toString(),
                label: 'Sub Price',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.yellowAccent, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontFamily: 'Montserrat',
          ),
        ),
      ],
    );
  }

  Widget _buildTopicsSection() {
    return FutureBuilder<List<String>>(
      future: _getTopicsFromCourses(),
      builder: (context, snapshot) {
        final topics = snapshot.data ?? [];
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                icon: Icons.topic_outlined,
                title: 'Skills',
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
                ))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: topics.map((topic) => _buildTopicChip(topic)).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopicChip(String topic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.yellowAccent.withOpacity(0.3)),
      ),
      child: Text(
        topic,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: 'Montserrat',
        ),
      ),
    );
  }

  Future<List<String>> _getTopicsFromCourses() async {
    try {
      final coursesSnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .where('authorId', isEqualTo: widget.profileUser.uid)
          .get();

      final Set<String> uniqueTopics = {};
      for (var doc in coursesSnapshot.docs) {
        final courseData = doc.data();
        if (courseData['topic'] != null) {
          uniqueTopics.add(courseData['topic'] as String);
        }
      }
      return uniqueTopics.toList()..sort();
    } catch (e) {
      print('Error retrieving topics: $e');
      return [];
    }
  }
}

// Widget Components
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.yellowAccent,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
        ),
      ],
    );
  }
}

class _ExperienceItem extends StatelessWidget {
  final String title;
  final String company;
  final String period;
  final String description;

  const _ExperienceItem({
    required this.title,
    required this.company,
    required this.period,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            company,
            style: TextStyle(
              color: Colors.yellowAccent.withOpacity(0.8),
              fontSize: 14,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            period,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              height: 1.5,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificationItem extends StatelessWidget {
  final String title;
  final String issuer;
  final String date;
  final String? imageUrl;

  const _CertificationItem({
    required this.title,
    required this.issuer,
    required this.date,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          if (imageUrl != null)
            Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(imageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  issuer,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final String userName;
  final double rating;
  final String comment;
  final DateTime date;
  final String? userImage;

  const _ReviewItem({
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
    this.userImage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: userImage != null
                    ? NetworkImage(userImage!)
                    : null,
                child: userImage == null
                    ? Text(
                        userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) => Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.yellowAccent,
                          size: 16,
                        )),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('d MMM yyyy').format(date),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              height: 1.5,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialContactItem extends StatelessWidget {
  final String type;
  final String value;
  final String? url;

  const _SocialContactItem({
    required this.type,
    required this.value,
    this.url,
  });

  IconData get _getIcon {
    switch (type) {
      case 'LinkedIn': return Icons.code;
      case 'GitHub': return Icons.code;
      case 'Twitter': return Icons.code;
      case 'Instagram': return Icons.photo_camera;
      case 'Website': return Icons.language;
      case 'Email': return Icons.email;
      case 'Phone': return Icons.phone;
      default: return Icons.link;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: url != null ? () => launchUrl(Uri.parse(url!)) : null,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_getIcon, color: Colors.yellowAccent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  Text(
                    type,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            ),
            if (url != null)
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.3),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
