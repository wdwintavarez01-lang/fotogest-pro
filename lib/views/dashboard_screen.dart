import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_scope.dart';
import '../widgets/fotogest_bottom_nav.dart';
import '../widgets/metric_tile.dart';
import '../widgets/status_chip.dart';
import 'clients_screen.dart';
import 'events_screen.dart';
import 'packages_screen.dart';
import 'payments_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const routeName = '/dashboard';

  @override
  Widget build(BuildContext context) {
    final viewModel = AppScope.of(context);
    final nextEvents = viewModel.events.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('FotoGest Pro'),
        actions: [
          IconButton(
            tooltip: 'Paquetes',
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () =>
                Navigator.pushNamed(context, PackagesScreen.routeName),
          ),
        ],
      ),
      bottomNavigationBar: const FotogestBottomNav(
        currentRoute: DashboardScreen.routeName,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text('Resumen', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.22,
              children: [
                MetricTile(
                  icon: Icons.people_alt_outlined,
                  label: 'Clientes',
                  value: '${viewModel.clients.length}',
                  color: AppTheme.ocean,
                ),
                MetricTile(
                  icon: Icons.event_available_outlined,
                  label: 'Eventos activos',
                  value: '${viewModel.activeEvents}',
                  color: AppTheme.teal,
                ),
                MetricTile(
                  icon: Icons.savings_outlined,
                  label: 'Abonado',
                  value: Formatters.money(viewModel.totalPaid),
                  color: AppTheme.coral,
                ),
                MetricTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Pendiente',
                  value: Formatters.money(viewModel.totalPending),
                  color: AppTheme.amber,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text('Cliente'),
                    onPressed: () =>
                        Navigator.pushNamed(context, ClientsScreen.routeName),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event_note),
                    label: const Text('Eventos'),
                    onPressed: () =>
                        Navigator.pushNamed(context, EventsScreen.routeName),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Agenda cercana',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            for (final event in nextEvents)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: Text(event.type),
                    subtitle: Text(
                      '${viewModel.clientFor(event.clientId).name} - '
                      '${Formatters.date(event.dateTime)} '
                      '${Formatters.time(event.dateTime)}',
                    ),
                    trailing: StatusChip(status: event.status),
                    onTap: () =>
                        Navigator.pushNamed(context, EventsScreen.routeName),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Ver pagos'),
              onPressed: () =>
                  Navigator.pushNamed(context, PaymentsScreen.routeName),
            ),
          ],
        ),
      ),
    );
  }
}
