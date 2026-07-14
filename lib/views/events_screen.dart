import 'package:flutter/material.dart';

import '../utils/formatters.dart';
import '../widgets/app_scope.dart';
import '../widgets/fotogest_bottom_nav.dart';
import '../widgets/status_chip.dart';

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
      bottomNavigationBar: const FotogestBottomNav(
        currentRoute: EventsScreen.routeName,
      ),
      body: SafeArea(
        child: viewModel.events.isEmpty
            ? const Center(child: Text('No hay eventos registrados'))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: viewModel.events.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final event = viewModel.events[index];
                  final client = viewModel.clientFor(event.clientId);
                  final package = viewModel.packageFor(event.packageId);
                  final paid = viewModel.paidForEvent(event.id);
                  final pending = (package.price - paid).clamp(
                    0,
                    package.price,
                  );

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
                          Text('Paquete: ${package.name}'),
                          Text(
                            'Pendiente: ${Formatters.money(pending.toDouble())}',
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
}
