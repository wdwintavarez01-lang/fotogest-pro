import 'package:flutter/material.dart';

import '../models/payment.dart';
import '../models/photo_event.dart';
import '../utils/formatters.dart';
import '../viewmodels/fotogest_view_model.dart';
import '../widgets/app_scope.dart';
import 'event_form_screen.dart';

class PaymentFormArguments {
  const PaymentFormArguments({this.event, this.payment});

  final PhotoEvent? event;
  final Payment? payment;
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
  Payment? payment;
  String? selectedEventId;
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
    final events = viewModel.events;

    if (!didLoadArguments) {
      didLoadArguments = true;
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments is PaymentFormArguments) {
        payment = arguments.payment;
        selectedEventId = arguments.payment?.eventId ?? arguments.event?.id;
        if (arguments.payment != null) {
          amountController.text = arguments.payment!.amount.toStringAsFixed(0);
          noteController.text = arguments.payment!.note;
          method = arguments.payment!.method;
          paidAt = arguments.payment!.paidAt;
          if (!methods.contains(method)) {
            method = 'otro';
          }
        }
      } else if (arguments is PhotoEvent) {
        selectedEventId = arguments.id;
      } else if (arguments is Payment) {
        payment = arguments;
        selectedEventId = arguments.eventId;
        amountController.text = arguments.amount.toStringAsFixed(0);
        noteController.text = arguments.note;
        method = arguments.method;
        paidAt = arguments.paidAt;
        if (!methods.contains(method)) {
          method = 'otro';
        }
      }

      selectedEventId ??= events.isEmpty ? null : events.first.id;
    }

    final isEditing = payment != null;
    final selectedEvent = selectedEventId == null
        ? null
        : viewModel.eventFor(selectedEventId!);
    final pending = selectedEvent == null
        ? 0.0
        : _availableAmount(viewModel, selectedEvent.id);

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar pago' : 'Registrar pago')),
      body: SafeArea(
        child: events.isEmpty
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
                          initialValue: selectedEventId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Evento a cobrar',
                            prefixIcon: Icon(Icons.event_note_outlined),
                          ),
                          items: [
                            for (final event in events)
                              DropdownMenuItem(
                                value: event.id,
                                child: Text(
                                  '${viewModel.clientFor(event.clientId).name} - '
                                  '${event.type}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedEventId = value;
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
                        if (selectedEvent != null)
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.account_balance_wallet),
                              title: const Text('Disponible para cobrar'),
                              subtitle: Text(
                                '${viewModel.clientFor(selectedEvent.clientId).name} - '
                                '${viewModel.packageFor(selectedEvent.packageId).name}',
                              ),
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
                            labelText: 'Monto cobrado',
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
                            isSaving
                                ? 'Guardando...'
                                : isEditing
                                ? 'Actualizar pago'
                                : 'Guardar pago',
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
                                  final savedRemotely = isEditing
                                      ? await viewModel.updatePayment(
                                          payment: payment!,
                                          eventId: selectedEventId!,
                                          amount: _parseAmount(
                                            amountController.text,
                                          )!,
                                          method: method,
                                          paidAt: paidAt,
                                          note: noteController.text,
                                        )
                                      : await viewModel.addPayment(
                                          eventId: selectedEventId!,
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
                                            ? 'Pago guardado Online'
                                            : 'Pago guardado en modo local',
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

  double _availableAmount(FotogestViewModel viewModel, String eventId) {
    final currentAmount = payment?.eventId == eventId ? payment!.amount : 0.0;
    return viewModel.pendingForEvent(eventId) + currentAmount;
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
            'Antes de registrar un pago necesitas tener al menos un evento.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.event_note),
            label: const Text('Crear evento'),
            onPressed: () =>
                Navigator.pushNamed(context, EventFormScreen.routeName),
          ),
        ],
      ),
    );
  }
}
