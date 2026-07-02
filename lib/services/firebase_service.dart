import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class FirebaseService {
  const FirebaseService();

  static Future<bool> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      return true;
    } on UnsupportedError {
      return false;
    } on FirebaseException catch (error) {
      if (error.code == 'duplicate-app') return true;
      return false;
    }
  }

  String collectionPath(String collectionName) => collectionName;
}
