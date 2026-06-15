import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class MeetGridFirebaseConfig {
  const MeetGridFirebaseConfig._();

  static const apiKey = 'AIzaSyC6jLzQHQ2w0-S2e63SmW8TCBbH50f_tNg';
  static const projectId = 'meetgrid-ebd98';
  static const messagingSenderId = '411746177907';
  static const storageBucket = 'meetgrid-ebd98.firebasestorage.app';
  static const iosBundleId = 'jwlee.MeetGrid';
  static const iosAppId = '1:411746177907:ios:a7301192976468b4bd6b06';
  static const iosClientId =
      '411746177907-0tptp4s8jge60q6mgrj44h6ejlhsk5if.apps.googleusercontent.com';
  static const reversedClientId =
      'com.googleusercontent.apps.411746177907-0tptp4s8jge60q6mgrj44h6ejlhsk5if';
  static const androidClientId =
      '411746177907-ob7r3vc023uk840cbdj3otosd3j5ssf9.apps.googleusercontent.com';
  static const androidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');

  static FirebaseOptions get currentOptions {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return const FirebaseOptions(
        apiKey: apiKey,
        appId: iosAppId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: storageBucket,
        iosBundleId: iosBundleId,
        iosClientId: iosClientId,
      );
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      if (androidAppId.isEmpty) {
        throw UnsupportedError('Android Firebase app id is not configured.');
      }
      return const FirebaseOptions(
        apiKey: apiKey,
        appId: androidAppId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: storageBucket,
        androidClientId: androidClientId,
      );
    }

    return const FirebaseOptions(
      apiKey: apiKey,
      appId: iosAppId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: storageBucket,
      iosBundleId: iosBundleId,
      iosClientId: iosClientId,
    );
  }
}
