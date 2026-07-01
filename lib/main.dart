import 'package:flutter/material.dart';

import 'repositories/fotogest_repository.dart';
import 'utils/app_theme.dart';
import 'viewmodels/fotogest_view_model.dart';
import 'views/client_form_screen.dart';
import 'views/clients_screen.dart';
import 'views/dashboard_screen.dart';
import 'views/events_screen.dart';
import 'views/login_screen.dart';
import 'views/packages_screen.dart';
import 'views/payments_screen.dart';
import 'widgets/app_scope.dart';

void main() {
  runApp(const FotoGestApp());
}

class FotoGestApp extends StatefulWidget {
  const FotoGestApp({super.key});

  @override
  State<FotoGestApp> createState() => _FotoGestAppState();
}

class _FotoGestAppState extends State<FotoGestApp> {
  late final FotogestViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = FotogestViewModel(FotogestRepository());
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      viewModel: viewModel,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FotoGest Pro',
        theme: AppTheme.light,
        builder: (context, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth > 430
                  ? 430.0
                  : constraints.maxWidth;
              return Align(
                alignment: Alignment.topLeft,
                child: SizedBox(width: width, child: child),
              );
            },
          );
        },
        initialRoute: LoginScreen.routeName,
        routes: {
          LoginScreen.routeName: (_) => const LoginScreen(),
          DashboardScreen.routeName: (_) => const DashboardScreen(),
          ClientsScreen.routeName: (_) => const ClientsScreen(),
          ClientFormScreen.routeName: (_) => const ClientFormScreen(),
          EventsScreen.routeName: (_) => const EventsScreen(),
          PaymentsScreen.routeName: (_) => const PaymentsScreen(),
          PackagesScreen.routeName: (_) => const PackagesScreen(),
        },
      ),
    );
  }
}
