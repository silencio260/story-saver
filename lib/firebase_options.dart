// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: const String.fromEnvironment("firebase_api_key_android"),
    appId: '1:213655052172:android:12c2a49a24bb5eca48c0a9',
    messagingSenderId: '213655052172',
    projectId: 'whatsapp-status-saver-fl-6c420',
    storageBucket: 'whatsapp-status-saver-fl-6c420.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: const String.fromEnvironment("firebase_api_key_ios"),
    appId: '1:213655052172:ios:debca4eacac328aa48c0a9',
    messagingSenderId: '213655052172',
    projectId: 'whatsapp-status-saver-fl-6c420',
    storageBucket: 'whatsapp-status-saver-fl-6c420.firebasestorage.app',
    iosBundleId: 'com.faruq.storysaver',
  );

}