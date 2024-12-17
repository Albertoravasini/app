// notification_service.dart
import 'package:Just_Learn/firebase_options.dart';
import 'package:Just_Learn/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:Just_Learn/main.dart';  // Importa il main per accedere al navigatorKey

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  print('Gestione notifica in background: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _isInitialized = false;
  static bool _lastAccessUpdated = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('Inizializzazione NotificationService...');
      
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final settings = await _firebaseMessaging.requestPermission();
      print('Stato autorizzazione notifiche: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        FirebaseMessaging.onMessage.listen((message) {
          print('Ricevuta notifica in foreground: ${message.messageId}');
          _showForegroundNotification(message);
        });

        await getAndUpdateToken();
        
        _firebaseMessaging.onTokenRefresh.listen((token) {
          print('Token FCM aggiornato: ${token.substring(0, 10)}...');
          getAndUpdateToken();
        });
      }

      _isInitialized = true;
      print('NotificationService inizializzato con successo');
    } catch (e) {
      print('Errore inizializzazione NotificationService: $e');
      rethrow;
    }
  }

  Future<void> getAndUpdateToken() async {
    if (_lastAccessUpdated) return;
    
    final String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await updateLastAccess(user.uid, token);
        _lastAccessUpdated = true;
      }
    }
  }

  Future<void> _handleNotificationClick(RemoteMessage message) async {
    // Naviga alla schermata appropriata in base al tipo di notifica
    if (message.data['type'] == 'daily_reminder') {
      navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  // Mostra una notifica in foreground
  void _showForegroundNotification(RemoteMessage message) {
    if (message.notification != null) {
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (context) => AlertDialog(
          title: Text(message.notification!.title ?? 'Notifica'),
          content: Text(message.notification!.body ?? 'Hai ricevuto una notifica.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  // Funzione per disabilitare le notifiche
  Future<void> disableNotifications() async {
    await _firebaseMessaging.unsubscribeFromTopic('all');
  }

  // Funzione per abilitare le notifiche
  Future<void> enableNotifications() async {
    await _firebaseMessaging.subscribeToTopic('all');
  }

  // Funzione per inviare l'UID e il token FCM al backend
  Future<void> updateLastAccess(String uid, String fcmToken) async {
    try {
      print('Aggiornamento ultimo accesso per uid: $uid');
      print('Token FCM: ${fcmToken.substring(0, 10)}...'); // Mostra solo i primi 10 caratteri per sicurezza
      
      final url = Uri.parse('http://167.99.131.91:3000/update_last_access');  // Usa l'IP corretto del tuo server
      
      final requestBody = {
        'uid': uid,
        'fcmToken': fcmToken,
        'lastAccessTime': DateTime.now().toIso8601String(),
        'timezone': DateTime.now().timeZoneOffset.inHours
      };
      
      print('Invio richiesta con dati: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Risposta server: ${response.statusCode}');
      print('Corpo risposta: ${response.body}');

      if (response.statusCode == 200) {
        print('Ultimo accesso aggiornato con successo');
      } else {
        print('Errore nell\'aggiornamento dell\'ultimo accesso: ${response.statusCode}');
        print('Dettagli errore: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Errore nella chiamata updateLastAccess: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // Aggiungi questo metodo per testare le notifiche
  Future<void> sendTestNotification() async {
    try {
      final token = await _firebaseMessaging.getToken();
      print('Invio notifica di test usando token: ${token?.substring(0, 10)}...');
      
      if (token == null) {
        print('Token FCM non disponibile');
        return;
      }

      final response = await http.post(
        Uri.parse('http://167.99.131.91:3000/send_test_notification'),  // Usa l'IP del tuo server
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': token,
          'title': 'Test Notifica',
          'body': 'Questa è una notifica di test'
        }),
      );

      print('Risposta server notifica: ${response.statusCode}');
      print('Corpo risposta: ${response.body}');
    } catch (e) {
      print('Errore invio notifica test: $e');
    }
  }
}