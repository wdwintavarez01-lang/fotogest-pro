import 'package:cloud_firestore/cloud_firestore.dart';
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
      _enableOfflinePersistence();

      return true;
    } on UnsupportedError {
      return false;
    } on FirebaseException catch (error) {
      if (error.code == 'duplicate-app') {
        _enableOfflinePersistence();
        return true;
      }
      return false;
    }
  }

  /// Activa la cache local de Cloud Firestore.
  ///
  /// Con la persistencia habilitada, las consultas hechas con `get()` se
  /// responden desde la cache del dispositivo cuando no hay conexion, y las
  /// escrituras quedan en cola hasta que la conexion se restablece. Esto
  /// sustituye el uso de datos de ejemplo cargados en el codigo.
  static void _enableOfflinePersistence() {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  String collectionPath(String collectionName) => collectionName;
}
