import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult({required this.isReady, this.message});

  const FirebaseBootstrapResult.ready() : isReady = true, message = null;

  const FirebaseBootstrapResult.unconfigured(this.message) : isReady = false;

  final bool isReady;
  final String? message;
}

class FirebaseService {
  static Future<FirebaseBootstrapResult>? _initializationFuture;

  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  static Future<FirebaseBootstrapResult> initialize() {
    return _initializationFuture ??= _initializeInternal();
  }

  static Future<FirebaseBootstrapResult> _initializeInternal() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        return const FirebaseBootstrapResult.ready();
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      return const FirebaseBootstrapResult.ready();
    } on FirebaseException catch (error) {
      return FirebaseBootstrapResult.unconfigured(
        'Firebase could not start: ${error.message ?? error.code}. '
        'Verify the Zeppo Firebase project configuration and try again.',
      );
    } catch (error) {
      return FirebaseBootstrapResult.unconfigured(
        'Firebase could not start: $error',
      );
    }
  }
}
