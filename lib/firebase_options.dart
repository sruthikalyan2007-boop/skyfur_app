// File generated for Skyfur Firebase configuration.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for Skyfur.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        // Using web configuration as fallback for desktop/mobile unless platform-specific credentials are provided
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDe-hTxOl6MWAuZ5_d9Oekngat0Oa3H83g',
    appId: '1:194752222089:web:d51be4753fc1634c50c758',
    messagingSenderId: '194752222089',
    projectId: 'skyfur-eac18',
    authDomain: 'skyfur-eac18.firebaseapp.com',
    storageBucket: 'skyfur-eac18.firebasestorage.app',
    measurementId: 'G-EDQD14GHGH',
  );
}
