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
  const FotoGestApp({super.key, this.firebaseReady = false, this.repository});

  final bool firebaseReady;
  final FotogestRepository? repository;

  @override
  State<FotoGestApp> createState() => _FotoGestAppState();
}

class _FotoGestAppState extends State<FotoGestApp> with WidgetsBindingObserver {
  Timer? refreshTimer;
  late final FotogestViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = FotogestViewModel(
      widget.repository ??
          (widget.firebaseReady
              ? FotogestRepository.firebase()
              : FotogestRepository()),
    );
    WidgetsBinding.instance.addObserver(this);
    unawaited(viewModel.loadRemoteData());
    refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (viewModel.hasSession && !viewModel.busy) {
        unawaited(viewModel.loadRemoteData());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        viewModel.hasSession &&
        !viewModel.busy) {
      unawaited(viewModel.loadRemoteData());
    }
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    viewModel.dispose();
    super.dispose();
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
                child: SizedBox(
                  width: width,
                  child: AnimatedBuilder(
                    animation: viewModel,
                    builder: (context, _) => Column(
                      children: [
                        if (viewModel.pendingCount > 0 ||
                            viewModel.syncError != null ||
                            viewModel.offlineSession)
                          Material(
                            color: viewModel.syncError != null
                                ? Colors.red.shade100
                                : Colors.amber.shade100,
                            child: SafeArea(
                              bottom: false,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Text(
                                  viewModel.syncError != null
                                      ? 'Cambio rechazado. Revisa Sincronizacion en Inicio.'
                                      : viewModel.pendingCount > 0
                                      ? '${viewModel.pendingCount} cambios pendientes. Saldos por confirmar.'
                                      : 'Sin conexion. Mostrando datos guardados.',
                                ),
                              ),
                            ),
                          ),
                        Expanded(child: child ?? const SizedBox.shrink()),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        initialRoute: viewModel.hasSession
            ? DashboardScreen.routeName
            : LoginScreen.routeName,
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
