import 'package:flutter/material.dart';

import '../views/clients_screen.dart';
import '../views/dashboard_screen.dart';
import '../views/events_screen.dart';
import '../views/packages_screen.dart';
import '../views/payments_screen.dart';

class FotogestBottomNav extends StatelessWidget {
  const FotogestBottomNav({super.key, required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final routes = [
      DashboardScreen.routeName,
      ClientsScreen.routeName,
      EventsScreen.routeName,
      PackagesScreen.routeName,
      PaymentsScreen.routeName,
    ];
    final index = routes.indexOf(currentRoute).clamp(0, routes.length - 1);

    return NavigationBar(
      selectedIndex: index,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Clientes',
        ),
        NavigationDestination(
          icon: Icon(Icons.event_note_outlined),
          selectedIcon: Icon(Icons.event_note),
          label: 'Eventos',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: 'Servicios',
        ),
        NavigationDestination(
          icon: Icon(Icons.payments_outlined),
          selectedIcon: Icon(Icons.payments),
          label: 'Pagos',
        ),
      ],
      onDestinationSelected: (selected) {
        final route = routes[selected];
        if (route != currentRoute) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}
