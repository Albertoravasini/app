import 'package:Just_Learn/models/message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:Just_Learn/services/notification_service.dart';

class PrivateChatTab extends StatefulWidget {
  final UserModel profileUser;
  final User currentUser;
  const PrivateChatTab({
    Key? key,
    required this.profileUser,
    required this.currentUser,
  }) : super(key: key);
  @override
  State<PrivateChatTab> createState() => _PrivateChatTabState();
}
class _PrivateChatTabState extends State<PrivateChatTab> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  String? selectedChatUserId;
  String _getChatId(String currentUserId, String otherUserId) {
    final List<String> ids = [currentUserId, otherUserId]..sort();
    return '${ids[0]}_${ids[1]}';
  }
  bool? _hasSubscription;
  @override
  void initState() {
    super.initState();
    // Se non siamo il proprietario del profilo, impostiamo automaticamente l'ID dell'utente del profilo
    if (widget.currentUser.uid != widget.profileUser.uid) {
      selectedChatUserId = widget.profileUser.uid;
    }
    // Controlla la subscription all'inizio
    _checkSubscriptionStatus().then((value) {
      if (mounted) {
        setState(() {
          _hasSubscription = value;
        });
      }
    });
  }
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    try {
      if (selectedChatUserId == null) return;
      final receiverId = selectedChatUserId!;
      final chatId = _getChatId(widget.currentUser.uid, receiverId);

      // Crea o aggiorna il documento della chat
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .set({
        'participants': [widget.currentUser.uid, receiverId],
        'lastMessage': message,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Salva il messaggio nella subcollection
      final messageDoc = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      // Ottieni i dati del mittente
      final senderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .get();
      final senderRole = senderDoc.data()?['role'];
      final senderName = senderDoc.data()?['name'] ?? 'Unknown';
      final isTeacher = senderRole == 'teacher';

      final newMessage = {
        'id': messageDoc.id,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'senderId': widget.currentUser.uid,
        'receiverId': receiverId,
      };

      // Salva il messaggio
      await messageDoc.set(newMessage);

      // Crea la notifica
      final notification = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'isFromTeacher': isTeacher,
        'senderId': widget.currentUser.uid,
        'type': isTeacher ? 'teacherMessage' : 'studentMessage'
      };

      // Aggiorna le notifiche del destinatario
      await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .update({
        'notifications': FieldValue.arrayUnion([notification])
      });

      // Invia notifica push
      final receiverDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .get();
      
      final fcmToken = receiverDoc.data()?['fcmToken'];
      if (fcmToken != null) {
        final notificationService = NotificationService();
        await notificationService.sendSpecificNotification(
          fcmToken,
          isTeacher ? 'teacher_message' : 'student_message',
          senderName
        );
      }

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      print('Errore nell\'invio del messaggio: $e');
    }
  }
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    // Sostituisci il FutureBuilder con una semplice condizione
    if (_hasSubscription == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
        ),
      );
    }

    // Se non il proprietario e nessuna subscription, mostra il messaggio
    if (widget.currentUser.uid != widget.profileUser.uid && !_hasSubscription!) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Private chat not available',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Subscribe to chat with this creator',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Se proprietario o ha subscription, mostra chat
    if (widget.currentUser.uid != widget.profileUser.uid) {
      return _buildSingleChat();
    }

    // Existing code for chat list
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: widget.currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
            ),
          );
        }
        final chats = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final chatId = doc.id;
          final participants = List<String>.from(data['participants'] ?? []);
          final otherUserId = participants.firstWhere(
            (id) => id != widget.currentUser.uid,
            orElse: () => '',
          );
          return {'id': chatId, 'otherUserId': otherUserId};
        }).toList();
        if (selectedChatUserId != null) {
          return _buildSingleChat(userId: selectedChatUserId);
        }
        if (chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/empty_chat.svg',
                  width: 200,
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a conversation!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }
        return Scaffold(
          backgroundColor: const Color(0xFF181819),
          body: Column(
            children: [
              // Header elegante
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: const [
                    Text(
                      'Chat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
              // Lista chat con animazioni
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final otherUserId = chat['otherUserId'];
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(otherUserId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return const SizedBox();
                        }
                        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                        final userName = userData['name'] ?? 'Utente';
                        final userImage = userData['profileImageUrl'];
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF282828),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  selectedChatUserId = otherUserId;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Hero(
                                      tag: 'avatar_$otherUserId',
                                      child: CircleAvatar(
                                        radius: 28,
                                        backgroundColor: Colors.yellowAccent,
                                        child: CircleAvatar(
                                          radius: 26,
                                          backgroundImage: userImage != null
                                              ? NetworkImage(userImage)
                                              : null,
                                          child: userImage == null
                                              ? Text(
                                                  userName[0].toUpperCase(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Montserrat',
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          StreamBuilder<QuerySnapshot>(
                                            stream: FirebaseFirestore.instance
                                                .collection('chats')
                                                .doc(chat['id'])
                                                .collection('messages')
                                                .orderBy('timestamp', descending: true)
                                                .limit(1)
                                                .snapshots(),
                                            builder: (context, messageSnapshot) {
                                              if (!messageSnapshot.hasData ||
                                                  messageSnapshot.data!.docs.isEmpty) {
                                                return const SizedBox();
                                              }
                                              final lastMessage = messageSnapshot
                                                  .data!.docs.first
                                                  .data() as Map<String, dynamic>;
                                              final isMyMessage = 
                                                  lastMessage['senderId'] == widget.currentUser.uid;
                                              return Row(
                                                children: [
                                                  if (isMyMessage)
                                                    const Icon(
                                                      Icons.reply,
                                                      size: 16,
                                                      color: Colors.yellowAccent,
                                                    ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      lastMessage['message'] as String,
                                                      style: TextStyle(
                                                        color: Colors.white.withOpacity(0.7),
                                                        fontFamily: 'Montserrat',
                                                        fontSize: 14,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.yellowAccent,
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Add this new method to check subscription status
  Future<bool> _checkSubscriptionStatus() async {
    if (widget.currentUser.uid == widget.profileUser.uid) {
      return true; // Owner always has access
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUser.uid)
        .get();

    if (!userDoc.exists) return false;

    final userData = userDoc.data() as Map<String, dynamic>;
    final subscriptions = List<String>.from(userData['subscriptions'] ?? []);
    
    return subscriptions.contains(widget.profileUser.uid);
  }

  Widget _buildSingleChat({String? userId}) {
    final chatUserId = userId ?? widget.profileUser.uid;
    
    return Container(
      color: const Color(0xFF181819),
      child: Column(
        children: [
          // Header elegante
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 16,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                if (widget.currentUser.uid == widget.profileUser.uid)
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.yellowAccent),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        selectedChatUserId = null;
                      });
                    },
                  ),
                Padding(
                  padding: EdgeInsets.only(
                    left: widget.currentUser.uid == widget.profileUser.uid ? 48.0 : 0,
                  ),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'avatar_$chatUserId',
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.yellowAccent,
                          child: CircleAvatar(
                            radius: 22,
                            backgroundImage: NetworkImage(
                              widget.profileUser.profileImageUrl ?? 'https://via.placeholder.com/40',
                            ),
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
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: const [
                                CircleAvatar(
                                  radius: 4,
                                  backgroundColor: Color(0xFF51B152),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Online',
                                  style: TextStyle(
                                    color: Colors.white70,
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
                ),
              ],
            ),
          ),
          // Area messaggi
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_getChatId(widget.currentUser.uid, chatUserId))
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
                    ),
                  );
                }
                
                final messages = snapshot.data!.docs;
                
                if (_scrollController.hasClients && messages.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _scrollToBottom();
                    }
                  });
                }

                return ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 22,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final isMe = message['senderId'] == widget.currentUser.uid;
                    final timestamp = (message['timestamp'] as Timestamp?)?.toDate();
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(message['senderId'] as String)
                          .get(),
                      builder: (context, userSnapshot) {
                        String? userImage;
                        if (userSnapshot.hasData && userSnapshot.data != null) {
                          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                          userImage = userData?['profileImageUrl'] as String?;
                        }
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == messages.length - 1 ? 12 : 12,
                          ),
                          child: Row(
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isMe) ...[
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.yellowAccent,
                                  child: CircleAvatar(
                                    radius: 15,
                                    backgroundImage: userImage != null
                                        ? NetworkImage(userImage)
                                        : null,
                                    child: userImage == null
                                        ? Icon(Icons.person, size: 20, color: Colors.white)
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.yellowAccent : const Color(0xFF282828),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 20),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message['message'] as String,
                                      style: TextStyle(
                                        color: isMe ? Colors.black : Colors.white,
                                        fontSize: 14,
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                    if (timestamp != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          color: isMe ? Colors.black54 : Colors.white54,
                                          fontSize: 10,
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          // Input area con padding bottom minimo
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: 8 + (MediaQuery.of(context).padding.bottom / 2) + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      style: const TextStyle(color: Colors.white),
                      autofocus: false,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.send,
                      enableInteractiveSelection: true,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF282828),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (value) {
                        _sendMessage(value);
                        _focusNode.requestFocus();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _sendMessage(_messageController.text);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.yellowAccent,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 