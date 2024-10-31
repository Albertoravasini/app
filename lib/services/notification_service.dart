// notification_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:Just_Learn/main.dart';  // Importa il main per accedere al navigatorKey

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Inizializza il servizio di notifiche push
  Future<void> initialize() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('Permessi notifiche: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permesso per le notifiche concesso');

      // Ottieni il token FCM e gestiscilo
      _getToken();

      // Gestisci le notifiche quando l'app è in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showForegroundNotification(message);
      });

      // Gestisci le notifiche quando l'app è in background o aperta tramite notifica
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Notifica aperta dall\'utente: ${message.notification?.title}');
        // Puoi aggiungere logica per navigare a una schermata specifica
      });
    } else {
      print('Permesso per le notifiche negato dall\'utente');
    }
  }

  // Ottenere il token FCM e inviarlo al server
  void _getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print("FCM Token: $token");

      if (token != null) {
        String uid = FirebaseAuth.instance.currentUser?.uid ?? "ID_UNICO_DEFAULT";  // Usa UID dell'utente autenticato o un valore di default
        await updateLastAccess(uid, token);
      }
    } catch (e) {
      print("Error getting FCM token: $e");
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
    final url = Uri.parse('http://167.99.131.91:3000/update_last_access');  // 10.0.2.2 per emulatore Android

    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'uid': uid,
        'fcmToken': fcmToken,
      }),
    );

    if (response.statusCode == 200) {
      print('Ultimo accesso aggiornato correttamente');
    } else {
      print('Errore nell\'aggiornare l\'ultimo accesso: ${response.statusCode}');
    }
  }
}