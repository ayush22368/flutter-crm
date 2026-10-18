import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Configured for project `crm-flutter-5fb01`.
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
    apiKey: 'AIzaSyC8ui7BnWsK3_jRm78mWOCemlnVfgQ6H8g',
    appId: '1:592371721464:web:0b9191b2732dc7b5be070d',
    messagingSenderId: '592371721464',
    projectId: 'crm-flutter-5fb01',
    authDomain: 'crm-flutter-5fb01.firebaseapp.com',
    storageBucket: 'crm-flutter-5fb01.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC8ui7BnWsK3_jRm78mWOCemlnVfgQ6H8g',
    appId: '1:592371721464:android:0b9191b2732dc7b5be070d',
    messagingSenderId: '592371721464',
    projectId: 'crm-flutter-5fb01',
    storageBucket: 'crm-flutter-5fb01.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC8ui7BnWsK3_jRm78mWOCemlnVfgQ6H8g',
    appId: '1:592371721464:ios:0b9191b2732dc7b5be070d',
    messagingSenderId: '592371721464',
    projectId: 'crm-flutter-5fb01',
    storageBucket: 'crm-flutter-5fb01.firebasestorage.app',
    iosBundleId: 'com.example.fluttercrm',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC8ui7BnWsK3_jRm78mWOCemlnVfgQ6H8g',
    appId: '1:592371721464:ios:0b9191b2732dc7b5be070d',
    messagingSenderId: '592371721464',
    projectId: 'crm-flutter-5fb01',
    storageBucket: 'crm-flutter-5fb01.firebasestorage.app',
    iosBundleId: 'com.example.fluttercrm',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC8ui7BnWsK3_jRm78mWOCemlnVfgQ6H8g',
    appId: '1:592371721464:web:0b9191b2732dc7b5be070d',
    messagingSenderId: '592371721464',
    projectId: 'crm-flutter-5fb01',
    authDomain: 'crm-flutter-5fb01.firebaseapp.com',
    storageBucket: 'crm-flutter-5fb01.firebasestorage.app',
  );
}
