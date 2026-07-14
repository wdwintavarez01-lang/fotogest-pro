import 'package:flutter/foundation.dart';

import '../models/client.dart';
import '../models/payment.dart';
import '../models/photo_event.dart';
import '../models/photo_package.dart';
import '../repositories/fotogest_repository.dart';

class FotogestViewModel extends ChangeNotifier {
  FotogestViewModel(this._repository);

  final FotogestRepository _repository;
  bool isLoading = false;
  bool remoteDataLoaded = false;
  bool offlineSession = false;
  String? connectionMessage;

  List<Client> get clients => _repository.getClients();
  List<PhotoEvent> get events => _repository.getEvents();
  List<PhotoPackage> get packages => _repository.getPackages();
  List<Payment> get payments => _repository.getPayments();

  String get connectionLabel {
    if (isLoading) return 'Cargando';
    if (remoteDataLoaded && !offlineSession) return 'Online';
    if (offlineSession) return 'Offline';
    return 'Local';
  }

  double get totalPaid {
    return payments.fold(0, (total, payment) => total + payment.amount);
  }

  int get activeEvents {
    return events.where((event) => event.status != 'completado').length;
  }

  double get totalPending {
    double total = 0;
    for (final event in events) {
      final package = packageFor(event.packageId);
      final paid = paymentsForEvent(
        event.id,
      ).fold<double>(0, (sum, payment) => sum + payment.amount);
      total += (package.price - paid).clamp(0, package.price).toDouble();
    }
    return total;
  }

  Client clientFor(String id) {
    return clients.firstWhere(
      (client) => client.id == id,
      orElse: () => Client(
        id: id,
        userId: 'usr_001',
        name: 'Cliente no encontrado',
        phone: 'Sin telefono',
        notes: 'El registro relacionado no existe en la base de datos.',
      ),
    );
  }

  PhotoEvent eventFor(String id) {
    return events.firstWhere(
      (event) => event.id == id,
      orElse: () => PhotoEvent(
        id: id,
        clientId: '',
        packageId: '',
        userId: 'usr_001',
        type: 'Evento no encontrado',
        dateTime: DateTime.now(),
        location: 'Sin ubicacion',
        status: 'pendiente',
      ),
    );
  }

  PhotoPackage packageFor(String id) {
    return packages.firstWhere(
      (package) => package.id == id,
      orElse: () => PhotoPackage(
        id: id,
        name: 'Paquete no encontrado',
        description: 'El paquete relacionado no existe en la base de datos.',
        price: 0,
        active: false,
      ),
    );
  }

  List<Payment> paymentsForEvent(String eventId) {
    return payments.where((payment) => payment.eventId == eventId).toList();
  }

  double paidForEvent(String eventId) {
    return paymentsForEvent(eventId).fold(0, (sum, payment) {
      return sum + payment.amount;
    });
  }

  double pendingForEvent(String eventId) {
    final event = eventFor(eventId);
    final package = packageFor(event.packageId);
    final paid = paidForEvent(eventId);
    return (package.price - paid).clamp(0, package.price).toDouble();
  }

  bool hasEventsForClient(String clientId) {
    return events.any((event) => event.clientId == clientId);
  }

  bool hasEventsForPackage(String packageId) {
    return events.any((event) => event.packageId == packageId);
  }

  Future<bool> loadRemoteData() async {
    if (!_repository.hasFirebase) return false;

    isLoading = true;
    notifyListeners();

    try {
      remoteDataLoaded = await _repository.loadRemoteData();
      connectionMessage = remoteDataLoaded
          ? 'Datos cargados en modo Online'
          : 'Usando datos locales del prototipo';
      return remoteDataLoaded;
    } catch (_) {
      remoteDataLoaded = false;
      connectionMessage =
          'No se pudo leer la base de datos. Revisa la conexion.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      final signedIn = await _repository.signIn(email, password);
      if (!signedIn) {
        connectionMessage =
            'No hay conexion y esas credenciales no estan guardadas.';
        notifyListeners();
        return false;
      }
      await loadRemoteData();
      offlineSession = _repository.lastSignInWasOffline;
      connectionMessage = offlineSession
          ? 'Sesion offline iniciada con credenciales guardadas'
          : 'Sesion iniciada Online';
      notifyListeners();
      return true;
    } catch (_) {
      connectionMessage =
          'No se pudo iniciar sesion. Revisa el correo, la contrasena o la conexion.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addClient({
    required String name,
    required String phone,
    String notes = '',
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final savedRemotely = await _repository.addClient(
      Client(
        id: 'cli_$timestamp',
        userId: 'usr_001',
        name: name.trim(),
        phone: phone.trim(),
        notes: notes.trim(),
      ),
    );
    notifyListeners();
    return savedRemotely;
  }

  Future<bool> updateClient({
    required Client client,
    required String name,
    required String phone,
    String notes = '',
  }) async {
    final savedRemotely = await _repository.updateClient(
      client.copyWith(
        name: name.trim(),
        phone: phone.trim(),
        notes: notes.trim(),
      ),
    );
    notifyListeners();
    return savedRemotely;
  }

  Future<bool> deleteClient(String clientId) async {
    final deletedRemotely = await _repository.deleteClient(clientId);
    notifyListeners();
    return deletedRemotely;
  }

  Future<bool> addPackage({
    required String name,
    required String description,
    required double price,
    bool active = true,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final savedRemotely = await _repository.addPackage(
      PhotoPackage(
        id: 'paq_$timestamp',
        name: name.trim(),
        description: description.trim(),
        price: price,
        active: active,
      ),
    );
    notifyListeners();
    return savedRemotely;
  }

  Future<bool> updatePackage({
    required PhotoPackage package,
    required String name,
    required String description,
    required double price,
    required bool active,
  }) async {
    final savedRemotely = await _repository.updatePackage(
      package.copyWith(
        name: name.trim(),
        description: description.trim(),
        price: price,
        active: active,
      ),
    );
    notifyListeners();
    return savedRemotely;
  }

  Future<bool> deletePackage(String packageId) async {
    final deletedRemotely = await _repository.deletePackage(packageId);
    notifyListeners();
    return deletedRemotely;
  }

  Future<bool> addEvent({
    required String clientId,
    required String packageId,
    required String type,
    required DateTime dateTime,
    required String location,
    required String status,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final savedRemotely = await _repository.addEvent(
      PhotoEvent(
        id: 'evt_$timestamp',
        clientId: clientId,
        packageId: packageId,
        userId: 'usr_001',
        type: type.trim(),
        dateTime: dateTime,
        location: location.trim(),
        status: status,
      ),
    );
    notifyListeners();
    return savedRemotely;
  }

  Future<bool> updateEvent({
    required PhotoEvent event,
    required String clientId,
    required String packageId,
    required String type,
    required DateTime dateTime,
    required String location,
    required String status,
  }) async {
    final savedRemotely = await _repository.updateEvent(
      event.copyWith(
        clientId: clientId,
        packageId: packageId,
        type: type.trim(),
        dateTime: dateTime,
        location: location.trim(),
        status: status,
      ),
    );
    notifyListeners();
    return savedRemotely;
  }

  Future<bool> deleteEvent(String eventId) async {
    final deletedRemotely = await _repository.deleteEvent(eventId);
    notifyListeners();
    return deletedRemotely;
  }

  Future<bool> addPayment({
    required String eventId,
    required double amount,
    required String method,
    required DateTime paidAt,
    String note = '',
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final savedRemotely = await _repository.addPayment(
      Payment(
        id: 'pag_$timestamp',
        eventId: eventId,
        amount: amount,
        method: method,
        paidAt: paidAt,
        note: note.trim(),
      ),
    );
    notifyListeners();
    return savedRemotely;
  }

  Future<bool> updatePayment({
    required Payment payment,
    required String eventId,
    required double amount,
    required String method,
    required DateTime paidAt,
    String note = '',
  }) async {
    final savedRemotely = await _repository.updatePayment(
      payment.copyWith(
        eventId: eventId,
        amount: amount,
        method: method,
        paidAt: paidAt,
        note: note.trim(),
      ),
    );
    notifyListeners();
    return savedRemotely;
  }

  Future<bool> deletePayment(String paymentId) async {
    final deletedRemotely = await _repository.deletePayment(paymentId);
    notifyListeners();
    return deletedRemotely;
  }
}
