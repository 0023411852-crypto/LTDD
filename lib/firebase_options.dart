// File generated manually based on google-services.json for project linh-4782e
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDWj_W4FV8MDor4Gx9kpIhZQezxjxgEnjQ',
    appId: '1:650149107566:android:77393474d6a991606e937f',
    messagingSenderId: '650149107566',
    projectId: 'linh-4782e',
    databaseURL: 'https://linh-4782e-default-rtdb.firebaseio.com',
    storageBucket: 'linh-4782e.firebasestorage.app',
  );
}
