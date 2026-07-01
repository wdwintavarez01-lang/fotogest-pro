import 'package:flutter/foundation.dart';

import '../models/client.dart';
import '../models/payment.dart';
import '../models/photo_event.dart';
import '../models/photo_package.dart';
import '../repositories/fotogest_repository.dart';

class FotogestViewModel extends ChangeNotifier {
  FotogestViewModel(this._repository);

  final FotogestRepository _repository;

  List<Client> get clients => _repository.getClients();
  List<PhotoEvent> get events => _repository.getEvents();
  List<PhotoPackage> get packages => _repository.getPackages();
  List<Payment> get payments => _repository.getPayments();

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
      total += (package.price - paid).clamp(0, package.price);
    }
    return total;
  }

  Client clientFor(String id) {
    return clients.firstWhere((client) => client.id == id);
  }

  PhotoPackage packageFor(String id) {
    return packages.firstWhere((package) => package.id == id);
  }

  List<Payment> paymentsForEvent(String eventId) {
    return payments.where((payment) => payment.eventId == eventId).toList();
  }

  double paidForEvent(String eventId) {
    return paymentsForEvent(eventId).fold(0, (sum, payment) {
      return sum + payment.amount;
    });
  }

  void addClient({
    required String name,
    required String phone,
    String notes = '',
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _repository.addClient(
      Client(
        id: 'cli_$timestamp',
        userId: 'usr_001',
        name: name.trim(),
        phone: phone.trim(),
        notes: notes.trim(),
      ),
    );
    notifyListeners();
  }
}
