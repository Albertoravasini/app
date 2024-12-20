import 'package:flutter/material.dart' hide Notification;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/user.dart' show UserModel, Notification;
import 'VideoPlayerScreen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          currentUser = UserModel.fromMap(userDoc.data()!);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Attività',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFF2C2C2C),
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.yellowAccent,
              indicatorWeight: 3,
              labelColor: Colors.yellowAccent,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'INSEGNANTI'),
                Tab(text: 'COMMENTI'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsList(type: 'teacher'),
          _buildNotificationsList(type: 'comment'),
        ],
      ),
    );
  }

  Widget _buildNotificationsList({required String type}) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.yellowAccent),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const SizedBox();

        final notifications = (userData['notifications'] as List<dynamic>? ?? [])
            .map((n) => Notification.fromMap(n))
            .where((n) => type == 'teacher' ? n.isFromTeacher : !n.isFromTeacher)
            .toList();

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type == 'teacher' ? Icons.school : Icons.comment,
                  size: 64,
                  color: Colors.white24,
                ),
                const SizedBox(height: 16),
                Text(
                  type == 'teacher' 
                      ? 'Nessuna notifica dagli insegnanti'
                      : 'Nessuna notifica dai commenti',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: notifications.length,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _NotificationCard(
              notification: notification,
              onTap: () => _handleNotificationTap(notification),
              onDismiss: () => _dismissNotification(notification.id),
            );
          },
        );
      },
    );
  }

  void _handleNotificationTap(Notification notification) async {
    // Segna come letta
    await _markAsRead(notification.id);

    // Naviga alla schermata appropriata
    if (notification.videoId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            videoId: notification.videoId!,
            autoOpenComments: true,
          ),
        ),
      );
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    if (currentUser == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
    final userDoc = await userRef.get();
    final notifications = List<dynamic>.from(userDoc.data()?['notifications'] ?? []);
    
    final index = notifications.indexWhere((n) => n['id'] == notificationId);
    if (index != -1) {
      notifications[index]['isRead'] = true;
      await userRef.update({'notifications': notifications});
    }
  }

  Future<void> _dismissNotification(String notificationId) async {
    if (currentUser == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
    await userRef.update({
      'notifications': FieldValue.arrayRemove([
        {'id': notificationId}
      ])
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifica rimossa'),
        backgroundColor: Colors.yellowAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _NotificationCard({
    required Notification notification,
    required VoidCallback onTap,
    required VoidCallback onDismiss,
  }) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.withOpacity(0.8),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: notification.isRead 
                ? Colors.transparent
                : const Color(0xFF1E1E1E),
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFF2C2C2C),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: notification.isRead
                      ? Colors.grey.withOpacity(0.1)
                      : Colors.yellowAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification.isFromTeacher ? Icons.school : Icons.chat_bubble_outline,
                  color: notification.isRead
                      ? Colors.grey
                      : Colors.yellowAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: notification.isRead
                            ? Colors.white70
                            : Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(notification.timestamp),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, left: 8),
                  decoration: const BoxDecoration(
                    color: Colors.yellowAccent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Ora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m fa';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h fa';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}g fa';
    } else {
      return DateFormat('d MMM').format(timestamp);
    }
  }
}