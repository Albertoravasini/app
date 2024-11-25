class AIChatMessage {
  final String id;
  final bool isAi;
  final String content;
  final DateTime timestamp;

  AIChatMessage({
    required this.id,
    required this.isAi,
    required this.content,
    required this.timestamp,
  });

  factory AIChatMessage.fromMap(Map<String, dynamic> data) {
    return AIChatMessage(
      id: data['id'] ?? '',
      isAi: data['isAi'] ?? false,
      content: data['content'] ?? '',
      timestamp: DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isAi': isAi,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }
} 