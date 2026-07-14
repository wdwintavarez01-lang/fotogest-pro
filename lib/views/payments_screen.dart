import 'package:flutter/material.dart';

import '../models/payment.dart';
import '../utils/formatters.dart';
import '../widgets/app_scope.dart';
import '../widgets/fotogest_bottom_nav.dart';
import 'payment_form_screen.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  static const routeName = '/payments';

  @override
  Widget build(BuildContext context) {
    final viewModel = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Pagos'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_card_outlined),
        label: const Text('Cobrar'),
        onPressed: () =>
            Navigator.pushNamed(context, PaymentFormScreen.routeName),
      ),
      bottomNavigationBar: const FotogestBottomNav(
        currentRoute: PaymentsScreen.routeName,
      ),
      body: SafeArea(
        child: viewModel.payments.isEmpty
            ? const Center(child: Text('No hay pagos registrados'))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: viewModel.payments.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final payment = viewModel.payments[index];
                  final event = viewModel.eventFor(payment.eventId);
                  final client = viewModel.clientFor(event.clientId);
                  final service = viewModel.packageFor(event.packageId);

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.receipt_long_outlined),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  Formatters.money(payment.amount),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              Text(Formatters.date(payment.paidAt)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('${client.name} - ${event.type}'),
                          Text(service.name),
                          Text('Metodo: ${_methodLabel(payment.method)}'),
                          if (payment.note.isNotEmpty) Text(payment.note),
                          const Divider(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Editar'),
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    PaymentFormScreen.routeName,
                                    arguments: PaymentFormArguments(
                                      payment: payment,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Eliminar'),
                                  onPressed: () =>
                                      _confirmDelete(context, payment),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Payment payment) async {
    final viewModel = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar pago'),
          content: const Text('Esta accion quitara el pago registrado.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final deletedRemotely = await viewModel.deletePayment(payment.id);
    if (!context.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          deletedRemotely
              ? 'Pago eliminado Online'
              : 'Pago eliminado en modo local',
        ),
      ),
    );
  }

  String _methodLabel(String value) {
    return switch (value) {
      'efectivo' => 'Efectivo',
      'transferencia' => 'Transferencia',
      'tarjeta' => 'Tarjeta',
      'otro' => 'Otro',
      _ => value,
    };
  }
}
