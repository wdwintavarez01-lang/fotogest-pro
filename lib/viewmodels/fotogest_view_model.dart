import 'package:flutter/foundation.dart';

import '../models/client.dart';
import '../models/payment.dart';
import '../models/photo_event.dart';
import '../models/photo_package.dart';
import '../models/photo_sale.dart';
import '../repositories/fotogest_repository.dart';

class SaleSaveResult {
  const SaleSaveResult({required this.sale, required this.savedRemotely});

  final PhotoSale sale;
  final bool savedRemotely;
}

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
  List<PhotoSale> get sales => _repository.getSales();
  List<Payment> get payments => _repository.getPayments();

  /// Identificador del usuario autenticado dueño de los registros.
  String get currentUserId => _repository.currentUserId;

  /// Correo del usuario autenticado, usado en la pantalla de resumen.
  String get currentUserEmail => _repository.currentUserEmail;

  String get connectionLabel {
    if (isLoading) return 'Cargando';
    if (remoteDataLoaded && !offlineSession && pendingCount == 0) {
      return 'Online';
    }
    if (offlineSession) return 'Offline';
    if (pendingCount > 0) return 'Pendiente';
    return 'Sin datos';
  }

  double get totalPaid {
    return _money(payments.fold(0, (total, payment) => total + payment.amount));
  }

  int get activeEvents {
    return events.where((event) {
      return event.status == 'programado' || event.status == 'en_proceso';
    }).length;
  }

  double get totalPending {
    double total = 0;
    for (final event in events) {
      if (event.status == 'cancelado') continue;
      total += pendingForEvent(event.id);
    }
    for (final sale in sales) {
      if (sale.status == 'cancelado') continue;
      total += pendingForSale(sale.id);
    }
    return _money(total);
  }

  static double _money(double value) => (value * 100).round() / 100;

  Client clientFor(String id) {
    return _repository.getAllClients().firstWhere(
      (client) => client.id == id,
      orElse: () => Client(
        id: id,
        userId: currentUserId,
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
        userId: currentUserId,
        type: 'Evento no encontrado',
        dateTime: DateTime.now(),
        location: 'Sin ubicacion',
        status: 'pendiente',
      ),
    );
  }

  PhotoPackage packageFor(String id) {
    return _repository.getAllPackages().firstWhere(
      (package) => package.id == id,
      orElse: () => PhotoPackage(
        id: id,
        userId: currentUserId,
        name: 'Servicio no encontrado',
        description: 'El servicio relacionado no existe en la base de datos.',
        price: 0,
        active: false,
      ),
    );
  }

  PhotoSale saleFor(String id) {
    return sales.firstWhere(
      (sale) => sale.id == id,
      orElse: () => PhotoSale(
        id: id,
        clientId: '',
        userId: currentUserId,
        type: 'otro',
        description: 'Venta no encontrada',
        quantity: 1,
        unitPrice: 0,
        soldAt: DateTime.now(),
        status: 'pendiente',
      ),
    );
  }

  /// Monto total que debe cobrarse por un evento.
  ///
  /// Se usa el monto acordado guardado dentro del evento. Los eventos creados
  /// anteriores a esta version se normalizan con la migracion de la base.
  double amountForEvent(String eventId) {
    final event = eventFor(eventId);
    return event.agreedAmount;
  }

  List<Payment> paymentsForEvent(String eventId) {
    return payments.where((payment) => payment.eventId == eventId).toList();
  }

  List<Payment> paymentsForSale(String saleId) {
    return payments.where((payment) => payment.saleId == saleId).toList();
  }

  List<PhotoEvent> get pendingPaymentEvents {
    final pending = events.where((event) {
      return event.status != 'cancelado' && pendingForEvent(event.id) > 0;
    }).toList();
    pending.sort((left, right) {
      final pendingCompare = pendingForEvent(
        right.id,
      ).compareTo(pendingForEvent(left.id));
      if (pendingCompare != 0) return pendingCompare;
      return left.dateTime.compareTo(right.dateTime);
    });
    return pending;
  }

  List<PhotoEvent> get paidEvents {
    final paid = events.where((event) {
      return event.status != 'cancelado' &&
          amountForEvent(event.id) > 0 &&
          pendingForEvent(event.id) <= 0;
    }).toList();
    paid.sort((left, right) {
      final rightDate = lastPaymentForEvent(right.id)?.paidAt ?? right.dateTime;
      final leftDate = lastPaymentForEvent(left.id)?.paidAt ?? left.dateTime;
      return rightDate.compareTo(leftDate);
    });
    return paid;
  }

  List<PhotoSale> get pendingSales {
    final pending = sales.where((sale) {
      return sale.status != 'cancelado' && pendingForSale(sale.id) > 0;
    }).toList();
    pending.sort((left, right) {
      final pendingCompare = pendingForSale(
        right.id,
      ).compareTo(pendingForSale(left.id));
      if (pendingCompare != 0) return pendingCompare;
      return right.soldAt.compareTo(left.soldAt);
    });
    return pending;
  }

  List<PhotoSale> get paidSales {
    final paid = sales.where((sale) {
      return sale.status != 'cancelado' &&
          sale.total > 0 &&
          pendingForSale(sale.id) <= 0;
    }).toList();
    paid.sort((left, right) {
      final rightDate = lastPaymentForSale(right.id)?.paidAt ?? right.soldAt;
      final leftDate = lastPaymentForSale(left.id)?.paidAt ?? left.soldAt;
      return rightDate.compareTo(leftDate);
    });
    return paid;
  }

  double paidForEvent(String eventId) {
    return _money(
      paymentsForEvent(eventId).fold(0.0, (sum, payment) {
        return sum + payment.amount;
      }),
    );
  }

  double paidForSale(String saleId) {
    return _money(
      paymentsForSale(saleId).fold(0.0, (sum, payment) {
        return sum + payment.amount;
      }),
    );
  }

  double pendingForEvent(String eventId) {
    final event = eventFor(eventId);
    if (event.status == 'cancelado') return 0;
    final amount = amountForEvent(eventId);
    final paid = paidForEvent(eventId);
    return _money((amount - paid).clamp(0, amount).toDouble());
  }

  double pendingForSale(String saleId) {
    final sale = saleFor(saleId);
    if (sale.status == 'cancelado') return 0;
    final paid = paidForSale(saleId);
    return _money((sale.total - paid).clamp(0, sale.total).toDouble());
  }

  Payment? lastPaymentForEvent(String eventId) {
    final eventPayments = paymentsForEvent(eventId);
    if (eventPayments.isEmpty) return null;
    eventPayments.sort((left, right) => right.paidAt.compareTo(left.paidAt));
    return eventPayments.first;
  }

  Payment? lastPaymentForSale(String saleId) {
    final salePayments = paymentsForSale(saleId);
    if (salePayments.isEmpty) return null;
    salePayments.sort((left, right) => right.paidAt.compareTo(left.paidAt));
    return salePayments.first;
  }

  bool hasEventsForClient(String clientId) {
    return events.any((event) => event.clientId == clientId);
  }

  bool hasSalesForClient(String clientId) {
    return sales.any((sale) => sale.clientId == clientId);
  }

  bool hasEventsForPackage(String packageId) {
    return events.any((event) => event.packageId == packageId);
  }

  // ---------------------------------------------------------------------
  // Sesion y carga
  // ---------------------------------------------------------------------

  Future<bool> loadRemoteData() async {
    if (!_repository.hasFirebase || !_repository.hasSession) return false;

    isLoading = true;
    notifyListeners();

    try {
      remoteDataLoaded = await _repository.loadRemoteData();
      offlineSession = _repository.fromCache;
      connectionMessage =
          syncError ??
          (offlineSession
              ? 'Sin conexion. Consulta la cache y guarda cambios pendientes de sincronizar.'
              : remoteDataLoaded
              ? 'Datos actualizados. Pendientes: $pendingCount'
              : 'No hay datos guardados. Conectate para la primera carga.');
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
      offlineSession = _repository.fromCache;
      notifyListeners();
      return true;
    } catch (_) {
      connectionMessage =
          'No se pudo iniciar sesion. Revisa el correo, la contrasena o la conexion.';
      notifyListeners();
      return false;
    }
  }

  /// Cierra la sesion y limpia el estado para que el proximo usuario no vea
  /// informacion del anterior.
  Future<void> signOut() async {
    await _repository.signOut();
    remoteDataLoaded = false;
    offlineSession = false;
    isLoading = false;
    connectionMessage = null;
    notifyListeners();
  }

  int get pendingCount => _repository.pendingCount;
  String? get syncError => _repository.syncError;
  bool get hasSession => _repository.hasSession;
  bool _mutating = false;
  bool get busy => isLoading || _mutating;
  Future<T> _mutate<T>(Future<T> Function() action) async {
    _mutating = true;
    try {
      return await action();
    } finally {
      _mutating = false;
      offlineSession = _repository.fromCache;
      notifyListeners();
    }
  }

  Future<void> synchronize() async {
    if (busy) return;
    await _mutate(() => _repository.synchronize(retry: true));
    await loadRemoteData();
  }

  Future<void> discardPending() async {
    await _mutate(_repository.discardPending);
    await loadRemoteData();
  }

  // ---------------------------------------------------------------------
  // Clientes
  // ---------------------------------------------------------------------

  Future<bool> addClient({
    required String name,
    required String phone,
    String notes = '',
  }) async {
    final savedRemotely = await _mutate(
      () => _repository.addClient(
        Client(
          id: FotogestRepository.newId('cli'),
          userId: currentUserId,
          name: name.trim(),
          phone: phone.trim(),
          notes: notes.trim(),
        ),
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
    final savedRemotely = await _mutate(
      () => _repository.updateClient(
        client.copyWith(
          userId: client.userId.isEmpty ? currentUserId : client.userId,
          name: name.trim(),
          phone: phone.trim(),
          notes: notes.trim(),
        ),
      ),
    );
    notifyListeners();
    return savedRemotely;
  }

  Future<bool> deleteClient(String clientId) async {
    final deletedRemotely = await _mutate(
      () => _repository.deleteClient(clientId),
    );
    notifyListeners();
    return deletedRemotely;
  }

  // ---------------------------------------------------------------------
  // Servicios fotograficos
  // ---------------------------------------------------------------------

  Future<bool> addPackage({
    required String name,
    required String description,
    required double price,
    bool active = true,
  }) async {
    final savedRemotely = await _mutate(
      () => _repository.addPackage(
        PhotoPackage(
          id: FotogestRepository.newId('paq'),
          userId: currentUserId,
          name: name.trim(),
          description: description.trim(),
          price: price,
          active: active,
        ),
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
    final savedRemotely = await _mutate(
      () => _repository.updatePackage(
        package.copyWith(
          userId: package.userId.isEmpty ? currentUserId : package.userId,
          name: name.trim(),
          description: description.trim(),
          price: price,
          active: active,
        ),
      ),
    );
    notifyListeners();
    return savedRemotely;
  }

  Future<bool> deletePackage(String packageId) async {
    final deletedRemotely = await _mutate(
      () => _repository.deletePackage(packageId),
    );
    notifyListeners();
    return deletedRemotely;
  }

  // ---------------------------------------------------------------------
  // Eventos
  // ---------------------------------------------------------------------

  Future<bool> addEvent({
    required String clientId,
    required String packageId,
    required String type,
    required DateTime dateTime,
    required String location,
    required String status,
    required double agreedAmount,
  }) async {
    final savedRemotely = await _mutate(
      () => _repository.addEvent(
        PhotoEvent(
          id: FotogestRepository.newId('evt'),
          clientId: clientId,
          packageId: packageId,
          userId: currentUserId,
          type: type.trim(),
          dateTime: dateTime,
          location: location.trim(),
          status: status,
          agreedAmount: agreedAmount,
        ),
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
    required double agreedAmount,
  }) async {
    final savedRemotely = await _mutate(
      () => _repository.updateEvent(
        event.copyWith(
          userId: event.userId.isEmpty ? currentUserId : event.userId,
          clientId: clientId,
          packageId: packageId,
          type: type.trim(),
          dateTime: dateTime,
          location: location.trim(),
          status: status,
          agreedAmount: agreedAmount,
        ),
      ),
    );
    notifyListeners();
    return savedRemotely;
  }

  Future<bool> deleteEvent(String eventId) async {
    final deletedRemotely = await _mutate(
      () => _repository.deleteEvent(eventId),
    );
    notifyListeners();
    return deletedRemotely;
  }

  // ---------------------------------------------------------------------
  // Ventas independientes
  // ---------------------------------------------------------------------

  Future<SaleSaveResult> addSale({
    required String clientId,
    required String type,
    required String description,
    required int quantity,
    required double unitPrice,
    required DateTime soldAt,
    required String status,
    String notes = '',
  }) async {
    final sale = PhotoSale(
      id: FotogestRepository.newId('ven'),
      clientId: clientId,
      userId: currentUserId,
      type: type,
      description: description.trim(),
      quantity: quantity,
      unitPrice: unitPrice,
      soldAt: soldAt,
      status: status,
      notes: notes.trim(),
    );
    final savedRemotely = await _mutate(() => _repository.addSale(sale));
    notifyListeners();
    return SaleSaveResult(sale: sale, savedRemotely: savedRemotely);
  }

  Future<SaleSaveResult> updateSale({
    required PhotoSale sale,
    required String clientId,
    required String type,
    required String description,
    required int quantity,
    required double unitPrice,
    required DateTime soldAt,
    required String status,
    String notes = '',
  }) async {
    final updatedSale = sale.copyWith(
      userId: sale.userId.isEmpty ? currentUserId : sale.userId,
      clientId: clientId,
      type: type,
      description: description.trim(),
      quantity: quantity,
      unitPrice: unitPrice,
      soldAt: soldAt,
      status: status,
      notes: notes.trim(),
    );
    final savedRemotely = await _mutate(
      () => _repository.updateSale(updatedSale),
    );
    notifyListeners();
    return SaleSaveResult(sale: updatedSale, savedRemotely: savedRemotely);
  }

  Future<bool> deleteSale(String saleId) async {
    final deletedRemotely = await _mutate(() => _repository.deleteSale(saleId));
    notifyListeners();
    return deletedRemotely;
  }

  // ---------------------------------------------------------------------
  // Pagos
  // ---------------------------------------------------------------------

  Future<bool> addPayment({
    String eventId = '',
    String saleId = '',
    required double amount,
    required String method,
    required DateTime paidAt,
    String note = '',
  }) async {
    final savedRemotely = await _mutate(
      () => _repository.addPayment(
        Payment(
          id: FotogestRepository.newId('pag'),
          eventId: eventId,
          saleId: saleId,
          userId: currentUserId,
          amount: amount,
          method: method,
          paidAt: paidAt,
          note: note.trim(),
        ),
      ),
    );
    notifyListeners();
    return savedRemotely;
  }

  Future<bool> updatePayment({
    required Payment payment,
    String eventId = '',
    String saleId = '',
    required double amount,
    required String method,
    required DateTime paidAt,
    String note = '',
  }) async {
    final savedRemotely = await _mutate(
      () => _repository.updatePayment(
        payment.copyWith(
          userId: payment.userId.isEmpty ? currentUserId : payment.userId,
          eventId: eventId,
          saleId: saleId,
          amount: amount,
          method: method,
          paidAt: paidAt,
          note: note.trim(),
        ),
      ),
    );
    notifyListeners();
    return savedRemotely;
  }

  Future<bool> deletePayment(String paymentId) async {
    final deletedRemotely = await _mutate(
      () => _repository.deletePayment(paymentId),
    );
    notifyListeners();
    return deletedRemotely;
  }
}
