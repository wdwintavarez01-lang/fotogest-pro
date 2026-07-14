import 'package:flutter/material.dart';

import '../models/photo_event.dart';
import '../utils/formatters.dart';
import '../widgets/app_scope.dart';
import '../widgets/fotogest_bottom_nav.dart';
import '../widgets/status_chip.dart';
import 'event_form_screen.dart';
import 'payment_form_screen.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  static const routeName = '/events';

  @override
  Widget build(BuildContext context) {
    final viewModel = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Eventos'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.event_available_outlined),
        label: const Text('Nuevo'),
        onPressed: () =>
            Navigator.pushNamed(context, EventFormScreen.routeName),
      ),
      bottomNavigationBar: const FotogestBottomNav(
        currentRoute: EventsScreen.routeName,
      ),
      body: SafeArea(
        child: viewModel.events.isEmpty
            ? const Center(child: Text('No hay eventos registrados'))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: viewModel.events.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final event = viewModel.events[index];
                  final client = viewModel.clientFor(event.clientId);
                  final package = viewModel.packageFor(event.packageId);
                  final paid = viewModel.paidForEvent(event.id);
                  final pending = viewModel.pendingForEvent(event.id);

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  event.type,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              StatusChip(status: event.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(client.name),
                          const SizedBox(height: 4),
                          Text(
                            '${Formatters.date(event.dateTime)} - '
                            '${Formatters.time(event.dateTime)}',
                          ),
                          const SizedBox(height: 4),
                          Text(event.location),
                          const Divider(height: 22),
                          Text('Servicio: ${package.name}'),
                          Text('Total: ${Formatters.money(package.price)}'),
                          Text('Abonado: ${Formatters.money(paid)}'),
                          Text('Pendiente: ${Formatters.money(pending)}'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                icon: const Icon(Icons.payments_outlined),
                                label: const Text('Cobrar'),
                                onPressed: pending <= 0
                                    ? null
                                    : () => Navigator.pushNamed(
                                        context,
                                        PaymentFormScreen.routeName,
                                        arguments: PaymentFormArguments(
                                          event: event,
                                        ),
                                      ),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Editar'),
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  EventFormScreen.routeName,
                                  arguments: event,
                                ),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Eliminar'),
                                onPressed: () => _confirmDelete(context, event),
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

  Future<void> _confirmDelete(BuildContext context, PhotoEvent event) async {
    final viewModel = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final payments = viewModel.paymentsForEvent(event.id);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar evento'),
          content: Text(
            payments.isEmpty
                ? 'Esta accion quitara el evento de la agenda.'
                : 'Este evento tiene pagos registrados. Al eliminarlo tambien se eliminaran esos pagos.',
          ),
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

    final deletedRemotely = await viewModel.deleteEvent(event.id);
    if (!context.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          deletedRemotely
              ? 'Evento eliminado Online'
              : 'Evento eliminado en modo local',
        ),
      ),
    );
  }
}
