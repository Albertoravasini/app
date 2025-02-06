import 'package:Just_Learn/screens/profile_screen.dart';
import 'package:Just_Learn/widgets/private_chat_tab.dart';
import 'package:flutter/material.dart' hide Notification;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/user.dart' show UserModel, Notification, NotificationType;
import 'VideoPlayerScreen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserModel? currentUser;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
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
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Activity',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Custom Tab Bar
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.yellowAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.yellowAccent,
                          width: 1,
                        ),
                      ),
                      indicatorPadding: EdgeInsets.zero,
                      padding: EdgeInsets.zero,
                      labelPadding: EdgeInsets.zero,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.yellowAccent,
                      unselectedLabelColor: Colors.white.withOpacity(0.5),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.school_outlined, size: 18),
                              const SizedBox(width: 8),
                              const Text('TEACHERS'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 18),
                              const SizedBox(width: 8),
                              const Text('COMMENTS'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Tab View Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNotificationsList(type: 'teacher'),
                  _buildNotificationsList(type: 'comment'),
                ],
              ),
            ),
          ],
        ),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: Colors.yellowAccent,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading notifications...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const SizedBox();

        final notifications = (userData['notifications'] as List<dynamic>? ?? [])
            .map((n) => Notification.fromMap(n))
            .where((n) {
              if (type == 'teacher') {
                return n.type == NotificationType.teacherMessage || 
                       n.type == NotificationType.studentMessage;
              } else {
                return n.type == NotificationType.commentReply;
              }
            })
            .toList();

        notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type == 'teacher' ? Icons.school : Icons.comment,
                  size: 64,
                  color: Colors.white12,
                ),
                const SizedBox(height: 24),
                Text(
                  type == 'teacher' 
                      ? 'No messages from teachers yet'
                      : 'No comment notifications yet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  type == 'teacher'
                      ? 'Start learning to connect with teachers'
                      : 'Engage with the community to get notifications',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          itemCount: notifications.length,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return AnimatedBuilder(
              animation: _scrollController,
              builder: (context, child) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  curve: Curves.easeOutQuart,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NotificationCard(
                      notification: notification,
                      onTap: () => _handleNotificationTap(notification),
                      onDismiss: () => _dismissNotification(notification.id),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _handleNotificationTap(Notification notification) async {
    // Segna come letta
    await _markAsRead(notification.id);

    if (!context.mounted) return;

    // Gestisci diversamente in base al tipo di notifica
    switch (notification.type) {
      case NotificationType.teacherMessage:
      case NotificationType.studentMessage:
        // Per i messaggi, naviga al profilo
        if (notification.senderId != null) {
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(notification.senderId)
                .get();

            if (userDoc.exists && context.mounted) {
              final userData = userDoc.data()!;
              final profileUser = UserModel.fromMap(userData);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    currentUser: profileUser,
                  ),
                ),
              );
            }
          } catch (e) {
            print('Errore nel recupero dati utente: $e');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error loading profile'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
        break;

      case NotificationType.commentReply:
        // Per le risposte ai commenti, naviga al video
        if (notification.videoId != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(
                videoId: notification.videoId!,
                autoOpenComments: true, // Apre automaticamente i commenti
              ),
            ),
          );
        }
        break;
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
    final userDoc = await userRef.get();
    
    // Ottieni l'array corrente delle notifiche
    final notifications = List<dynamic>.from(userDoc.data()?['notifications'] ?? []);
    
    // Trova e rimuovi la notifica completa
    notifications.removeWhere((n) => n['id'] == notificationId);
    
    // Aggiorna il documento con il nuovo array
    await userRef.update({'notifications': notifications});

    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification removed'),
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
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (_) => onDismiss(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: notification.isRead 
                  ? const Color(0xFF1A1A1A)
                  : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: notification.isRead
                    ? Colors.white.withOpacity(0.05)
                    : Colors.yellowAccent.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: notification.isRead
                        ? Colors.white.withOpacity(0.05)
                        : Colors.yellowAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification),
                    color: notification.isRead
                        ? Colors.white.withOpacity(0.5)
                        : Colors.yellowAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: FutureBuilder<String>(
                              future: _getNotificationTitle(notification),
                              builder: (context, snapshot) {
                                return Text(
                                  snapshot.data ?? 'Loading...',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 16,
                                    fontWeight: notification.isRead 
                                        ? FontWeight.w500 
                                        : FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                          ),
                          Text(
                            _formatTimestamp(notification.timestamp),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: notification.isRead
                              ? Colors.white.withOpacity(0.5)
                              : Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: const BoxDecoration(
                      color: Colors.yellowAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(Notification notification) {
    switch (notification.type) {
      case NotificationType.teacherMessage:
        return Icons.school;
      case NotificationType.studentMessage:
        return Icons.person_outline;
      case NotificationType.commentReply:
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications_none;
    }
  }

  Future<String> _getNotificationTitle(Notification notification) async {
    if (notification.senderId != null) {
      try {
        final senderDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(notification.senderId)
            .get();
        
        if (senderDoc.exists) {
          return senderDoc.data()?['name'] ?? 'Utente';
        }
      } catch (e) {
        print('Errore nel recupero del nome: $e');
      }
    }
    
    switch (notification.type) {
      case NotificationType.teacherMessage:
        return 'Insegnante';
      case NotificationType.studentMessage:
        return 'Studente';
      case NotificationType.commentReply:
        return 'Nuovo commento';
      default:
        return 'Notifica';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('d MMM').format(timestamp);
    }
  }

  Widget _buildNotificationItem(Notification notification) {
    IconData icon;
    String title;
    VoidCallback? onTap;

    switch (notification.type) {
      case 'message':
        icon = Icons.message;
        title = notification.isFromTeacher ? 'Messaggio dal docente' : 'Messaggio dallo studente';
        onTap = notification.senderId != null ? () async {
          // Prima ottieni i dati dell'utente
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(notification.senderId)
              .get();
          
          if (userDoc.exists && context.mounted) {
            final userData = userDoc.data()!;
            final profileUser = UserModel.fromMap(userData);
            
            // Naviga alla chat con il mittente
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PrivateChatTab(
                  profileUser: profileUser,
                  currentUser: FirebaseAuth.instance.currentUser!,
                ),
              ),
            );
          }
        } : null;
        break;
      default:
        icon = notification.isFromTeacher ? Icons.school : Icons.comment;
        title = notification.message;
        onTap = notification.videoId != null ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(videoId: notification.videoId!),
            ),
          );
        } : null;
    }

    return _NotificationCard(
      notification: notification,
      onTap: () {
        _markAsRead(notification.id);
        if (onTap != null) onTap();
      },
      onDismiss: () => _dismissNotification(notification.id),
    );
  }
}