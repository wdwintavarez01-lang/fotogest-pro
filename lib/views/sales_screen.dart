import 'package:flutter/material.dart';

import '../models/photo_sale.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_scope.dart';
import '../widgets/fotogest_bottom_nav.dart';
import 'payment_form_screen.dart';
import 'sale_form_screen.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  static const routeName = '/sales';

  @override
  Widget build(BuildContext context) {
    final viewModel = AppScope.of(context);
    final sales = viewModel.sales;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Ventas'),
      ),
      bottomNavigationBar: const FotogestBottomNav(
        currentRoute: SalesScreen.routeName,
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_shopping_cart_outlined),
        label: const Text('Nueva'),
        onPressed: () => Navigator.pushNamed(context, SaleFormScreen.routeName),
      ),
      body: SafeArea(
        child: sales.isEmpty
            ? const Center(child: Text('No hay ventas registradas'))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: sales.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final sale = sales[index];
                  final client = viewModel.clientFor(sale.clientId);
                  final paid = viewModel.paidForSale(sale.id);
                  final pending = viewModel.pendingForSale(sale.id);
                  final progress = sale.total <= 0 ? 0.0 : paid / sale.total;
                  final hasPayments = viewModel
                      .paymentsForSale(sale.id)
                      .isNotEmpty;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.shopping_bag_outlined),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  client.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              _SaleStatusChip(
                                paid:
                                    pending <= 0 && sale.status != 'cancelado',
                                canceled: sale.status == 'cancelado',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(_saleTypeLabel(sale.type)),
                          Text(sale.description),
                          const SizedBox(height: 8),
                          Text(
                            '${sale.quantity} x ${Formatters.money(sale.unitPrice)}',
                          ),
                          const SizedBox(height: 10),
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
                                  amount: sale.total,
                                ),
                              ),
                              Expanded(
                                child: _AmountLabel(
                                  label: 'Abonado',
                                  amount: paid,
                                ),
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
                          if (sale.notes.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(sale.notes),
                          ],
                          const Divider(height: 24),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                icon: const Icon(Icons.payments_outlined),
                                label: const Text('Abonar'),
                                onPressed:
                                    pending <= 0 || sale.status == 'cancelado'
                                    ? null
                                    : () => Navigator.pushNamed(
                                        context,
                                        PaymentFormScreen.routeName,
                                        arguments: PaymentFormArguments(
                                          sale: sale,
                                        ),
                                      ),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Editar'),
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  SaleFormScreen.routeName,
                                  arguments: sale,
                                ),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Eliminar'),
                                onPressed: hasPayments
                                    ? null
                                    : () => _confirmDelete(context, sale),
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

  Future<void> _confirmDelete(BuildContext context, PhotoSale sale) async {
    final viewModel = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar venta'),
          content: const Text('Esta accion quitara la venta de la lista.'),
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

    final deletedRemotely = await viewModel.deleteSale(sale.id);
    if (!context.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          deletedRemotely
              ? 'Venta eliminada Online'
              : 'Venta eliminada en modo local',
        ),
      ),
    );
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
}

class _SaleStatusChip extends StatelessWidget {
  const _SaleStatusChip({required this.paid, required this.canceled});

  final bool paid;
  final bool canceled;

  @override
  Widget build(BuildContext context) {
    final color = canceled
        ? AppTheme.coral
        : paid
        ? AppTheme.teal
        : AppTheme.amber;
    final label = canceled
        ? 'Cancelada'
        : paid
        ? 'Pagada'
        : 'Pendiente';

    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(
        canceled
            ? Icons.cancel_outlined
            : paid
            ? Icons.check_circle_outline
            : Icons.schedule_outlined,
        color: color,
        size: 18,
      ),
      label: Text(label),
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
