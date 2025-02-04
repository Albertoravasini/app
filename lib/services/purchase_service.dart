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
  static const String _threeMonthId = '\$rc_six_month';
  
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
      final canMakePurchases = await Purchases.canMakePayments();
      if (!canMakePurchases) {
        throw PlatformException(
          code: 'PAYMENTS_NOT_ALLOWED',
          message: 'L\'utente non può effettuare acquisti',
        );
      }

      final purchaseResult = await Purchases.purchasePackage(package);
      
      // Registra i dettagli dell'acquisto
      await handlePurchaseIdentity(purchaseResult);
      
      return purchaseResult;
    } catch (e) {
      print('DEBUG: Errore durante l\'acquisto: $e');
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

  static Future<void> setupUserIdentity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await Purchases.setAttributes({
        'firebase_uid': user.uid,      // ID univoco Firebase
        'auth_provider': user.providerData.first.providerId,  // 'password', 'google.com', 'apple.com'
        'email': user.email ?? '',
      });
    }
  }

  static Future<void> handlePurchaseIdentity(CustomerInfo customerInfo) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('purchases')
            .add({
          'purchaseDate': DateTime.now().toIso8601String(),
          'provider': customerInfo.originalPurchaseDate,
          'productIdentifier': customerInfo.entitlements.active[_entitlementId]?.productIdentifier,
          'willRenew': customerInfo.entitlements.active[_entitlementId]?.willRenew,
          'expirationDate': customerInfo.entitlements.active[_entitlementId]?.expirationDate,
          'authProvider': user.providerData.first.providerId,
          'userEmail': user.email,
        });
      }
    } catch (e) {
      print('DEBUG: Errore registrazione acquisto: $e');
    }
  }
} 