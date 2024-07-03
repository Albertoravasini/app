import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBgjfPlIqi9mC5G2andI6SmPoSH02IvA5E',
    appId: '1:771313118088:web:9cfdf09e915575da35a83d',
    messagingSenderId: '771313118088',
    projectId: 'app-just-learn',
    authDomain: 'app-just-learn.firebaseapp.com',
    storageBucket: 'app-just-learn.appspot.com',
    measurementId: 'G-85R7W075FY',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBCjoxjtorOADx1oWdcCmoIO3xT-rjMkB4',
    appId: '1:771313118088:android:cc00ee9377cbe94e35a83d',
    messagingSenderId: '771313118088',
    projectId: 'app-just-learn',
    storageBucket: 'app-just-learn.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAleC0c6hhhDtE3jcKF7tMxZLVuw-W5ymQ',
    appId: '1:771313118088:ios:baf963592ec082b935a83d',
    messagingSenderId: '771313118088',
    projectId: 'app-just-learn',
    storageBucket: 'app-just-learn.appspot.com',
    iosBundleId: 'com.example.justlearn',
  );
}