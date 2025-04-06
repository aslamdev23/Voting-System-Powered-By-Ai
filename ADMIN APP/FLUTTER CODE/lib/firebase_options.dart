import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
            'DefaultFirebaseOptions have not been configured for Linux.');
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCOzqhbfBEGCg3V0ID-dRdlrHmcfcBN8rM',
    appId: '1:232619754281:web:da66cc7d0e0205d690ad38',
    messagingSenderId: '232619754281',
    projectId: 'voting-1da7b',
    authDomain: 'voting-1da7b.firebaseapp.com',
    databaseURL:
        'https://voting-1da7b-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'voting-1da7b.firebasestorage.app',
    measurementId: 'G-MQR5GRK114',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCMpsTz3-7w3MQfOK9nuInGVFl42DbtMb4',
    appId: '1:232619754281:android:392475a63e485a7190ad38',
    messagingSenderId: '232619754281',
    projectId: 'voting-1da7b',
    databaseURL:
        'https://voting-1da7b-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'voting-1da7b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDxr9PzilVRIgMu68CUpLCumU1Uu_hQAbI',
    appId: '1:232619754281:ios:68b89550dad17d6a90ad38',
    messagingSenderId: '232619754281',
    projectId: 'voting-1da7b',
    databaseURL:
        'https://voting-1da7b-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'voting-1da7b.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication2',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDxr9PzilVRIgMu68CUpLCumU1Uu_hQAbI',
    appId: '1:232619754281:ios:68b89550dad17d6a90ad38',
    messagingSenderId: '232619754281',
    projectId: 'voting-1da7b',
    databaseURL:
        'https://voting-1da7b-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'voting-1da7b.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication2',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCOzqhbfBEGCg3V0ID-dRdlrHmcfcBN8rM',
    appId: '1:232619754281:web:f5816be66577ad3790ad38',
    messagingSenderId: '232619754281',
    projectId: 'voting-1da7b',
    authDomain: 'voting-1da7b.firebaseapp.com',
    databaseURL:
        'https://voting-1da7b-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'voting-1da7b.firebasestorage.app',
    measurementId: 'G-2FY8TFVDKB',
  );
}
