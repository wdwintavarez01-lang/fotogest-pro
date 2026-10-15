import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fotogest_pro/repositories/fotogest_repository.dart';
import 'package:fotogest_pro/viewmodels/fotogest_view_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const stage = String.fromEnvironment('STAGE');
  testWidgets(
    'I02 reinicio real Android $stage',
    (tester) async {
      expect(['PREPARAR', 'RECUPERAR'].contains(stage), true);
      if (stage == 'RECUPERAR') {
        debugPrint('FOTOGEST_OFFLINE_START');
        await Future<void>.delayed(const Duration(seconds: 5));
      }
      final app = await Firebase.initializeApp(
        name: 'fotogest-restart',
        options: const FirebaseOptions(
          apiKey: 'demo-key',
          appId: '1:123:android:restart',
          messagingSenderId: '123',
          projectId: 'demo-fotogest',
        ),
      );
      final auth = FirebaseAuth.instanceFor(app: app);
      await auth.useAuthEmulator('10.0.2.2', 9099);
      await auth.authStateChanges().first;
      final db = FirebaseFirestore.instanceFor(app: app);
      db.settings = const Settings(persistenceEnabled: false);
      db.useFirestoreEmulator('10.0.2.2', 8085);
      final repo = FotogestRepository.forFirebase(firestore: db, auth: auth);
      final vm = FotogestViewModel(repo);
      if (stage == 'PREPARAR') {
        await auth.createUserWithEmailAndPassword(
          email:
              'restart_${DateTime.now().microsecondsSinceEpoch}@example.test',
          password: 'PruebaLocal123!',
        );
        expect(await vm.loadRemoteData(), true);
        expect(
          await vm.addClient(
            name: 'Confirmado antes de cierre',
            phone: '8095550100',
          ),
          true,
        );
        debugPrint('FOTOGEST_OFFLINE_START');
        await Future<void>.delayed(const Duration(seconds: 5));
        await db.disableNetwork();
        expect(
          await vm.addClient(
            name: 'Pendiente antes de cierre',
            phone: '8095550101',
          ),
          false,
        );
        expect(vm.pendingCount, 1);
        // El proceso termina conservando la sesion y el journal del dispositivo.
        debugPrint('REINICIO_PREPARADO_CON_UN_PENDIENTE');
      } else {
        expect(
          auth.currentUser,
          isNotNull,
          reason: 'Firebase debe restaurar la sesion sin autenticar por red.',
        );
        await db.disableNetwork();
        expect(await vm.loadRemoteData(), true);
        expect(vm.clients, hasLength(2));
        expect(vm.pendingCount, 1);
        expect(vm.offlineSession, true);
        expect(
          vm.clients.any((c) => c.name == 'Pendiente antes de cierre'),
          true,
        );
        debugPrint('FOTOGEST_ONLINE_START');
        await Future<void>.delayed(const Duration(seconds: 5));
        await db.enableNetwork();
        await vm.synchronize();
        expect(vm.syncError, isNull);
        expect(vm.pendingCount, 0);
        final uid = auth.currentUser!.uid;
        final docs = await db
            .collection('clientes')
            .where('usuarioId', isEqualTo: uid)
            .get(const GetOptions(source: Source.server));
        expect(docs.docs, hasLength(2));
        expect(
          docs.docs.where((d) => d['nombre'] == 'Pendiente antes de cierre'),
          hasLength(1),
        );
        await vm.signOut();
        expect(vm.clients, isEmpty);
        // Una segunda cuenta no recibe la cache ni los pendientes de la primera.
        await auth.createUserWithEmailAndPassword(
          email: 'otra_${DateTime.now().microsecondsSinceEpoch}@example.test',
          password: 'PruebaLocal123!',
        );
        final other = FotogestViewModel(
          FotogestRepository.forFirebase(firestore: db, auth: auth),
        );
        expect(await other.loadRemoteData(), true);
        expect(other.clients, isEmpty);
        expect(other.pendingCount, 0);
        await other.signOut();
        other.dispose();
        debugPrint('REINICIO_RECUPERADO_SIN_DUPLICADOS_Y_CUENTAS_AISLADAS');
      }
      vm.dispose();
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
