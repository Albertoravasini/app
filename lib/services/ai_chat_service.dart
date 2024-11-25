import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:Just_Learn/models/ai_chat_message.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Just_Learn/models/level.dart';

class AIChatService {
  static final AIChatService _instance = AIChatService._internal();
  factory AIChatService() => _instance;
  AIChatService._internal();

  static const String baseUrl = 'http://167.99.131.91:3000';
  final List<AIChatMessage> _chatHistory = [];

  List<AIChatMessage> get chatHistory => List.unmodifiable(_chatHistory);

  void addMessage(AIChatMessage message) {
    _chatHistory.add(message);
  }

  Future<bool> _checkConnection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/ai/chat'));
      return response.statusCode == 200;
    } catch (e) {
      print('Errore di connessione: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> sendMessage(String message, String videoId, String levelId) async {
    if (!await _checkConnection()) {
      throw Exception('Server non raggiungibile');
    }

    try {
      final requestBody = {
        'message': message,
        'videoId': videoId,
        'levelId': levelId,
        'videoTitle': 'Video',
        'chatHistory': _chatHistory.map((msg) => msg.toMap()).toList(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception('Errore del server: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final aiMessage = AIChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          isAi: true,
          content: data['response'],
          timestamp: DateTime.now(),
        );
        
        _chatHistory.add(aiMessage);
        return {
          'aiMessage': aiMessage,
          'videoTitle': 'Video',
        };
      } else {
        throw Exception('Risposta non valida dal server: ${data['message']}');
      }
    } catch (e) {
      print('ERRORE AIChatService: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendMessageWithoutUserMessage(String message, String videoId, String levelId) async {
    print('Tentativo di connessione a: $baseUrl/ai/chat');
    
    try {
      // Verifica la connessione al server prima di procedere
      try {
        final testResponse = await http.get(Uri.parse('$baseUrl/ai/chat'));
        print('Status code risposta: ${testResponse.statusCode}');
        if (testResponse.statusCode != 200) {
          throw Exception('Server non raggiungibile: ${testResponse.statusCode}');
        }
      } catch (e) {
        print('Errore di connessione: $e');
        throw Exception('Impossibile connettersi al server: $e');
      }

      final requestBody = {
        'message': message,
        'videoId': videoId,
        'levelId': levelId,
        'videoTitle': 'Video', // Semplificato per il debug
        'chatHistory': _chatHistory.map((msg) => msg.toMap()).toList(),
      };

      print('AIChatService: Invio richiesta POST a $baseUrl/ai/chat');
      
      final response = await http.post(
        Uri.parse('$baseUrl/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception('Errore del server: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final aiMessage = AIChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          isAi: true,
          content: data['response'],
          timestamp: DateTime.now(),
        );
        
        _chatHistory.add(aiMessage);
        return {
          'aiMessage': aiMessage,
          'videoTitle': 'Video',
        };
      } else {
        throw Exception('Risposta non valida dal server: ${data['message']}');
      }
    } catch (e) {
      print('ERRORE AIChatService: $e');
      print('Stack trace: ${StackTrace.current}');
      throw Exception('Errore nella comunicazione con l\'AI: $e');
    }
  }

  void clearHistory() {
    _chatHistory.clear();
  }
} 