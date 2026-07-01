import '../models/app_user.dart';
import '../models/client.dart';
import '../models/payment.dart';
import '../models/photo_event.dart';
import '../models/photo_package.dart';

class FotogestRepository {
  final List<AppUser> _users = const [
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

  final List<Client> _clients = [
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

  final List<PhotoPackage> _packages = const [
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

  final List<PhotoEvent> _events = [
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

  final List<Payment> _payments = [
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

  List<AppUser> getUsers() => List.unmodifiable(_users);
  List<Client> getClients() => List.unmodifiable(_clients);
  List<PhotoEvent> getEvents() => List.unmodifiable(_events);
  List<PhotoPackage> getPackages() => List.unmodifiable(_packages);
  List<Payment> getPayments() => List.unmodifiable(_payments);

  void addClient(Client client) {
    _clients.insert(0, client);
  }
}
