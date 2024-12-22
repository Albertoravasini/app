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
          'Activity',
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
                Tab(text: 'TEACHERS'),
                Tab(text: 'COMMENTS'),
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

        // Filtra le notifiche in base al tipo
        final notifications = (userData['notifications'] as List<dynamic>? ?? [])
            .map((n) => Notification.fromMap(n))
            .where((n) {
              if (type == 'teacher') {
                // Nella tab TEACHERS mostra:
                // - Per gli insegnanti: i messaggi degli studenti
                // - Per gli studenti: i messaggi degli insegnanti
                return n.type == NotificationType.teacherMessage || 
                       n.type == NotificationType.studentMessage;
              } else {
                // Nella tab COMMENTS mostra solo le risposte ai commenti
                return n.type == NotificationType.commentReply;
              }
            })
            .toList();

        // Ordina per timestamp più recente
        notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

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
                      ? 'No notifications from teachers'
                      : 'No comment notifications',
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
    await userRef.update({
      'notifications': FieldValue.arrayRemove([
        {'id': notificationId}
      ])
    });

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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: notification.isRead
                      ? Colors.grey.withOpacity(0.1)
                      : Colors.yellowAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(notification),
                  color: notification.isRead
                      ? Colors.grey
                      : Colors.yellowAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
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
                                snapshot.data ?? 'Caricamento...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: notification.isRead 
                                      ? FontWeight.normal 
                                      : FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        Text(
                          _formatTimestamp(notification.timestamp),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: notification.isRead
                            ? Colors.white54
                            : Colors.white70,
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