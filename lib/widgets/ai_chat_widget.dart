import 'package:flutter/material.dart';
import 'package:Just_Learn/models/ai_chat_message.dart';
import 'package:Just_Learn/services/ai_chat_service.dart';

class AIChatWidget extends StatefulWidget {
  final String videoId;
  final String levelId;
  final GlobalKey<AIChatWidgetState> aiChatKey;

  const AIChatWidget({
    Key? key,
    required this.videoId,
    required this.levelId,
    required this.aiChatKey,
  }) : super(key: key);

  @override
  AIChatWidgetState createState() => AIChatWidgetState();
}

class AIChatWidgetState extends State<AIChatWidget> {
  final AIChatService _aiChatService = AIChatService();
  final ScrollController _scrollController = ScrollController();
  bool _isWaitingResponse = false;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _aiChatService.chatHistory.length + 1 + (_isWaitingResponse ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildMessageBubble(AIChatMessage(
                  id: 'welcome',
                  isAi: true,
                  content: "Ciao! Sono il tuo assistente AI. Come posso aiutarti con questo video?",
                  timestamp: DateTime.now(),
                ));
              }
              
              if (_isWaitingResponse && index == _aiChatService.chatHistory.length + 1) {
                return _buildLoadingBubble();
              }
              
              return _buildMessageBubble(_aiChatService.chatHistory[index - 1]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.yellowAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.yellowAccent,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.yellowAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> handleMessage(String message) async {
    print('handleMessage chiamato con messaggio: $message');
    
    if (message.isEmpty || _isWaitingResponse) {
      print('Messaggio vuoto o in attesa di risposta');
      return;
    }

    setState(() {
      _isWaitingResponse = true;
      final userMessage = AIChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        isAi: false,
        content: message,
        timestamp: DateTime.now(),
      );
      _aiChatService.addMessage(userMessage);
    });

    _scrollToBottom();

    try {
      final response = await _aiChatService.sendMessageWithoutUserMessage(
        message,
        widget.videoId,
        widget.levelId,
      );

      if (mounted) {
        setState(() {
          _isWaitingResponse = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isWaitingResponse = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Widget _buildMessageBubble(AIChatMessage message) {
    return Align(
      alignment: message.isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.isAi 
              ? Colors.white.withOpacity(0.05)
              : Colors.yellowAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: message.isAi 
                ? Colors.white.withOpacity(0.1)
                : Colors.yellowAccent.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.isAi)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.yellowAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.yellowAccent,
                      size: 16,
                    ),
                  ),
                Flexible(
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
} 
