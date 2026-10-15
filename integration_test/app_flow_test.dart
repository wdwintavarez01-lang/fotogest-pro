import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fotogest_pro/main.dart';
import 'package:fotogest_pro/repositories/fotogest_repository.dart';
import 'package:fotogest_pro/viewmodels/fotogest_view_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'I01 recorrido Android con Firebase local y recuperacion offline',
    (tester) async {
      final app = await Firebase.initializeApp(
        name: 'fotogest-test',
        options: const FirebaseOptions(
          apiKey: 'demo-key',
          appId: '1:123:android:demo',
          messagingSenderId: '123',
          projectId: 'demo-fotogest',
        ),
      );
      final auth = FirebaseAuth.instanceFor(app: app);
      await auth.useAuthEmulator('10.0.2.2', 9099);
      final db = FirebaseFirestore.instanceFor(app: app);
      db.settings = const Settings(persistenceEnabled: false);
      db.useFirestoreEmulator('10.0.2.2', 8085);
      expect(db.app.options.projectId, 'demo-fotogest');
      await auth.createUserWithEmailAndPassword(
        email: 'android_${DateTime.now().microsecondsSinceEpoch}@example.test',
        password: 'PruebaLocal123!',
      );
      FotogestRepository open() =>
          FotogestRepository.forFirebase(firestore: db, auth: auth);
      var repo = open();
      var vm = FotogestViewModel(repo);
      expect(await vm.loadRemoteData(), true);
      expect(
        await vm.addClient(name: 'Cliente Android', phone: '8095550123'),
        true,
      );
      expect(
        await vm.addPackage(
          name: 'Servicio Android',
          description: 'Prueba local',
          price: 1000,
        ),
        true,
      );
      final clientId = vm.clients.single.id;
      final packageId = vm.packages.single.id;
      expect(
        await vm.addEvent(
          clientId: clientId,
          packageId: packageId,
          type: 'Retrato',
          dateTime: DateTime.now(),
          location: 'Estudio',
          status: 'programado',
          agreedAmount: 1000,
        ),
        true,
      );
      final eventId = vm.events.single.id;
      expect(
        await vm.addPayment(
          eventId: eventId,
          amount: 300,
          method: 'efectivo',
          paidAt: DateTime.now(),
        ),
        true,
      );
      expect(vm.pendingForEvent(eventId), 700);
      await expectLater(
        vm.addPayment(
          eventId: eventId,
          amount: 701,
          method: 'efectivo',
          paidAt: DateTime.now(),
        ),
        throwsStateError,
      );
      await expectLater(vm.deleteEvent(eventId), throwsStateError);
      final saleResult = await vm.addSale(
        clientId: clientId,
        type: 'impresion',
        description: 'Cinco impresiones',
        quantity: 5,
        unitPrice: 20,
        soldAt: DateTime.now(),
        status: 'pendiente',
      );
      expect(saleResult.savedRemotely, true);
      expect(
        await vm.addPayment(
          saleId: saleResult.sale.id,
          amount: 100,
          method: 'transferencia',
          paidAt: DateTime.now(),
        ),
        true,
      );
      expect(vm.paidSales.single.id, saleResult.sale.id);
      await vm.updatePackage(
        package: vm.packages.single,
        name: 'Servicio Android',
        description: 'Nuevo precio',
        price: 1500,
        active: true,
      );
      expect(vm.amountForEvent(eventId), 1000);
      // SDK offline: el repositorio persiste su propia cola antes de avisar pendiente.
      debugPrint('FOTOGEST_OFFLINE_START');
      await Future<void>.delayed(const Duration(seconds: 5));
      await db.disableNetwork();
      expect(
        await vm.addClient(name: 'Cliente sin red', phone: '8095550456'),
        false,
      );
      expect(vm.pendingCount, 1);
      vm.dispose();
      repo = open();
      vm = FotogestViewModel(repo);
      await vm.loadRemoteData();
      expect(vm.pendingCount, 1);
      expect(vm.clients.any((c) => c.name == 'Cliente sin red'), true);
      expect(vm.offlineSession, true);
      debugPrint('FOTOGEST_ONLINE_START');
      await Future<void>.delayed(const Duration(seconds: 5));
      await db.enableNetwork();
      await vm.synchronize();
      expect(vm.pendingCount, 0);
      expect(vm.syncError, isNull);
      final saved = await db
          .collection('clientes')
          .where('usuarioId', isEqualTo: auth.currentUser!.uid)
          .get(const GetOptions(source: Source.server));
      expect(
        saved.docs.where((d) => d['nombre'] == 'Cliente sin red'),
        hasLength(1),
      );
      // Otro dispositivo modifica la revision: se rechaza el cambio pendiente sin falso exito.
      final client = vm.clients.firstWhere((c) => c.id == clientId);
      debugPrint('FOTOGEST_OFFLINE_START');
      await Future<void>.delayed(const Duration(seconds: 5));
      await db.disableNetwork();
      expect(
        await repo.updateClient(client.copyWith(name: 'Edicion pendiente')),
        false,
      );
      debugPrint('FOTOGEST_ONLINE_START');
      await Future<void>.delayed(const Duration(seconds: 5));
      await db.enableNetwork();
      final ref = db.collection('clientes').doc(clientId);
      final original = await ref.get();
      await ref.update({
        'nombre': 'Edicion de otro dispositivo',
        'revision': (original.data()!['revision'] as int) + 1,
      });
      await vm.synchronize();
      expect(vm.syncError, isNotNull);
      expect(
        vm.clients.firstWhere((c) => c.id == clientId).name,
        'Edicion de otro dispositivo',
      );
      await vm.discardPending();
      expect(vm.pendingCount, 0);
      await tester.pumpWidget(
        FotoGestApp(firebaseReady: true, repository: repo),
      );
      await tester.pumpAndSettle();
      expect(find.text('Resumen'), findsOneWidget);
      debugPrint('FOTOGEST_CAPTURE_RESUMEN');
      await Future<void>.delayed(const Duration(seconds: 2));
      expect(find.textContaining('Sincronizacion:'), findsOneWidget);
      // Navegacion y estados vacios de todas las listas principales.
      for (final route in [
        '/clients',
        '/packages',
        '/events',
        '/sales',
        '/payments',
      ]) {
        final ctx = tester.element(find.byType(Scaffold).first);
        Navigator.of(ctx).pushNamed(route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        debugPrint('FOTOGEST_CAPTURE_${route.substring(1).toUpperCase()}');
        await Future<void>.delayed(const Duration(seconds: 2));
        Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
        await tester.pumpAndSettle();
      }
      await vm.signOut();
      expect(vm.clients, isEmpty);
      expect(vm.hasSession, false);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      vm.dispose();
      await app.delete();
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
