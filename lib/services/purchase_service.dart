import 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class PurchaseService {
  // Chiavi API di RevenueCat
  static const String _apiKeyIOS = 'appl_BnISKxsimQBUpioTfnyWehngrIE';
  static const String _apiKeyAndroid = 'goog_IyJwhhhXOkFDEtzACKvyWROhxzn';
  
  // ID dei prodotti RevenueCat (aggiornati in base ai log)
  static const String _monthlyId = '\$rc_monthly';
  static const String _threeMonthId = '\$rc_three_month';
  
  // ID dell'entitlement
  static const String _entitlementId = 'premium';

  static Future<void> init() async {
    try {
      await Purchases.setLogLevel(LogLevel.verbose);
      print('DEBUG: Inizializzazione RevenueCat...');
      
      // Seleziona la chiave API corretta in base alla piattaforma
      final apiKey = Platform.isIOS ? _apiKeyIOS : _apiKeyAndroid;
      
      final configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);
      print('DEBUG: RevenueCat configurato con successo per ${Platform.isIOS ? 'iOS' : 'Android'}');
      
      // Test della configurazione
      final offerings = await Purchases.getOfferings();
      print('DEBUG: Test configurazione:');
      print('- API Key: $apiKey');
      print('- Offerings disponibili: ${offerings.all.length}');
      print('- Current offering: ${offerings.current?.identifier}');
      
      if (offerings.current != null) {
        print('DEBUG: Pacchetti nell\'offering corrente:');
        for (var package in offerings.current!.availablePackages) {
          print('- Package: ${package.identifier}');
          print('  Product: ${package.storeProduct.identifier}');
          print('  Price: ${package.storeProduct.priceString}');
        }
      }
    } catch (e) {
      print('DEBUG: ERRORE durante l\'inizializzazione: $e');
      if (e is PlatformException) {
        print('DEBUG: Error code: ${e.code}');
        print('DEBUG: Error message: ${e.message}');
        print('DEBUG: Error details: ${e.details}');
      }
    }
  }

  static Future<CustomerInfo> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      print('Errore nel recupero delle info cliente: $e');
      rethrow;
    }
  }

  static Future<List<Offering>> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.current;
      return offering != null ? [offering] : [];
    } catch (e) {
      print('Errore nel recupero delle offerte: $e');
      rethrow;
    }
  }

  static Future<CustomerInfo> purchasePackage(Package package) async {
    try {
      print('DEBUG: Inizio processo di acquisto per pacchetto: ${package.identifier}');
      print('DEBUG: Dettagli prodotto: ${package.storeProduct.identifier}');
      
      // Verifica se l'utente può effettuare acquisti
      final canMakePurchases = await Purchases.canMakePayments();
      if (!canMakePurchases) {
        throw PlatformException(
          code: 'PAYMENTS_NOT_ALLOWED',
          message: 'L\'utente non può effettuare acquisti',
        );
      }

      // Tenta l'acquisto
      final purchaseResult = await Purchases.purchasePackage(package);
      
      print('DEBUG: Acquisto completato con successo');
      print('DEBUG: Entitlements attivi: ${purchaseResult.entitlements.active.keys}');
      
      return purchaseResult;
    } on PlatformException catch (e) {
      print('DEBUG: Dettagli errore PlatformException:');
      print('- Codice: ${e.code}');
      print('- Messaggio: ${e.message}');
      print('- Dettagli: ${e.details}');
      
      if (e.details != null && e.details!['userCancelled'] == true) {
        print('DEBUG: Acquisto cancellato dall\'utente');
        throw Exception('Acquisto cancellato');
      } else if (e.code == 'PAYMENTS_NOT_ALLOWED') {
        throw Exception('Acquisti non consentiti su questo dispositivo');
      }
      rethrow;
    } catch (e) {
      print('DEBUG: Errore generico durante l\'acquisto: $e');
      rethrow;
    }
  }

  static bool isProUser(CustomerInfo customerInfo) {
    return customerInfo.entitlements.active.containsKey(_entitlementId);
  }

  static Package? getPackageForPlan(Offering offering, String planType) {
    try {
      return offering.availablePackages.firstWhere(
        (package) => planType == 'monthly' 
          ? package.identifier == _monthlyId
          : package.identifier == _threeMonthId,
        orElse: () => offering.availablePackages.first,
      );
    } catch (e) {
      print('DEBUG: Errore nella selezione del pacchetto: $e');
      return null;
    }
  }

  static Future<bool> checkSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return isProUser(customerInfo);
    } catch (e) {
      print('DEBUG: Errore verifica abbonamento: $e');
      return false;
    }
  }

  static Future<void> setupSubscriptionMonitoring() async {
    try {
      // Verifica se Firebase è già inizializzato
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      
      Purchases.addCustomerInfoUpdateListener((customerInfo) async {
        final isPro = isProUser(customerInfo);
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'isPro': isPro});
        }
      });
    } catch (e) {
      print('DEBUG: Errore setup monitoraggio: $e');
    }
  }
} 