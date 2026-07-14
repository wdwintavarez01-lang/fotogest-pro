import 'dart:async';

import 'package:flutter/material.dart';

import 'repositories/fotogest_repository.dart';
import 'services/firebase_service.dart';
import 'utils/app_theme.dart';
import 'viewmodels/fotogest_view_model.dart';
import 'views/client_form_screen.dart';
import 'views/clients_screen.dart';
import 'views/dashboard_screen.dart';
import 'views/event_form_screen.dart';
import 'views/events_screen.dart';
import 'views/login_screen.dart';
import 'views/package_form_screen.dart';
import 'views/packages_screen.dart';
import 'views/payment_form_screen.dart';
import 'views/payments_screen.dart';
import 'views/sale_form_screen.dart';
import 'views/sales_screen.dart';
import 'widgets/app_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await FirebaseService.initialize();
  runApp(FotoGestApp(firebaseReady: firebaseReady));
}

class FotoGestApp extends StatefulWidget {
  const FotoGestApp({super.key, this.firebaseReady = false});

  final bool firebaseReady;

  @override
  State<FotoGestApp> createState() => _FotoGestAppState();
}

class _FotoGestAppState extends State<FotoGestApp> {
  late final FotogestViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = FotogestViewModel(
      widget.firebaseReady
          ? FotogestRepository.firebase()
          : FotogestRepository(),
    );
    unawaited(viewModel.loadRemoteData());
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
          EventFormScreen.routeName: (_) => const EventFormScreen(),
          PaymentsScreen.routeName: (_) => const PaymentsScreen(),
          PaymentFormScreen.routeName: (_) => const PaymentFormScreen(),
          PackagesScreen.routeName: (_) => const PackagesScreen(),
          PackageFormScreen.routeName: (_) => const PackageFormScreen(),
          SalesScreen.routeName: (_) => const SalesScreen(),
          SaleFormScreen.routeName: (_) => const SaleFormScreen(),
        },
      ),
    );
  }
}
