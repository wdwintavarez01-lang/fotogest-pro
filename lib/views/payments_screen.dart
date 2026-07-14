import 'package:flutter/material.dart';

import '../models/payment.dart';
import '../models/photo_event.dart';
import '../utils/app_theme.dart';
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
    final pendingEvents = viewModel.pendingPaymentEvents;
    final paidEvents = viewModel.paidEvents;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Cobros y pagos'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pendientes'),
              Tab(text: 'Historial'),
            ],
          ),
        ),
        bottomNavigationBar: const FotogestBottomNav(
          currentRoute: PaymentsScreen.routeName,
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _PendingPaymentsTab(events: pendingEvents),
              _PaymentHistoryTab(events: paidEvents),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingPaymentsTab extends StatelessWidget {
  const _PendingPaymentsTab({required this.events});

  final List<PhotoEvent> events;

  @override
  Widget build(BuildContext context) {
    final viewModel = AppScope.of(context);
    if (events.isEmpty) {
      return const _EmptyState(
        icon: Icons.check_circle_outline,
        title: 'No hay cobros pendientes',
        message: 'Los eventos con saldo completo apareceran en Historial.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: events.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _CollectionSummary(events: events);
        }
        final event = events[index - 1];
        final client = viewModel.clientFor(event.clientId);
        final service = viewModel.packageFor(event.packageId);
        final paid = viewModel.paidForEvent(event.id);
        final pending = viewModel.pendingForEvent(event.id);
        final progress = service.price <= 0 ? 0.0 : paid / service.price;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        client.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(Formatters.date(event.dateTime)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${event.type} - ${service.name}'),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: AppTheme.line,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _AmountLabel(
                        label: 'Total',
                        amount: service.price,
                      ),
                    ),
                    Expanded(
                      child: _AmountLabel(label: 'Abonado', amount: paid),
                    ),
                    Expanded(
                      child: _AmountLabel(
                        label: 'Pendiente',
                        amount: pending,
                        highlight: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Abonar'),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    PaymentFormScreen.routeName,
                    arguments: PaymentFormArguments(event: event),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PaymentHistoryTab extends StatelessWidget {
  const _PaymentHistoryTab({required this.events});

  final List<PhotoEvent> events;

  @override
  Widget build(BuildContext context) {
    final viewModel = AppScope.of(context);
    if (events.isEmpty) {
      return const _EmptyState(
        icon: Icons.history_outlined,
        title: 'Todavia no hay historial',
        message: 'Cuando un evento quede pagado completo, aparecera aqui.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: events.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final event = events[index];
        final client = viewModel.clientFor(event.clientId);
        final service = viewModel.packageFor(event.packageId);
        final payments = viewModel.paymentsForEvent(event.id);
        final lastPayment = viewModel.lastPaymentForEvent(event.id);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_outlined, color: AppTheme.teal),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        client.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(Formatters.money(service.price)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${event.type} - ${service.name}'),
                Text(
                  lastPayment == null
                      ? 'Pagado completo'
                      : 'Pagado el ${Formatters.date(lastPayment.paidAt)}',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Text(
                    payments.length == 1
                        ? 'Ver abono'
                        : 'Ver ${payments.length} abonos',
                  ),
                  onPressed: () => _showPaymentHistory(context, event),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPaymentHistory(
    BuildContext context,
    PhotoEvent event,
  ) async {
    final viewModel = AppScope.of(context);
    final client = viewModel.clientFor(event.clientId);
    final service = viewModel.packageFor(event.packageId);
    final payments = viewModel.paymentsForEvent(event.id)
      ..sort((left, right) => right.paidAt.compareTo(left.paidAt));

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  client.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text('${event.type} - ${service.name}'),
                const Divider(height: 24),
                for (final payment in payments)
                  _PaymentHistoryRow(payment: payment),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CollectionSummary extends StatelessWidget {
  const _CollectionSummary({required this.events});

  final List<PhotoEvent> events;

  @override
  Widget build(BuildContext context) {
    final viewModel = AppScope.of(context);
    final pendingTotal = events.fold<double>(0, (total, event) {
      return total + viewModel.pendingForEvent(event.id);
    });

    return Card(
      color: AppTheme.ink,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.priority_high_outlined, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cobros pendientes',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  Text(
                    '${events.length} evento(s) por cobrar',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Text(
              Formatters.money(pendingTotal),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountLabel extends StatelessWidget {
  const _AmountLabel({
    required this.label,
    required this.amount,
    this.highlight = false,
  });

  final String label;
  final double amount;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppTheme.coral : AppTheme.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(
          Formatters.money(amount),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _PaymentHistoryRow extends StatelessWidget {
  const _PaymentHistoryRow({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.payments_outlined),
      title: Text(Formatters.money(payment.amount)),
      subtitle: Text(
        '${_methodLabel(payment.method)} - ${Formatters.date(payment.paidAt)}',
      ),
      trailing: payment.note.isEmpty
          ? null
          : const Icon(Icons.sticky_note_2_outlined),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 46),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
