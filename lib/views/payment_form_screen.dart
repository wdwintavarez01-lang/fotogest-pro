import 'package:flutter/material.dart';

import '../models/photo_event.dart';
import '../models/photo_sale.dart';
import '../utils/formatters.dart';
import '../widgets/app_scope.dart';
import 'event_form_screen.dart';
import 'sale_form_screen.dart';

class PaymentFormArguments {
  const PaymentFormArguments({this.event, this.sale});

  final PhotoEvent? event;
  final PhotoSale? sale;
}

class PaymentFormScreen extends StatefulWidget {
  const PaymentFormScreen({super.key});

  static const routeName = '/payments/new';

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  String? selectedTargetKey;
  String method = 'efectivo';
  DateTime paidAt = DateTime.now();
  bool didLoadArguments = false;
  bool isSaving = false;

  static const methods = ['efectivo', 'transferencia', 'tarjeta', 'otro'];

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = AppScope.of(context);
    final targets = [
      for (final event in viewModel.pendingPaymentEvents)
        _PaymentTarget.event(
          event: event,
          clientName: viewModel.clientFor(event.clientId).name,
          description: event.type,
          pending: viewModel.pendingForEvent(event.id),
        ),
      for (final sale in viewModel.pendingSales)
        _PaymentTarget.sale(
          sale: sale,
          clientName: viewModel.clientFor(sale.clientId).name,
          description: sale.description,
          pending: viewModel.pendingForSale(sale.id),
        ),
    ];

    if (!didLoadArguments) {
      didLoadArguments = true;
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments is PaymentFormArguments) {
        if (arguments.event != null) {
          selectedTargetKey = 'event:${arguments.event!.id}';
        }
        if (arguments.sale != null) {
          selectedTargetKey = 'sale:${arguments.sale!.id}';
        }
      } else if (arguments is PhotoEvent) {
        selectedTargetKey = 'event:${arguments.id}';
      } else if (arguments is PhotoSale) {
        selectedTargetKey = 'sale:${arguments.id}';
      }

      if (!targets.any((target) => target.key == selectedTargetKey)) {
        selectedTargetKey = targets.isEmpty ? null : targets.first.key;
      }
    }

    final selectedTarget = _selectedTarget(targets, selectedTargetKey);
    final pending = selectedTarget?.pending ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar abono')),
      body: SafeArea(
        child: targets.isEmpty
            ? _MissingEventState()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: selectedTargetKey,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Cuenta a cobrar',
                            prefixIcon: Icon(Icons.account_balance_wallet),
                          ),
                          items: [
                            for (final target in targets)
                              DropdownMenuItem(
                                value: target.key,
                                child: Text(
                                  target.title,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedTargetKey = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Selecciona un evento';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        if (selectedTarget != null)
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.account_balance_wallet),
                              title: const Text('Saldo pendiente'),
                              subtitle: Text(selectedTarget.subtitle),
                              trailing: Text(
                                Formatters.money(pending),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: amountController,
                          decoration: const InputDecoration(
                            labelText: 'Monto a abonar',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final amount = _parseAmount(value ?? '');
                            if (amount == null || amount <= 0) {
                              return 'Escribe un monto valido';
                            }
                            if (amount > pending) {
                              return 'El monto supera lo pendiente';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: method,
                          decoration: const InputDecoration(
                            labelText: 'Metodo de pago',
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                          items: [
                            for (final item in methods)
                              DropdownMenuItem(
                                value: item,
                                child: Text(_methodLabel(item)),
                              ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              method = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.today_outlined),
                            title: const Text('Fecha de pago'),
                            subtitle: Text(Formatters.date(paidAt)),
                            trailing: const Icon(Icons.edit_calendar_outlined),
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: noteController,
                          decoration: const InputDecoration(
                            labelText: 'Nota',
                            prefixIcon: Icon(Icons.notes_outlined),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          icon: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            isSaving ? 'Guardando...' : 'Guardar abono',
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final navigator = Navigator.of(context);
                                  setState(() {
                                    isSaving = true;
                                  });
                                  final savedRemotely = await viewModel
                                      .addPayment(
                                        eventId: selectedTarget!.eventId,
                                        saleId: selectedTarget.saleId,
                                        amount: _parseAmount(
                                          amountController.text,
                                        )!,
                                        method: method,
                                        paidAt: paidAt,
                                        note: noteController.text,
                                      );
                                  if (!mounted) return;
                                  setState(() {
                                    isSaving = false;
                                  });
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        savedRemotely
                                            ? 'Abono guardado Online'
                                            : 'Abono guardado en modo local',
                                      ),
                                    ),
                                  );
                                  navigator.pop();
                                },
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.close),
                          label: const Text('Cancelar'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: paidAt,
      firstDate: DateTime(2024),
      lastDate: DateTime(2032),
    );
    if (date == null) return;
    setState(() {
      paidAt = date;
    });
  }

  double? _parseAmount(String value) {
    final normalized = value.replaceAll('RD\$', '').replaceAll(',', '').trim();
    return double.tryParse(normalized);
  }

  _PaymentTarget? _selectedTarget(
    List<_PaymentTarget> targets,
    String? selectedKey,
  ) {
    for (final target in targets) {
      if (target.key == selectedKey) return target;
    }
    return null;
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

class _MissingEventState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.info_outline, size: 42),
          const SizedBox(height: 16),
          Text(
            'No hay eventos ni ventas pendientes por cobrar.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.event_note),
                  label: const Text('Evento'),
                  onPressed: () =>
                      Navigator.pushNamed(context, EventFormScreen.routeName),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Venta'),
                  onPressed: () =>
                      Navigator.pushNamed(context, SaleFormScreen.routeName),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentTarget {
  const _PaymentTarget({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.pending,
    this.eventId = '',
    this.saleId = '',
  });

  factory _PaymentTarget.event({
    required PhotoEvent event,
    required String clientName,
    required String description,
    required double pending,
  }) {
    return _PaymentTarget(
      key: 'event:${event.id}',
      title: '$clientName - $description',
      subtitle: 'Evento fotografico',
      pending: pending,
      eventId: event.id,
    );
  }

  factory _PaymentTarget.sale({
    required PhotoSale sale,
    required String clientName,
    required String description,
    required double pending,
  }) {
    return _PaymentTarget(
      key: 'sale:${sale.id}',
      title: '$clientName - $description',
      subtitle: 'Venta independiente',
      pending: pending,
      saleId: sale.id,
    );
  }

  final String key;
  final String title;
  final String subtitle;
  final double pending;
  final String eventId;
  final String saleId;
}
