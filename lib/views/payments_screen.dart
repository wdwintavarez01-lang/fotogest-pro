import 'package:flutter/material.dart';

import '../utils/formatters.dart';
import '../widgets/app_scope.dart';
import '../widgets/fotogest_bottom_nav.dart';

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
      bottomNavigationBar: const FotogestBottomNav(
        currentRoute: PaymentsScreen.routeName,
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: viewModel.payments.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final payment = viewModel.payments[index];
            final event = viewModel.events.firstWhere(
              (item) => item.id == payment.eventId,
            );
            final client = viewModel.clientFor(event.clientId);

            return Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(Formatters.money(payment.amount)),
                subtitle: Text(
                  '${client.name} - ${event.type}\n'
                  '${payment.method} - ${Formatters.date(payment.paidAt)}',
                ),
                isThreeLine: true,
              ),
            );
          },
        ),
      ),
    );
  }
}
