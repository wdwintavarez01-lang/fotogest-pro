import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/client.dart';
import '../models/payment.dart';
import '../models/photo_event.dart';
import '../models/photo_package.dart';
import '../models/photo_sale.dart';
import 'pending_journal.dart';

/// Unico acceso a Firebase. La cola, cache y sesion se separan por UID.
class FotogestRepository {
  FotogestRepository()
    : _firestore = null,
      _auth = null,
      _allowMemoryWrites = false;
  FotogestRepository.memoryForTesting()
    : _firestore = null,
      _auth = null,
      _allowMemoryWrites = true;
  FotogestRepository._firebase(this._firestore, this._auth)
    : _allowMemoryWrites = false;
  factory FotogestRepository.firebase() => FotogestRepository._firebase(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );

  /// Permite conectar clientes de emulador en las pruebas de integracion.
  factory FotogestRepository.forFirebase({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) => FotogestRepository._firebase(firestore, auth);

  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;
  final bool _allowMemoryWrites;
  PendingJournal? _journal;
  String? _journalUser;
  Future<void> _tail = Future.value();
  bool fromCache = false;
  bool get hasFirebase => _firestore != null;
  bool get lastSignInWasOffline => fromCache;
  String get currentUserId => _auth?.currentUser?.uid ?? '';
  String get currentUserEmail => _auth?.currentUser?.email ?? '';
  bool get hasSession => currentUserId.isNotEmpty;
  int get pendingCount => _journal?.pending.length ?? 0;
  String? get syncError => _journal?.rejection;

  final Map<String, Map<String, dynamic>> _memory = {};
  Map<String, Map<String, dynamic>> get _visible =>
      _journal?.visible ?? _memory;
  List<T> _rows<T>(
    String collection,
    T Function(String, Map<String, dynamic>) read, {
    bool includeDeleted = false,
  }) => [
    for (final entry in _visible.entries)
      if (entry.key.startsWith('$collection/') &&
          (includeDeleted || entry.value['eliminado'] != true))
        read(entry.key.substring(collection.length + 1), entry.value),
  ];

  List<AppUser> getUsers() => [
    if (hasSession)
      AppUser(
        id: currentUserId,
        name: currentUserEmail,
        email: currentUserEmail,
        role: 'fotografo',
        active: true,
      ),
  ];
  List<Client> getClients() =>
      _rows('clientes', _clientFromDoc)..sort(_sortByClientId);
  List<Client> getAllClients() =>
      _rows('clientes', _clientFromDoc, includeDeleted: true);
  List<PhotoPackage> getPackages() =>
      _rows('paquetes', _packageFromDoc)..sort(_sortByPackageId);
  List<PhotoPackage> getAllPackages() =>
      _rows('paquetes', _packageFromDoc, includeDeleted: true);
  List<PhotoEvent> getEvents() =>
      _rows('eventos', _eventFromDoc)..sort(_sortByEventDate);
  List<PhotoSale> getSales() =>
      _rows('ventas', _saleFromDoc)..sort(_sortBySaleDate);
  List<Payment> getPayments() =>
      _rows('pagos', _paymentFromDoc)..sort(_sortByPaymentDate);

  Future<T> _exclusive<T>(Future<T> Function() work) {
    final result = _tail.then((_) => work());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> _openJournal() async {
    if (!hasFirebase || !hasSession) return;
    if (_journalUser == currentUserId) return;
    final uid = currentUserId;
    final prefs = await SharedPreferences.getInstance();
    final key = 'fotogest_journal_v1_$uid';
    final journal = PendingJournal(
      persist: (value) async {
        if (!await prefs.setString(key, value)) {
          throw StateError('No se pudo guardar en el dispositivo.');
        }
      },
      send: _send,
    );
    journal.restore(prefs.getString(key));
    _journal = journal;
    _journalUser = uid;
  }

  Future<bool> signIn(String email, String password) async {
    final auth = _auth;
    if (auth == null) return false;
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Elimina el antiguo acceso por hash: solo Firebase conserva la sesion.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fotogest_cached_email');
    await prefs.remove('fotogest_cached_password_hash');
    await _openJournal();
    return true;
  }

  Future<void> signOut() => _exclusive(() async {
    await _auth?.signOut();
    clearLocalData();
  });
  void clearLocalData() {
    _journal = null;
    _journalUser = null;
    _memory.clear();
    fromCache = false;
  }

  Future<bool> loadRemoteData() => _exclusive(() async {
    if (!hasFirebase || !hasSession) return false;
    await _openJournal();
    final uid = currentUserId;
    final result = <String, Map<String, dynamic>>{};
    try {
      final snapshots = await Future.wait([
        for (final name in [
          'clientes',
          'paquetes',
          'eventos',
          'ventas',
          'pagos',
        ])
          _firestore!
              .collection(name)
              .where('usuarioId', isEqualTo: uid)
              .get(const GetOptions(source: Source.server)),
      ]).timeout(const Duration(seconds: 10));
      for (var i = 0; i < snapshots.length; i++) {
        final collection = [
          'clientes',
          'paquetes',
          'eventos',
          'ventas',
          'pagos',
        ][i];
        for (final doc in snapshots[i].docs) {
          result['$collection/${doc.id}'] = _serializable(doc.data());
        }
      }
      await _firestore!.runTransaction(
        (transaction) async {
          final ref = _firestore.collection('usuarios').doc(uid);
          final profile = await transaction.get(ref);
          if (!profile.exists) {
            transaction.set(ref, {
              'usuarioId': uid,
              'nombre': currentUserEmail,
              'email': currentUserEmail,
              'rol': 'fotografo',
              'activo': true,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        },
        timeout: const Duration(seconds: 12),
        maxAttempts: 3,
      );
      _journal!.confirmed = result;
      await _journal!.save();
      fromCache = false;
      await _journal!.sync();
      return true;
    } on TimeoutException {
      fromCache = true;
      return _journal!.confirmed.isNotEmpty || pendingCount > 0;
    } on FirebaseException catch (error) {
      if (!_connectivity(error.code)) rethrow;
      fromCache = true;
      return _journal!.confirmed.isNotEmpty || pendingCount > 0;
    }
  });

  Future<void> synchronize({bool retry = false}) => _exclusive(() async {
    await _openJournal();
    await _journal?.sync(retry: retry);
  });
  Future<void> discardPending() => _exclusive(() async {
    await _journal?.discardPending();
  });

  static String newId(String prefix) {
    final random = Random.secure();
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${random.nextInt(1 << 32).toRadixString(16)}';
  }

  static bool _connectivity(String code) => [
    'unavailable',
    'deadline-exceeded',
    'network-request-failed',
  ].contains(code);
  static Map<String, dynamic> _serializable(Map<String, dynamic> data) =>
      data.map(
        (key, value) => MapEntry(
          key,
          value is Timestamp ? value.toDate().toIso8601String() : value,
        ),
      );
  static Map<String, dynamic> _firestoreData(Map<String, dynamic> data) =>
      data.map(
        (key, value) => MapEntry(
          key,
          [
                    'fechaHora',
                    'fechaVenta',
                    'fechaPago',
                    'createdAt',
                    'updatedAt',
                  ].contains(key) &&
                  value is String
              ? Timestamp.fromDate(DateTime.parse(value))
              : value,
        ),
      );

  Future<bool> _write(
    String collection,
    String id,
    Map<String, dynamic> data,
    String kind,
  ) => _exclusive(() async {
    if (!hasFirebase && !_allowMemoryWrites) {
      throw StateError(
        'Firebase no esta disponible. Reinicia la app antes de guardar.',
      );
    }
    await _openJournal();
    if (hasFirebase && !hasSession) {
      throw StateError('Inicia sesion para guardar.');
    }
    if (hasFirebase && _journal!.rejection != null) {
      throw StateError('Resuelve los cambios rechazados desde Sincronizacion.');
    }
    final path = '$collection/$id';
    final previous = _visible[path];
    if (kind != 'create' && previous == null) {
      throw StateError('Registro no encontrado. Actualiza los datos.');
    }
    final payload = {
      ...?previous,
      ...data,
      'usuarioId': currentUserId,
      'eliminado': kind == 'delete',
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
    if (kind == 'create') {
      payload['createdAt'] = payload['updatedAt'];
      if (['eventos', 'ventas'].contains(collection)) {
        payload['totalAbonado'] = 0;
        payload['abonadoCentavos'] = 0;
      }
    }
    if (['eventos', 'ventas'].contains(collection)) {
      final field = collection == 'eventos' ? 'montoAcordado' : 'total';
      final total = payload[field] as num;
      if (!total.isFinite) throw StateError('El monto debe ser finito.');
      payload['totalCentavos'] = (total * 100).round();
      if (collection == 'ventas') {
        payload[field] = payload['totalCentavos'] / 100;
      }
    }
    if (collection == 'ventas') {
      final unit = payload['precioUnitario'] as num;
      if (!unit.isFinite) throw StateError('Precio unitario invalido.');
      payload['precioUnitarioCentavos'] = (unit * 100).round();
    }
    if (collection == 'pagos') {
      final amount = payload['monto'] as num;
      if (!amount.isFinite) throw StateError('El monto debe ser finito.');
      payload['montoCentavos'] = (amount * 100).round();
    }
    _validate(collection, payload, _visible, kind: kind);
    final operation = <String, dynamic>{
      'path': path,
      'data': payload,
      'kind': kind,
      'id': newId('op'),
      'revision': previous?['revision'] ?? 0,
    };
    if (!hasFirebase) {
      _memory[path] = {
        ...payload,
        'revision': (operation['revision'] as int) + 1,
      };
      if (collection == 'pagos') {
        final target = payload['eventoId'] != ''
            ? 'eventos/${payload['eventoId']}'
            : 'ventas/${payload['ventaId']}';
        _memory[target]!['totalAbonado'] =
            ((_memory[target]!['totalAbonado'] ?? 0) as num) +
            (payload['monto'] as num);
      }
      return false;
    }
    await _journal!.enqueue(operation);
    await _journal!.sync();
    if (_journal!.rejection != null) throw StateError(_journal!.rejection!);
    fromCache = pendingCount > 0;
    return !_journal!.pending.any((op) => op['id'] == operation['id']);
  });

  void _validate(
    String collection,
    Map<String, dynamic> data,
    Map<String, Map<String, dynamic>> records, {
    required String kind,
  }) {
    void require(bool condition, String message) {
      if (!condition) throw StateError(message);
    }

    bool amount(dynamic value, {bool positive = false}) =>
        value is num &&
        value.isFinite &&
        value <= 1000000000 &&
        (positive ? value > 0 : value >= 0) &&
        ((value * 100) - (value * 100).round()).abs() < 0.00001;
    void reference(String target, dynamic id) {
      final item = records['$target/$id'];
      require(
        item != null &&
            item['usuarioId'] == data['usuarioId'] &&
            item['eliminado'] != true,
        'El registro relacionado no existe o fue eliminado.',
      );
    }

    if (kind == 'delete') {
      require(
        ((data['totalAbonado'] ?? 0) as num) == 0,
        'Esta cuenta tiene abonos. Conserva su historial; puedes cancelarla.',
      );
      return;
    }
    if (collection == 'clientes') {
      require(
        (data['nombre'] as String).trim().length >= 3,
        'El nombre debe tener al menos 3 caracteres.',
      );
    } else if (collection == 'paquetes') {
      require(
        (data['nombre'] as String).trim().length >= 3,
        'Escribe un nombre de servicio valido.',
      );
      require(
        amount(data['precio']),
        'Precio invalido. Usa hasta dos decimales.',
      );
    } else if (collection == 'eventos' || collection == 'ventas') {
      reference('clientes', data['clienteId']);
      if (collection == 'eventos') reference('paquetes', data['paqueteId']);
      final total = collection == 'eventos'
          ? data['montoAcordado']
          : data['total'];
      require(amount(total), 'Monto invalido. Usa hasta dos decimales.');
      require(
        total >= (data['totalAbonado'] ?? 0),
        'El total no puede ser menor que los abonos.',
      );
      if (collection == 'ventas') {
        require(
          data['cantidad'] is int && data['cantidad'] > 0,
          'Cantidad invalida.',
        );
        require(amount(data['precioUnitario']), 'Precio unitario invalido.');
        require(
          (total - data['cantidad'] * data['precioUnitario']).abs() < 0.00001,
          'Total de venta invalido.',
        );
      }
    } else if (collection == 'pagos') {
      final event = data['eventoId'] as String;
      final sale = data['ventaId'] as String;
      require(
        event.isNotEmpty != sale.isNotEmpty,
        'El abono debe pertenecer a una sola cuenta.',
      );
      final target = event.isNotEmpty ? 'eventos/$event' : 'ventas/$sale';
      final account = records[target];
      require(
        account != null &&
            account['usuarioId'] == data['usuarioId'] &&
            account['eliminado'] != true &&
            account['estado'] != 'cancelado',
        'Cuenta no disponible para recibir abonos.',
      );
      require(
        amount(data['monto'], positive: true),
        'Abono invalido. Usa hasta dos decimales.',
      );
      final total =
          account![event.isNotEmpty ? 'montoAcordado' : 'total'] as num;
      final paid = (account['totalAbonado'] ?? 0) as num;
      require(
        data['monto'] <= (total - paid) + 0.000001,
        'El monto supera el saldo pendiente. Actualiza los datos.',
      );
      require(
        [
          'efectivo',
          'transferencia',
          'tarjeta',
          'otro',
        ].contains(data['metodo']),
        'Metodo de pago invalido.',
      );
    }
  }

  Future<Map<String, Map<String, dynamic>>> _send(
    Map<String, dynamic> operation,
  ) async {
    final firestore = _firestore!;
    final path = operation['path'] as String;
    final collection = path.split('/').first;
    final payload = Map<String, dynamic>.from(operation['data'] as Map);
    final reference = firestore.doc(path);
    try {
      // Evita iniciar una transaccion cuando solo hay datos de cache.
      // Este sondeo es de lectura y su timeout no deja escrituras ambiguas.
      await firestore
          .collection('usuarios')
          .doc(currentUserId)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 4));
      return await firestore.runTransaction(
        (transaction) async {
          final snapshot = await transaction.get(reference);
          final previous = snapshot.data();
          if (previous != null && previous['usuarioId'] != currentUserId) {
            throw StateError('El registro pertenece a otro usuario.');
          }
          if (previous?['operacionId'] == operation['id']) {
            final result = {path: _serializable(previous!)};
            if (collection == 'pagos') {
              final target = payload['eventoId'] != ''
                  ? 'eventos/${payload['eventoId']}'
                  : 'ventas/${payload['ventaId']}';
              final account = await transaction.get(firestore.doc(target));
              if (account.exists) {
                result[target] = _serializable(account.data()!);
              }
            }
            return result;
          }
          if ((operation['kind'] == 'create' && snapshot.exists) ||
              (operation['kind'] != 'create' &&
                  (!snapshot.exists ||
                      (previous?['revision'] ?? 0) != operation['revision']))) {
            throw StateError(
              'Otro dispositivo cambio este registro. Descarta los pendientes, actualiza y vuelve a editar.',
            );
          }
          final related = <String, Map<String, dynamic>>{};
          for (final target in [
            if (collection == 'eventos' || collection == 'ventas')
              'clientes/${payload['clienteId']}',
            if (collection == 'eventos') 'paquetes/${payload['paqueteId']}',
            if (collection == 'pagos')
              payload['eventoId'] != ''
                  ? 'eventos/${payload['eventoId']}'
                  : 'ventas/${payload['ventaId']}',
          ]) {
            final doc = await transaction.get(firestore.doc(target));
            if (doc.exists) related[target] = _serializable(doc.data()!);
          }
          final data = {
            ...?previous,
            ...payload,
            'revision': ((previous?['revision'] ?? 0) as int) + 1,
            'operacionId': operation['id'],
          };
          if (previous != null && ['eventos', 'ventas'].contains(collection)) {
            data['totalAbonado'] = previous['totalAbonado'] ?? 0;
            data['abonadoCentavos'] = previous['abonadoCentavos'] ?? 0;
            if ((data['totalAbonado'] as num) > 0 &&
                (data['clienteId'] != previous['clienteId'] ||
                    data['paqueteId'] != previous['paqueteId'])) {
              throw StateError(
                'No puedes cambiar las relaciones de una cuenta con abonos.',
              );
            }
          }
          _validate(
            collection,
            data,
            related,
            kind: operation['kind'] as String,
          );
          final result = <String, Map<String, dynamic>>{
            path: _serializable(data),
          };
          if (collection == 'pagos') {
            final target = related.keys.single;
            final account = {
              ...related[target]!,
              'totalAbonado':
                  (((related[target]!['totalAbonado'] ?? 0) as num) * 100 +
                          (data['monto'] as num) * 100)
                      .round() /
                  100,
              'abonadoCentavos':
                  ((related[target]!['abonadoCentavos'] ?? 0) as int) +
                  (data['montoCentavos'] as int),
              'ultimoPagoId': path.split('/').last,
              'revision': ((related[target]!['revision'] ?? 0) as int) + 1,
            };
            transaction.update(firestore.doc(target), _firestoreData(account));
            result[target] = account;
          }
          transaction.set(reference, _firestoreData(data));
          return result;
        },
        timeout: const Duration(seconds: 12),
        maxAttempts: 3,
      );
    } on TimeoutException {
      throw RetryWhenOnline();
    } on FirebaseException catch (error) {
      if (_connectivity(error.code)) throw RetryWhenOnline();
      rethrow;
    }
  }

  Future<bool> addClient(Client client) => _write('clientes', client.id, {
    'clienteId': client.id,
    'usuarioId': client.userId,
    'nombre': client.name,
    'telefono': client.phone,
    'notas': client.notes,
  }, 'create');
  Future<bool> updateClient(Client client) => _write('clientes', client.id, {
    'clienteId': client.id,
    'usuarioId': client.userId,
    'nombre': client.name,
    'telefono': client.phone,
    'notas': client.notes,
  }, 'update');
  Future<bool> deleteClient(String id) => _write('clientes', id, {}, 'delete');
  Future<bool> addPackage(PhotoPackage package) =>
      _write('paquetes', package.id, {
        'paqueteId': package.id,
        'usuarioId': package.userId,
        'nombre': package.name,
        'descripcion': package.description,
        'precio': package.price,
        'activo': package.active,
      }, 'create');
  Future<bool> updatePackage(PhotoPackage package) =>
      _write('paquetes', package.id, {
        'paqueteId': package.id,
        'usuarioId': package.userId,
        'nombre': package.name,
        'descripcion': package.description,
        'precio': package.price,
        'activo': package.active,
      }, 'update');
  Future<bool> deletePackage(String id) => _write('paquetes', id, {}, 'delete');
  Future<bool> addEvent(PhotoEvent event) => _write('eventos', event.id, {
    'eventoId': event.id,
    'clienteId': event.clientId,
    'paqueteId': event.packageId,
    'usuarioId': event.userId,
    'tipo': event.type,
    'fechaHora': event.dateTime.toIso8601String(),
    'ubicacion': event.location,
    'estado': event.status,
    'montoAcordado': event.agreedAmount,
  }, 'create');
  Future<bool> updateEvent(PhotoEvent event) => _write('eventos', event.id, {
    'eventoId': event.id,
    'clienteId': event.clientId,
    'paqueteId': event.packageId,
    'usuarioId': event.userId,
    'tipo': event.type,
    'fechaHora': event.dateTime.toIso8601String(),
    'ubicacion': event.location,
    'estado': event.status,
    'montoAcordado': event.agreedAmount,
  }, 'update');
  Future<bool> deleteEvent(String id) => _write('eventos', id, {}, 'delete');
  Future<bool> addSale(PhotoSale sale) => _write('ventas', sale.id, {
    'ventaId': sale.id,
    'clienteId': sale.clientId,
    'usuarioId': sale.userId,
    'tipo': sale.type,
    'descripcion': sale.description,
    'cantidad': sale.quantity,
    'precioUnitario': sale.unitPrice,
    'total': sale.total,
    'fechaVenta': sale.soldAt.toIso8601String(),
    'estado': sale.status,
    'notas': sale.notes,
  }, 'create');
  Future<bool> updateSale(PhotoSale sale) => _write('ventas', sale.id, {
    'ventaId': sale.id,
    'clienteId': sale.clientId,
    'usuarioId': sale.userId,
    'tipo': sale.type,
    'descripcion': sale.description,
    'cantidad': sale.quantity,
    'precioUnitario': sale.unitPrice,
    'total': sale.total,
    'fechaVenta': sale.soldAt.toIso8601String(),
    'estado': sale.status,
    'notas': sale.notes,
  }, 'update');
  Future<bool> deleteSale(String id) => _write('ventas', id, {}, 'delete');
  Future<bool> addPayment(Payment payment) => _write('pagos', payment.id, {
    'pagoId': payment.id,
    'eventoId': payment.eventId,
    'ventaId': payment.saleId,
    'usuarioId': payment.userId,
    'monto': payment.amount,
    'metodo': payment.method,
    'fechaPago': payment.paidAt.toIso8601String(),
    'nota': payment.note,
  }, 'create');
  Future<bool> updatePayment(Payment payment) async =>
      throw StateError('Los abonos confirmados son inmutables.');
  Future<bool> deletePayment(String id) async =>
      throw StateError('Los abonos confirmados se conservan como historial.');
  static Client _clientFromDoc(String id, Map<String, dynamic> data) {
    return Client(
      id: _text(data, 'clienteId', id),
      userId: _text(data, 'usuarioId'),
      name: _text(data, 'nombre'),
      phone: _text(data, 'telefono'),
      notes: _text(data, 'notas'),
    );
  }

  static PhotoPackage _packageFromDoc(String id, Map<String, dynamic> data) {
    return PhotoPackage(
      id: _text(data, 'paqueteId', id),
      userId: _text(data, 'usuarioId'),
      name: _text(data, 'nombre'),
      description: _text(data, 'descripcion'),
      price: _number(data, 'precio'),
      active: _bool(data, 'activo', true),
    );
  }

  static PhotoEvent _eventFromDoc(String id, Map<String, dynamic> data) {
    return PhotoEvent(
      id: _text(data, 'eventoId', id),
      clientId: _text(data, 'clienteId'),
      packageId: _text(data, 'paqueteId'),
      userId: _text(data, 'usuarioId'),
      type: _text(data, 'tipo'),
      dateTime: _date(data, 'fechaHora'),
      location: _text(data, 'ubicacion'),
      status: _text(data, 'estado'),
      agreedAmount: _number(data, 'montoAcordado'),
    );
  }

  static Payment _paymentFromDoc(String id, Map<String, dynamic> data) {
    return Payment(
      id: _text(data, 'pagoId', id),
      eventId: _text(data, 'eventoId'),
      saleId: _text(data, 'ventaId'),
      userId: _text(data, 'usuarioId'),
      amount: _number(data, 'monto'),
      method: _text(data, 'metodo'),
      paidAt: _date(data, 'fechaPago'),
      note: _text(data, 'nota'),
    );
  }

  static PhotoSale _saleFromDoc(String id, Map<String, dynamic> data) {
    return PhotoSale(
      id: _text(data, 'ventaId', id),
      clientId: _text(data, 'clienteId'),
      userId: _text(data, 'usuarioId'),
      type: _text(data, 'tipo', 'foto_individual'),
      description: _text(data, 'descripcion'),
      quantity: _int(data, 'cantidad', 1),
      unitPrice: _number(data, 'precioUnitario'),
      soldAt: _date(data, 'fechaVenta'),
      status: _text(data, 'estado', 'pendiente'),
      notes: _text(data, 'notas'),
    );
  }

  static String _text(
    Map<String, dynamic> data,
    String key, [
    String fallback = '',
  ]) {
    final value = data[key];
    if (value == null) return fallback;
    return value.toString();
  }

  static bool _bool(
    Map<String, dynamic> data,
    String key, [
    bool fallback = false,
  ]) {
    final value = data[key];
    if (value is bool) return value;
    return fallback;
  }

  static double _number(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _int(Map<String, dynamic> data, String key, [int fallback = 0]) {
    final value = data[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static DateTime _date(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static int _sortByClientId(Client left, Client right) {
    return left.id.compareTo(right.id);
  }

  static int _sortByPackageId(PhotoPackage left, PhotoPackage right) {
    return left.id.compareTo(right.id);
  }

  static int _sortByEventDate(PhotoEvent left, PhotoEvent right) {
    return left.dateTime.compareTo(right.dateTime);
  }

  static int _sortByPaymentDate(Payment left, Payment right) {
    return left.paidAt.compareTo(right.paidAt);
  }

  static int _sortBySaleDate(PhotoSale left, PhotoSale right) {
    return right.soldAt.compareTo(left.soldAt);
  }
}
