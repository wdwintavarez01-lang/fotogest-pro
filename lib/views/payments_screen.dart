import 'package:flutter/material.dart';

import '../models/payment.dart';
import '../models/photo_event.dart';
import '../models/photo_sale.dart';
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
    final pendingSales = viewModel.pendingSales;
    final paidEvents = viewModel.paidEvents;
    final paidSales = viewModel.paidSales;

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
              _PendingPaymentsTab(events: pendingEvents, sales: pendingSales),
              _PaymentHistoryTab(events: paidEvents, sales: paidSales),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingPaymentsTab extends StatelessWidget {
  const _PendingPaymentsTab({required this.events, required this.sales});

  final List<PhotoEvent> events;
  final List<PhotoSale> sales;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty && sales.isEmpty) {
      return const _EmptyState(
        icon: Icons.check_circle_outline,
        title: 'No hay cobros pendientes',
        message: 'Los eventos y ventas pagados apareceran en Historial.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _CollectionSummary(events: events, sales: sales),
        if (events.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _SectionTitle(title: 'Eventos por cobrar'),
          const SizedBox(height: 10),
          for (final event in events) ...[
            _PendingEventCard(event: event),
            const SizedBox(height: 10),
          ],
        ],
        if (sales.isNotEmpty) ...[
          const SizedBox(height: 6),
          const _SectionTitle(title: 'Ventas por cobrar'),
          const SizedBox(height: 10),
          for (final sale in sales) ...[
            _PendingSaleCard(sale: sale),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _PaymentHistoryTab extends StatelessWidget {
  const _PaymentHistoryTab({required this.events, required this.sales});

  final List<PhotoEvent> events;
  final List<PhotoSale> sales;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty && sales.isEmpty) {
      return const _EmptyState(
        icon: Icons.history_outlined,
        title: 'Todavia no hay historial',
        message: 'Cuando una cuenta quede pagada completa, aparecera aqui.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (events.isNotEmpty) ...[
          const _SectionTitle(title: 'Eventos pagados'),
          const SizedBox(height: 10),
          for (final event in events) ...[
            _PaidEventCard(event: event),
            const SizedBox(height: 10),
          ],
        ],
        if (sales.isNotEmpty) ...[
          const SizedBox(height: 6),
          const _SectionTitle(title: 'Ventas pagadas'),
          const SizedBox(height: 10),
          for (final sale in sales) ...[
            _PaidSaleCard(sale: sale),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _PendingEventCard extends StatelessWidget {
  const _PendingEventCard({required this.event});

  final PhotoEvent event;

  @override
  Widget build(BuildContext context) {
    final viewModel = AppScope.of(context);
    final client = viewModel.clientFor(event.clientId);
    final service = viewModel.packageFor(event.packageId);
    final paid = viewModel.paidForEvent(event.id);
    final pending = viewModel.pendingForEvent(event.id);
    final progress = service.price <= 0 ? 0.0 : paid / service.price;

    return _PendingCard(
      icon: Icons.event_note_outlined,
      title: client.name,
      subtitle: '${event.type} - ${service.name}',
      detail: Formatters.date(event.dateTime),
      total: service.price,
      paid: paid,
      pending: pending,
      progress: progress,
      onPay: () => Navigator.pushNamed(
        context,
        PaymentFormScreen.routeName,
        arguments: PaymentFormArguments(event: event),
      ),
    );
  }
}

class _PendingSaleCard extends StatelessWidget {
  const _PendingSaleCard({required this.sale});

  final PhotoSale sale;

  @override
  Widget build(BuildContext context) {
    final viewModel = AppScope.of(context);
    final client = viewModel.clientFor(sale.clientId);
    final paid = viewModel.paidForSale(sale.id);
    final pending = viewModel.pendingForSale(sale.id);
    final progress = sale.total <= 0 ? 0.0 : paid / sale.total;

    return _PendingCard(
      icon: Icons.shopping_bag_outlined,
      title: client.name,
      subtitle: sale.description,
      detail: _saleTypeLabel(sale.type),
      total: sale.total,
      paid: paid,
      pending: pending,
      progress: progress,
      onPay: () => Navigator.pushNamed(
        context,
        PaymentFormScreen.routeName,
        arguments: PaymentFormArguments(sale: sale),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.total,
    required this.paid,
    required this.pending,
    required this.progress,
    required this.onPay,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String detail;
  final double total;
  final double paid;
  final double pending;
  final double progress;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(detail),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle),
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
                  child: _AmountLabel(label: 'Total', amount: total),
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
              onPressed: onPay,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaidEventCard extends StatelessWidget {
  const _PaidEventCard({required this.event});

  final PhotoEvent event;

  @override
  Widget build(BuildContext context) {
    final viewModel = AppScope.of(context);
    final client = viewModel.clientFor(event.clientId);
    final service = viewModel.packageFor(event.packageId);
    final payments = viewModel.paymentsForEvent(event.id);
    final lastPayment = viewModel.lastPaymentForEvent(event.id);

    return _PaidCard(
      icon: Icons.event_available_outlined,
      title: client.name,
      subtitle: '${event.type} - ${service.name}',
      amount: service.price,
      paidAt: lastPayment?.paidAt,
      payments: payments,
    );
  }
}

class _PaidSaleCard extends StatelessWidget {
  const _PaidSaleCard({required this.sale});

  final PhotoSale sale;

  @override
  Widget build(BuildContext context) {
    final viewModel = AppScope.of(context);
    final client = viewModel.clientFor(sale.clientId);
    final payments = viewModel.paymentsForSale(sale.id);
    final lastPayment = viewModel.lastPaymentForSale(sale.id);

    return _PaidCard(
      icon: Icons.shopping_bag_outlined,
      title: client.name,
      subtitle: sale.description,
      amount: sale.total,
      paidAt: lastPayment?.paidAt,
      payments: payments,
    );
  }
}

class _PaidCard extends StatelessWidget {
  const _PaidCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.paidAt,
    required this.payments,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime? paidAt;
  final List<Payment> payments;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.teal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(Formatters.money(amount)),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle),
            Text(
              paidAt == null
                  ? 'Pagado completo'
                  : 'Pagado el ${Formatters.date(paidAt!)}',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.receipt_long_outlined),
              label: Text(
                payments.length == 1
                    ? 'Ver abono'
                    : 'Ver ${payments.length} abonos',
              ),
              onPressed: () => _showPaymentHistory(context, payments),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPaymentHistory(
    BuildContext context,
    List<Payment> sourcePayments,
  ) async {
    final payments = [...sourcePayments]
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
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(subtitle),
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
  const _CollectionSummary({required this.events, required this.sales});

  final List<PhotoEvent> events;
  final List<PhotoSale> sales;

  @override
  Widget build(BuildContext context) {
    final viewModel = AppScope.of(context);
    final pendingTotal =
        events.fold<double>(0, (total, event) {
          return total + viewModel.pendingForEvent(event.id);
        }) +
        sales.fold<double>(0, (total, sale) {
          return total + viewModel.pendingForSale(sale.id);
        });
    final count = events.length + sales.length;

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
                    '$count cuenta(s) por cobrar',
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
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

String _saleTypeLabel(String value) {
  return switch (value) {
    'foto_individual' => 'Foto individual',
    'impresion' => 'Impresion',
    'edicion' => 'Edicion',
    'retoque' => 'Retoque',
    'sesion_rapida' => 'Sesion rapida',
    'servicio' => 'Servicio suelto',
    'otro' => 'Otro',
    _ => value,
  };
}
