import 'package:flutter_test/flutter_test.dart';
import 'package:fotogest_pro/models/client.dart';
import 'package:fotogest_pro/models/photo_event.dart';
import 'package:fotogest_pro/models/photo_package.dart';
import 'package:fotogest_pro/models/photo_sale.dart';
import 'package:fotogest_pro/models/payment.dart';
import 'package:fotogest_pro/repositories/fotogest_repository.dart';
import 'package:fotogest_pro/viewmodels/fotogest_view_model.dart';

PhotoEvent event(
  String id, {
  double amount = 1000,
  String status = 'programado',
}) => PhotoEvent(
  id: id,
  clientId: 'c1',
  packageId: 'p1',
  userId: 'u1',
  type: 'Boda',
  dateTime: DateTime(2026, 10, 15),
  location: 'Santiago',
  status: status,
  agreedAmount: amount,
);
PhotoSale sale(
  String id, {
  int quantity = 10,
  double price = 200,
  String status = 'pendiente',
}) => PhotoSale(
  id: id,
  clientId: 'c1',
  userId: 'u1',
  type: 'foto_individual',
  description: 'Prueba',
  quantity: quantity,
  unitPrice: price,
  soldAt: DateTime(2026, 10, 15),
  status: status,
);
Payment payment(
  String id,
  double amount, {
  String eventId = '',
  String saleId = '',
}) => Payment(
  id: id,
  eventId: eventId,
  saleId: saleId,
  userId: 'u1',
  amount: amount,
  method: 'efectivo',
  paidAt: DateTime(2026, 10, 15),
);
void main() {
  late FotogestRepository repository;
  late FotogestViewModel model;
  setUp(() async {
    repository = FotogestRepository.memoryForTesting();
    model = FotogestViewModel(repository);
    await repository.addClient(
      const Client(
        id: 'c1',
        userId: 'u1',
        name: 'Cliente Prueba',
        phone: '8095550101',
      ),
    );
    await repository.addPackage(
      const PhotoPackage(
        id: 'p1',
        userId: 'u1',
        name: 'Boda',
        description: 'Cobertura',
        active: true,
        price: 1000,
      ),
    );
  });
  tearDown(() => model.dispose());
  test('A01 total de venta diez unidades por doscientos', () {
    expect(sale('s1').total, 2000);
  });
  test('A02 monto acordado permanece tras cambiar el catalogo', () async {
    await repository.updatePackage(
      const PhotoPackage(
        id: 'p1',
        userId: 'u1',
        name: 'Boda',
        description: 'Cobertura',
        active: true,
        price: 1000,
      ),
    );
    await repository.addEvent(event('e1'));
    await repository.updatePackage(
      const PhotoPackage(
        id: 'p1',
        userId: 'u1',
        name: 'Boda',
        description: 'Cobertura',
        active: true,
        price: 1800,
      ),
    );
    expect(model.amountForEvent('e1'), 1000);
  });
  test('A03 abono parcial deja setecientos pendientes', () async {
    await repository.addEvent(event('e1'));
    await repository.addPayment(payment('a1', 300, eventId: 'e1'));
    expect(model.paidForEvent('e1'), 300);
    expect(model.pendingForEvent('e1'), 700);
  });
  test('A04 pago total mueve evento al historial', () async {
    await repository.addEvent(event('e1'));
    await repository.addPayment(payment('a1', 1000, eventId: 'e1'));
    expect(model.pendingPaymentEvents, isEmpty);
    expect(model.paidEvents.single.id, 'e1');
  });
  test('A05 pendientes ordenados de mayor a menor saldo', () async {
    await repository.addEvent(event('e1', amount: 1000));
    await repository.addEvent(event('e2', amount: 3000));
    expect(model.pendingPaymentEvents.map((e) => e.id).toList(), ['e2', 'e1']);
  });
  test('A06 cancelaciones excluidas del pendiente total', () async {
    await repository.addEvent(event('e1', status: 'cancelado'));
    await repository.addSale(sale('s1', status: 'cancelado'));
    expect(model.totalPending, 0);
    expect(model.activeEvents, 0);
    expect(model.pendingSales, isEmpty);
  });
  test('A07 relaciones de cliente y servicio detectadas', () async {
    await repository.updateClient(
      const Client(
        id: 'c1',
        userId: 'u1',
        name: 'Cliente Prueba',
        phone: '8095550101',
      ),
    );
    await repository.addEvent(event('e1'));
    await repository.addSale(sale('s1'));
    expect(model.hasEventsForClient('c1'), isTrue);
    expect(model.hasSalesForClient('c1'), isTrue);
    expect(model.hasEventsForPackage('p1'), isTrue);
  });
  test('A08 borrado de evento con abonos bloqueado', () async {
    await repository.addEvent(event('e1'));
    await repository.addPayment(payment('a1', 300, eventId: 'e1'));
    await expectLater(repository.deleteEvent('e1'), throwsStateError);
    expect(model.events, hasLength(1));
    expect(model.payments, hasLength(1));
  });
  test('A09 abonos de venta separados de los de evento', () async {
    await repository.addSale(sale('s1'));
    await repository.addEvent(event('e1'));
    await repository.addPayment(payment('a1', 500, saleId: 's1'));
    await repository.addPayment(payment('a2', 200, eventId: 'e1'));
    expect(model.pendingForSale('s1'), 1500);
    expect(model.pendingForEvent('e1'), 800);
    expect(model.totalPaid, 700);
  });
  test('A10 pago completo de venta aparece en historial', () async {
    await repository.addSale(sale('s1'));
    await repository.addPayment(payment('a1', 2000, saleId: 's1'));
    expect(model.pendingSales, isEmpty);
    expect(model.paidSales.single.id, 's1');
  });
  test('A11 monto cero permanece congelado', () async {
    await repository.updatePackage(
      const PhotoPackage(
        id: 'p1',
        userId: 'u1',
        name: 'Boda',
        description: 'Cobertura',
        active: true,
        price: 1800,
      ),
    );
    await repository.addEvent(event('e1', amount: 0));
    expect(model.amountForEvent('e1'), 0);
  });
  test('A12 cierre de sesion limpia listas y estado', () async {
    await repository.addEvent(event('e1'));
    await repository.addSale(sale('s1'));
    await model.signOut();
    expect(model.events, isEmpty);
    expect(model.sales, isEmpty);
    expect(model.connectionLabel, 'Sin datos');
  });
}
