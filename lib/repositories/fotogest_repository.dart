import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/client.dart';
import '../models/payment.dart';
import '../models/photo_event.dart';
import '../models/photo_package.dart';

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

  List<AppUser> getUsers() => List.unmodifiable(_users);
  List<Client> getClients() => List.unmodifiable(_clients);
  List<PhotoEvent> getEvents() => List.unmodifiable(_events);
  List<PhotoPackage> getPackages() => List.unmodifiable(_packages);
  List<Payment> getPayments() => List.unmodifiable(_payments);

  Future<bool> signIn(String email, String password) async {
    final auth = _auth;
    if (auth == null) return false;

    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    return true;
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
      amount: _number(data, 'monto'),
      method: _text(data, 'metodo'),
      paidAt: _date(data, 'fechaPago'),
      note: _text(data, 'nota'),
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
}
