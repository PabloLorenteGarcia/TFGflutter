import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default Firebase configuration options for the app
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
    apiKey: 'AIzaSyDm7mtgKKki3AKRYVDnH4K8z9YifYep7oo',
    appId: '1:891140578455:web:6a55b20f9ac18ff8baddd2',
    messagingSenderId: '891140578455',
    projectId: 'tfgplantas',
    authDomain: 'tfgplantas.firebaseapp.com',
    storageBucket: 'tfgplantas.firebasestorage.app',
    measurementId: 'G-V2TB5QKNM1',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDm7mtgKKki3AKRYVDnH4K8z9YifYep7oo',
    appId: '1:891140578455:android:6a55b20f9ac18ff8baddd2',
    messagingSenderId: '891140578455',
    projectId: 'tfgplantas',
    authDomain: 'tfgplantas.firebaseapp.com',
    storageBucket: 'tfgplantas.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDm7mtgKKki3AKRYVDnH4K8z9YifYep7oo',
    appId: '1:891140578455:ios:6a55b20f9ac18ff8baddd2',
    messagingSenderId: '891140578455',
    projectId: 'tfgplantas',
    authDomain: 'tfgplantas.firebaseapp.com',
    storageBucket: 'tfgplantas.firebasestorage.app',
    iosClientId: '891140578455-apps.googleusercontent.com',
    iosBundleId: 'com.example.plantcare',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDm7mtgKKki3AKRYVDnH4K8z9YifYep7oo',
    appId: '1:891140578455:ios:6a55b20f9ac18ff8baddd2',
    messagingSenderId: '891140578455',
    projectId: 'tfgplantas',
    authDomain: 'tfgplantas.firebaseapp.com',
    storageBucket: 'tfgplantas.firebasestorage.app',
    iosClientId: '891140578455-apps.googleusercontent.com',
    iosBundleId: 'com.example.plantcare',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDm7mtgKKki3AKRYVDnH4K8z9YifYep7oo',
    appId: '1:891140578455:windows:6a55b20f9ac18ff8baddd2',
    messagingSenderId: '891140578455',
    projectId: 'tfgplantas',
    authDomain: 'tfgplantas.firebaseapp.com',
    storageBucket: 'tfgplantas.firebasestorage.app',
  );
}