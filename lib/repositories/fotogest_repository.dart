import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/client.dart';
import '../models/payment.dart';
import '../models/photo_event.dart';
import '../models/photo_package.dart';
import '../models/photo_sale.dart';

class FotogestRepository {
  FotogestRepository() : _firestore = null, _auth = null;

  FotogestRepository._firebase(this._firestore, this._auth);

  factory FotogestRepository.firebase() {
    return FotogestRepository._firebase(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    );
  }

  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;
  bool _lastSignInWasOffline = false;

  static const _cachedEmailKey = 'fotogest_cached_email';
  static const _cachedPasswordHashKey = 'fotogest_cached_password_hash';

  List<AppUser> _users = const [
    AppUser(
      id: 'usr_001',
      name: 'Edwin Tavarez',
      email: 'edwin.tavarez@example.com',
      role: 'fotografo',
      active: true,
    ),
    AppUser(
      id: 'usr_002',
      name: 'Asistente Demo',
      email: 'asistente@example.com',
      role: 'asistente',
      active: true,
    ),
    AppUser(
      id: 'usr_003',
      name: 'Admin FotoGest',
      email: 'admin@example.com',
      role: 'administrador',
      active: true,
    ),
  ];

  List<Client> _clients = [
    const Client(
      id: 'cli_001',
      userId: 'usr_001',
      name: 'Maria Fernandez',
      phone: '809-555-1101',
      notes: 'Prefiere contacto por WhatsApp',
    ),
    const Client(
      id: 'cli_002',
      userId: 'usr_001',
      name: 'Jose Ramirez',
      phone: '809-555-2202',
      notes: 'Solicita album impreso',
    ),
    const Client(
      id: 'cli_003',
      userId: 'usr_001',
      name: 'Laura Gomez',
      phone: '809-555-3303',
      notes: 'Evento en iglesia y recepcion',
    ),
  ];

  List<PhotoPackage> _packages = const [
    PhotoPackage(
      id: 'paq_001',
      name: 'Basico Evento',
      description: '20 fotos editadas y entrega digital',
      price: 3500,
      active: true,
    ),
    PhotoPackage(
      id: 'paq_002',
      name: 'Premium Familiar',
      description: '40 fotos editadas, album digital y 5 impresas',
      price: 6500,
      active: true,
    ),
    PhotoPackage(
      id: 'paq_003',
      name: 'Cobertura Completa',
      description: '80 fotos editadas, album impreso y entrega express',
      price: 12000,
      active: true,
    ),
  ];

  List<PhotoEvent> _events = [
    PhotoEvent(
      id: 'evt_001',
      clientId: 'cli_001',
      packageId: 'paq_002',
      userId: 'usr_001',
      type: 'Bautizo',
      dateTime: DateTime(2026, 7, 5, 15),
      location: 'Parroquia San Judas',
      status: 'programado',
    ),
    PhotoEvent(
      id: 'evt_002',
      clientId: 'cli_002',
      packageId: 'paq_001',
      userId: 'usr_001',
      type: 'Cumpleanos',
      dateTime: DateTime(2026, 7, 6, 18),
      location: 'Salon Vista Alegre',
      status: 'en_proceso',
    ),
    PhotoEvent(
      id: 'evt_003',
      clientId: 'cli_003',
      packageId: 'paq_003',
      userId: 'usr_001',
      type: 'Boda',
      dateTime: DateTime(2026, 7, 12, 16, 30),
      location: 'Santiago Centro',
      status: 'programado',
    ),
  ];

  List<PhotoSale> _sales = [
    PhotoSale(
      id: 'ven_001',
      clientId: 'cli_001',
      userId: 'usr_001',
      type: 'foto_individual',
      description: 'Foto digital editada para perfil profesional',
      quantity: 3,
      unitPrice: 450,
      soldAt: DateTime(2026, 7, 3, 10),
      status: 'pendiente',
      notes: 'Entrega por WhatsApp',
    ),
    PhotoSale(
      id: 'ven_002',
      clientId: 'cli_002',
      userId: 'usr_001',
      type: 'impresion',
      description: 'Impresion 8x10 con retoque basico',
      quantity: 2,
      unitPrice: 650,
      soldAt: DateTime(2026, 7, 4, 11, 30),
      status: 'pendiente',
      notes: 'Recoger en estudio',
    ),
  ];

  List<Payment> _payments = [
    Payment(
      id: 'pag_001',
      eventId: 'evt_001',
      amount: 3000,
      method: 'transferencia',
      paidAt: DateTime(2026, 7, 1, 12),
      note: 'Abono inicial',
    ),
    Payment(
      id: 'pag_002',
      eventId: 'evt_002',
      amount: 1500,
      method: 'efectivo',
      paidAt: DateTime(2026, 7, 1, 12, 10),
      note: 'Reserva de fecha',
    ),
    Payment(
      id: 'pag_003',
      eventId: 'evt_003',
      amount: 5000,
      method: 'transferencia',
      paidAt: DateTime(2026, 7, 1, 12, 20),
      note: 'Separacion de paquete premium',
    ),
  ];

  bool get hasFirebase => _firestore != null;
  bool get lastSignInWasOffline => _lastSignInWasOffline;

  List<AppUser> getUsers() => List.unmodifiable(_users);
  List<Client> getClients() => List.unmodifiable(_clients);
  List<PhotoEvent> getEvents() => List.unmodifiable(_events);
  List<PhotoPackage> getPackages() => List.unmodifiable(_packages);
  List<PhotoSale> getSales() => List.unmodifiable(_sales);
  List<Payment> getPayments() => List.unmodifiable(_payments);

  Future<bool> signIn(String email, String password) async {
    final auth = _auth;
    if (auth == null) {
      _lastSignInWasOffline = true;
      return _signInWithCachedCredentials(email, password);
    }

    try {
      _lastSignInWasOffline = false;
      await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await _cacheSuccessfulCredentials(email, password);
      _lastSignInWasOffline = false;
      return true;
    } on FirebaseAuthException catch (error) {
      if (!_isConnectivityAuthError(error.code)) rethrow;
      final cachedAccess = await _signInWithCachedCredentials(email, password);
      _lastSignInWasOffline = cachedAccess;
      if (cachedAccess) return true;
      rethrow;
    } on FirebaseException catch (error) {
      if (!_isConnectivityAuthError(error.code)) rethrow;
      final cachedAccess = await _signInWithCachedCredentials(email, password);
      _lastSignInWasOffline = cachedAccess;
      if (cachedAccess) return true;
      rethrow;
    }
  }

  Future<bool> loadRemoteData() async {
    final firestore = _firestore;
    if (firestore == null) return false;

    final users = await firestore.collection('usuarios').get();
    final clients = await firestore.collection('clientes').get();
    final packages = await firestore.collection('paquetes').get();
    final events = await firestore.collection('eventos').get();
    final payments = await firestore.collection('pagos').get();

    _users = users.docs.map(_userFromDoc).toList()..sort(_sortByUserId);
    _clients = clients.docs.map(_clientFromDoc).toList()..sort(_sortByClientId);
    _packages = packages.docs.map(_packageFromDoc).toList()
      ..sort(_sortByPackageId);
    _events = events.docs.map(_eventFromDoc).toList()..sort(_sortByEventDate);
    _payments = payments.docs.map(_paymentFromDoc).toList()
      ..sort(_sortByPaymentDate);
    await _loadSalesIfAvailable(firestore);

    return true;
  }

  Future<bool> addClient(Client client) async {
    var savedRemotely = false;
    final firestore = _firestore;

    if (firestore != null) {
      try {
        await firestore.collection('clientes').doc(client.id).set({
          'clienteId': client.id,
          'usuarioId': client.userId,
          'nombre': client.name,
          'telefono': client.phone,
          'notas': client.notes,
          'createdAt': FieldValue.serverTimestamp(),
        });
        savedRemotely = true;
      } on FirebaseException {
        savedRemotely = false;
      }
    }

    _clients.removeWhere((savedClient) => savedClient.id == client.id);
    _clients.insert(0, client);
    return savedRemotely;
  }

  Future<bool> updateClient(Client client) async {
    var savedRemotely = false;
    final firestore = _firestore;

    if (firestore != null) {
      try {
        await firestore.collection('clientes').doc(client.id).set({
          'clienteId': client.id,
          'usuarioId': client.userId,
          'nombre': client.name,
          'telefono': client.phone,
          'notas': client.notes,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        savedRemotely = true;
      } on FirebaseException {
        savedRemotely = false;
      }
    }

    final index = _clients.indexWhere((savedClient) {
      return savedClient.id == client.id;
    });
    if (index == -1) {
      _clients.insert(0, client);
    } else {
      _clients[index] = client;
    }
    return savedRemotely;
  }

  Future<bool> deleteClient(String clientId) async {
    var deletedRemotely = false;
    final firestore = _firestore;

    if (firestore != null) {
      try {
        await firestore.collection('clientes').doc(clientId).delete();
        deletedRemotely = true;
      } on FirebaseException {
        deletedRemotely = false;
      }
    }

    _clients.removeWhere((client) => client.id == clientId);
    return deletedRemotely;
  }

  Future<bool> addPackage(PhotoPackage package) async {
    var savedRemotely = false;
    final firestore = _firestore;

    if (firestore != null) {
      try {
        await firestore.collection('paquetes').doc(package.id).set({
          'paqueteId': package.id,
          'nombre': package.name,
          'descripcion': package.description,
          'precio': package.price,
          'activo': package.active,
          'createdAt': FieldValue.serverTimestamp(),
        });
        savedRemotely = true;
      } on FirebaseException {
        savedRemotely = false;
      }
    }

    _packages.removeWhere((savedPackage) => savedPackage.id == package.id);
    _packages = [package, ..._packages]..sort(_sortByPackageId);
    return savedRemotely;
  }

  Future<bool> updatePackage(PhotoPackage package) async {
    var savedRemotely = false;
    final firestore = _firestore;

    if (firestore != null) {
      try {
        await firestore.collection('paquetes').doc(package.id).set({
          'paqueteId': package.id,
          'nombre': package.name,
          'descripcion': package.description,
          'precio': package.price,
          'activo': package.active,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        savedRemotely = true;
      } on FirebaseException {
        savedRemotely = false;
      }
    }

    final index = _packages.indexWhere((savedPackage) {
      return savedPackage.id == package.id;
    });
    if (index == -1) {
      _packages = [package, ..._packages]..sort(_sortByPackageId);
    } else {
      _packages[index] = package;
    }
    return savedRemotely;
  }

  Future<bool> deletePackage(String packageId) async {
    var deletedRemotely = false;
    final firestore = _firestore;

    if (firestore != null) {
      try {
        await firestore.collection('paquetes').doc(packageId).delete();
        deletedRemotely = true;
      } on FirebaseException {
        deletedRemotely = false;
      }
    }

    _packages = _packages
        .where((package) => package.id != packageId)
        .toList(growable: true);
    return deletedRemotely;
  }

  Future<bool> addEvent(PhotoEvent event) async {
    var savedRemotely = false;
    final firestore = _firestore;

    if (firestore != null) {
      try {
        await firestore.collection('eventos').doc(event.id).set({
          'eventoId': event.id,
          'clienteId': event.clientId,
          'paqueteId': event.packageId,
          'usuarioId': event.userId,
          'tipo': event.type,
          'fechaHora': Timestamp.fromDate(event.dateTime),
          'ubicacion': event.location,
          'estado': event.status,
          'createdAt': FieldValue.serverTimestamp(),
        });
        savedRemotely = true;
      } on FirebaseException {
        savedRemotely = false;
      }
    }

    _events.removeWhere((savedEvent) => savedEvent.id == event.id);
    _events = [event, ..._events]..sort(_sortByEventDate);
    return savedRemotely;
  }

  Future<bool> updateEvent(PhotoEvent event) async {
    var savedRemotely = false;
    final firestore = _firestore;

    if (firestore != null) {
      try {
        await firestore.collection('eventos').doc(event.id).set({
          'eventoId': event.id,
          'clienteId': event.clientId,
          'paqueteId': event.packageId,
          'usuarioId': event.userId,
          'tipo': event.type,
          'fechaHora': Timestamp.fromDate(event.dateTime),
          'ubicacion': event.location,
          'estado': event.status,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        savedRemotely = true;
      } on FirebaseException {
        savedRemotely = false;
      }
    }

    final index = _events.indexWhere((savedEvent) {
      return savedEvent.id == event.id;
    });
    if (index == -1) {
      _events = [event, ..._events]..sort(_sortByEventDate);
    } else {
      _events[index] = event;
      _events.sort(_sortByEventDate);
    }
    return savedRemotely;
  }

  Future<bool> deleteEvent(String eventId) async {
    var deletedRemotely = false;
    final firestore = _firestore;
    final paymentIds = _payments
        .where((payment) => payment.eventId == eventId)
        .map((payment) => payment.id)
        .toList();

    if (firestore != null) {
      try {
        final batch = firestore.batch();
        batch.delete(firestore.collection('eventos').doc(eventId));
        for (final paymentId in paymentIds) {
          batch.delete(firestore.collection('pagos').doc(paymentId));
        }
        await batch.commit();
        deletedRemotely = true;
      } on FirebaseException {
        deletedRemotely = false;
      }
    }

    _events = _events
        .where((event) => event.id != eventId)
        .toList(growable: true);
    _payments = _payments
        .where((payment) => payment.eventId != eventId)
        .toList(growable: true);
    return deletedRemotely;
  }

  Future<bool> addSale(PhotoSale sale) async {
    var savedRemotely = false;
    final firestore = _firestore;

    if (firestore != null) {
      try {
        await firestore.collection('ventas').doc(sale.id).set({
          'ventaId': sale.id,
          'clienteId': sale.clientId,
          'usuarioId': sale.userId,
          'tipo': sale.type,
          'descripcion': sale.description,
          'cantidad': sale.quantity,
          'precioUnitario': sale.unitPrice,
          'total': sale.total,
          'fechaVenta': Timestamp.fromDate(sale.soldAt),
          'estado': sale.status,
          'notas': sale.notes,
          'createdAt': FieldValue.serverTimestamp(),
        });
        savedRemotely = true;
      } on FirebaseException {
        savedRemotely = false;
      }
    }

    _sales.removeWhere((savedSale) => savedSale.id == sale.id);
    _sales = [sale, ..._sales]..sort(_sortBySaleDate);
    return savedRemotely;
  }

  Future<bool> updateSale(PhotoSale sale) async {
    var savedRemotely = false;
    final firestore = _firestore;

    if (firestore != null) {
      try {
        await firestore.collection('ventas').doc(sale.id).set({
          'ventaId': sale.id,
          'clienteId': sale.clientId,
          'usuarioId': sale.userId,
          'tipo': sale.type,
          'descripcion': sale.description,
          'cantidad': sale.quantity,
          'precioUnitario': sale.unitPrice,
          'total': sale.total,
          'fechaVenta': Timestamp.fromDate(sale.soldAt),
          'estado': sale.status,
          'notas': sale.notes,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        savedRemotely = true;
      } on FirebaseException {
        savedRemotely = false;
      }
    }

    final index = _sales.indexWhere((savedSale) {
      return savedSale.id == sale.id;
    });
    if (index == -1) {
      _sales = [sale, ..._sales]..sort(_sortBySaleDate);
    } else {
      _sales[index] = sale;
      _sales.sort(_sortBySaleDate);
    }
    return savedRemotely;
  }

  Future<bool> deleteSale(String saleId) async {
    var deletedRemotely = false;
    final firestore = _firestore;
    final paymentIds = _payments
        .where((payment) => payment.saleId == saleId)
        .map((payment) => payment.id)
        .toList();

    if (firestore != null) {
      try {
        final batch = firestore.batch();
        batch.delete(firestore.collection('ventas').doc(saleId));
        for (final paymentId in paymentIds) {
          batch.delete(firestore.collection('pagos').doc(paymentId));
        }
        await batch.commit();
        deletedRemotely = true;
      } on FirebaseException {
        deletedRemotely = false;
      }
    }

    _sales = _sales.where((sale) => sale.id != saleId).toList(growable: true);
    _payments = _payments
        .where((payment) => payment.saleId != saleId)
        .toList(growable: true);
    return deletedRemotely;
  }

  Future<bool> addPayment(Payment payment) async {
    var savedRemotely = false;
    final firestore = _firestore;

    if (firestore != null) {
      try {
        await firestore.collection('pagos').doc(payment.id).set({
          'pagoId': payment.id,
          'eventoId': payment.eventId,
          'ventaId': payment.saleId,
          'monto': payment.amount,
          'metodo': payment.method,
          'fechaPago': Timestamp.fromDate(payment.paidAt),
          'nota': payment.note,
          'createdAt': FieldValue.serverTimestamp(),
        });
        savedRemotely = true;
      } on FirebaseException {
        savedRemotely = false;
      }
    }

    _payments.removeWhere((savedPayment) => savedPayment.id == payment.id);
    _payments = [payment, ..._payments]..sort(_sortByPaymentDate);
    return savedRemotely;
  }

  Future<bool> updatePayment(Payment payment) async {
    var savedRemotely = false;
    final firestore = _firestore;

    if (firestore != null) {
      try {
        await firestore.collection('pagos').doc(payment.id).set({
          'pagoId': payment.id,
          'eventoId': payment.eventId,
          'ventaId': payment.saleId,
          'monto': payment.amount,
          'metodo': payment.method,
          'fechaPago': Timestamp.fromDate(payment.paidAt),
          'nota': payment.note,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        savedRemotely = true;
      } on FirebaseException {
        savedRemotely = false;
      }
    }

    final index = _payments.indexWhere((savedPayment) {
      return savedPayment.id == payment.id;
    });
    if (index == -1) {
      _payments = [payment, ..._payments]..sort(_sortByPaymentDate);
    } else {
      _payments[index] = payment;
      _payments.sort(_sortByPaymentDate);
    }
    return savedRemotely;
  }

  Future<bool> deletePayment(String paymentId) async {
    var deletedRemotely = false;
    final firestore = _firestore;

    if (firestore != null) {
      try {
        await firestore.collection('pagos').doc(paymentId).delete();
        deletedRemotely = true;
      } on FirebaseException {
        deletedRemotely = false;
      }
    }

    _payments = _payments
        .where((payment) => payment.id != paymentId)
        .toList(growable: true);
    return deletedRemotely;
  }

  static AppUser _userFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return AppUser(
      id: _text(data, 'usuarioId', doc.id),
      name: _text(data, 'nombre'),
      email: _text(data, 'email'),
      role: _text(data, 'rol'),
      active: _bool(data, 'activo', true),
    );
  }

  static Client _clientFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return Client(
      id: _text(data, 'clienteId', doc.id),
      userId: _text(data, 'usuarioId', 'usr_001'),
      name: _text(data, 'nombre'),
      phone: _text(data, 'telefono'),
      notes: _text(data, 'notas'),
    );
  }

  static PhotoPackage _packageFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return PhotoPackage(
      id: _text(data, 'paqueteId', doc.id),
      name: _text(data, 'nombre'),
      description: _text(data, 'descripcion'),
      price: _number(data, 'precio'),
      active: _bool(data, 'activo', true),
    );
  }

  static PhotoEvent _eventFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return PhotoEvent(
      id: _text(data, 'eventoId', doc.id),
      clientId: _text(data, 'clienteId'),
      packageId: _text(data, 'paqueteId'),
      userId: _text(data, 'usuarioId', 'usr_001'),
      type: _text(data, 'tipo'),
      dateTime: _date(data, 'fechaHora'),
      location: _text(data, 'ubicacion'),
      status: _text(data, 'estado'),
    );
  }

  static Payment _paymentFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return Payment(
      id: _text(data, 'pagoId', doc.id),
      eventId: _text(data, 'eventoId'),
      saleId: _text(data, 'ventaId'),
      amount: _number(data, 'monto'),
      method: _text(data, 'metodo'),
      paidAt: _date(data, 'fechaPago'),
      note: _text(data, 'nota'),
    );
  }

  static PhotoSale _saleFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return PhotoSale(
      id: _text(data, 'ventaId', doc.id),
      clientId: _text(data, 'clienteId'),
      userId: _text(data, 'usuarioId', 'usr_001'),
      type: _text(data, 'tipo', 'foto_individual'),
      description: _text(data, 'descripcion'),
      quantity: _int(data, 'cantidad', 1),
      unitPrice: _number(data, 'precioUnitario'),
      soldAt: _date(data, 'fechaVenta'),
      status: _text(data, 'estado', 'pendiente'),
      notes: _text(data, 'notas'),
    );
  }

  Future<void> _loadSalesIfAvailable(FirebaseFirestore firestore) async {
    try {
      final sales = await firestore.collection('ventas').get();
      _sales = sales.docs.map(_saleFromDoc).toList()..sort(_sortBySaleDate);
    } on FirebaseException {
      return;
    }
  }

  static Future<void> _cacheSuccessfulCredentials(
    String email,
    String password,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_cachedEmailKey, _normalizeEmail(email));
    await preferences.setString(
      _cachedPasswordHashKey,
      _credentialHash(email, password),
    );
  }

  static Future<bool> _signInWithCachedCredentials(
    String email,
    String password,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final cachedEmail = preferences.getString(_cachedEmailKey);
    final cachedHash = preferences.getString(_cachedPasswordHashKey);

    if (cachedEmail == null || cachedHash == null) return false;
    return cachedEmail == _normalizeEmail(email) &&
        cachedHash == _credentialHash(email, password);
  }

  static String _credentialHash(String email, String password) {
    final value = '${_normalizeEmail(email)}:${password.trim()}:fotogest_pro';
    return sha256.convert(utf8.encode(value)).toString();
  }

  static bool _isConnectivityAuthError(String code) {
    return code == 'network-request-failed' ||
        code == 'unavailable' ||
        code == 'deadline-exceeded';
  }

  static String _normalizeEmail(String email) => email.trim().toLowerCase();

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

  static int _sortByUserId(AppUser left, AppUser right) {
    return left.id.compareTo(right.id);
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
