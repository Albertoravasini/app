import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import 'VideoPlayerScreen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          setState(() {
            currentUser = UserModel.fromMap(userData);
          });
        }
      }
    }
  }

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212), // Sfondo scuro
        appBar: AppBar(
          title: const Text(
            'Notifications',
            style: TextStyle(
              color: Colors.white, // Testo bianco
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF1E1E1E), // AppBar scura
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.white), // Icone bianche
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white), // Icona bianca
              onPressed: _loadCurrentUser,
            ),
          ],
        ),
        body: currentUser == null
            ? const Center(child: CircularProgressIndicator(color: Colors.yellowAccent)) // Indicatore di caricamento giallo
            : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading notifications.', style: TextStyle(color: Colors.white)));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.yellowAccent)); // Indicatore di caricamento giallo
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text('No notifications found.', style: TextStyle(color: Colors.white)));
                  }

                  final userDocument = snapshot.data;
                  final userData = userDocument!.data() as Map<String, dynamic>?;

                  if (userData == null) {
                    return const Center(child: Text('No data found.', style: TextStyle(color: Colors.white)));
                  }

                  final userModel = UserModel.fromMap(userData);

                  if (userModel.notifications.isEmpty) {
                    return const Center(child: Text('No notifications found.', style: TextStyle(color: Colors.white)));
                  }

                  return ListView.builder(
                    itemCount: userModel.notifications.length,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemBuilder: (context, index) {
                      final notification = userModel.notifications[index];
                      return Dismissible(
                        key: Key(notification.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.redAccent, // Sfondo rosso per il dismiss
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) async {
                          userModel.notifications.removeAt(index);
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userModel.uid)
                              .update({
                            'notifications': userModel.notifications
                                .map((n) => n.toMap())
                                .toList(),
                          });
                          scaffoldMessengerKey.currentState?.showSnackBar(
                            const SnackBar(content: Text('Notification dismissed', style: TextStyle(color: Colors.black)), backgroundColor: Colors.yellowAccent), // Sfondo giallo per il messaggio
                          );
                        },
                        child: NotificationCard(
                          notification: notification,
                          onTap: () async {
                            notification.isRead = true;
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(userModel.uid)
                                .update({
                              'notifications': userModel.notifications
                                  .map((n) => n.toMap())
                                  .toList(),
                            });

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
                          },
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final notification;
  final VoidCallback onTap;

  const NotificationCard({
    Key? key,
    required this.notification,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: notification.isRead ? const Color(0xFF2C2C2C) : const Color(0xFF1E1E1E), // Colori scuri per la card
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                _getIconForNotification(notification),
                size: 40,
                color: notification.isRead ? Colors.grey : Colors.yellowAccent, // Icone gialle se non lette
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                        color: notification.isRead ? Colors.white70 : Colors.white, // Testo bianco o attenuato
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(notification.timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB3B3B3), // Testo grigio chiaro per il timestamp
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white70, // Icona freccia bianca attenuata
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForNotification(notification) {
    if (notification.videoId != null) {
      return Icons.play_circle_fill;
    } else {
      return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final DateFormat formatter = DateFormat('dd MMM yyyy, hh:mm a');
    return formatter.format(timestamp);
  }
}