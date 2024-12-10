import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Just_Learn/models/user.dart';
import 'package:flutter/services.dart';

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
  String? selectedChatUserId;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentUser.uid != widget.profileUser.uid) {
      selectedChatUserId = widget.profileUser.uid;
      _checkSubscriptionStatus();
    }
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .get();
      final subscriptions = List<String>.from(doc.data()?['subscriptions'] ?? []);
      setState(() {
        _isSubscribed = subscriptions.contains(widget.profileUser.uid);
      });
    } catch (e) {
      print('Errore nel controllo della subscription: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getChatId(String otherUserId) {
    final List<String> ids = [widget.currentUser.uid, otherUserId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty || selectedChatUserId == null) return;

    final chatId = _getChatId(selectedChatUserId!);
    
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'participants': [widget.currentUser.uid, selectedChatUserId],
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': widget.currentUser.uid,
      'receiverId': selectedChatUserId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    _messageController.clear();
    _scrollToBottom();
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
    if (!_isSubscribed && widget.currentUser.uid != widget.profileUser.uid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Profile image with yellow border
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.yellowAccent,
                    Colors.yellowAccent.withOpacity(0.5),
                  ],
                ),
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF282828),
                backgroundImage: NetworkImage(
                  widget.profileUser.profileImageUrl ?? 'https://via.placeholder.com/80',
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Elegant title
            Text(
              'Private Chat Locked',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 24,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            
            // Descriptive subtitle
            Text(
              'To chat with ${widget.profileUser.name} you need to be subscribed to their profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
                fontFamily: 'Montserrat',
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Stylized lock icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.yellowAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 32,
                color: Colors.yellowAccent.withOpacity(0.8),
              ),
            ),
          ],
        ),
      );
    }

    return _buildSingleChat();
  }

  Widget _buildSingleChat({String? userId}) {
    final chatUserId = userId ?? widget.profileUser.uid;
    
    return Container(
      color: const Color(0xFF181819),
      child: Column(
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

          // Area messaggi
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_getChatId(chatUserId))
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

                return ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
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
                          padding: const EdgeInsets.only(bottom: 12),
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

          // Input area migliorata
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Scrivi un messaggio...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontFamily: 'Montserrat',
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
                    onSubmitted: (value) => _sendMessage(value),
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
        ],
      ),
    );
  }
} 