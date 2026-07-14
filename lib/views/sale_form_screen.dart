import 'package:flutter/material.dart';

import '../models/photo_sale.dart';
import '../utils/formatters.dart';
import '../widgets/app_scope.dart';
import 'client_form_screen.dart';
import 'payment_form_screen.dart';

class SaleFormScreen extends StatefulWidget {
  const SaleFormScreen({super.key});

  static const routeName = '/sales/new';

  @override
  State<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends State<SaleFormScreen> {
  final formKey = GlobalKey<FormState>();
  final descriptionController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  final unitPriceController = TextEditingController();
  final notesController = TextEditingController();
  PhotoSale? sale;
  String? selectedClientId;
  String type = 'foto_individual';
  String status = 'pendiente';
  DateTime soldAt = DateTime.now();
  bool didLoadArguments = false;
  bool isSaving = false;
  bool isSavingAndPaying = false;

  static const saleTypes = [
    'foto_individual',
    'impresion',
    'edicion',
    'retoque',
    'sesion_rapida',
    'servicio',
    'otro',
  ];

  static const statuses = ['pendiente', 'cancelado'];

  @override
  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = AppScope.of(context);
    final clients = viewModel.clients;

    if (!didLoadArguments) {
      didLoadArguments = true;
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments is PhotoSale) {
        sale = arguments;
        selectedClientId = arguments.clientId;
        type = arguments.type;
        descriptionController.text = arguments.description;
        quantityController.text = arguments.quantity.toString();
        unitPriceController.text = arguments.unitPrice.toStringAsFixed(0);
        soldAt = arguments.soldAt;
        status = arguments.status;
        notesController.text = arguments.notes;
        if (!saleTypes.contains(type)) type = 'otro';
        if (!statuses.contains(status)) status = 'pendiente';
      } else {
        selectedClientId = clients.isEmpty ? null : clients.first.id;
      }
    }

    final isEditing = sale != null;
    final total = _currentTotal();

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar venta' : 'Nueva venta')),
      body: SafeArea(
        child: clients.isEmpty
            ? const _MissingClientState()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: selectedClientId,
                          decoration: const InputDecoration(
                            labelText: 'Cliente',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          items: [
                            for (final client in clients)
                              DropdownMenuItem(
                                value: client.id,
                                child: Text(client.name),
                              ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedClientId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Selecciona un cliente';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: type,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de venta',
                            prefixIcon: Icon(Icons.sell_outlined),
                          ),
                          items: [
                            for (final item in saleTypes)
                              DropdownMenuItem(
                                value: item,
                                child: Text(_saleTypeLabel(item)),
                              ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              type = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Descripcion (opcional)',
                            prefixIcon: Icon(Icons.notes_outlined),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: quantityController,
                                decoration: const InputDecoration(
                                  labelText: 'Cantidad',
                                  prefixIcon: Icon(Icons.numbers_outlined),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                                validator: (value) {
                                  final quantity = _parseQuantity(value ?? '');
                                  if (quantity == null || quantity <= 0) {
                                    return 'Cantidad valida';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: unitPriceController,
                                decoration: const InputDecoration(
                                  labelText: 'Precio unit.',
                                  prefixIcon: Icon(Icons.attach_money),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                                validator: (value) {
                                  final price = _parseMoney(value ?? '');
                                  if (price == null || price <= 0) {
                                    return 'Precio valido';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.calculate_outlined),
                            title: const Text('Total de la venta'),
                            subtitle: const Text('Cantidad x precio unitario'),
                            trailing: Text(
                              Formatters.money(total),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.today_outlined),
                            title: const Text('Fecha de venta'),
                            subtitle: Text(Formatters.date(soldAt)),
                            trailing: const Icon(Icons.edit_calendar_outlined),
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: status,
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                          items: [
                            for (final item in statuses)
                              DropdownMenuItem(
                                value: item,
                                child: Text(_statusLabel(item)),
                              ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              status = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: notesController,
                          decoration: const InputDecoration(
                            labelText: 'Notas',
                            prefixIcon: Icon(Icons.sticky_note_2_outlined),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          icon: isSaving || isSavingAndPaying
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
                                ? 'Actualizar venta'
                                : 'Guardar venta',
                          ),
                          onPressed: isSaving || isSavingAndPaying
                              ? null
                              : () => _saveSale(payNow: false),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          icon: isSavingAndPaying
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.payments_outlined),
                          label: Text(
                            isSavingAndPaying
                                ? 'Abriendo cobro...'
                                : 'Guardar y cobrar ahora',
                          ),
                          onPressed:
                              isSaving ||
                                  isSavingAndPaying ||
                                  status == 'cancelado'
                              ? null
                              : () => _saveSale(payNow: true),
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

  Future<void> _saveSale({required bool payNow}) async {
    if (!formKey.currentState!.validate()) return;

    final viewModel = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final isEditing = sale != null;

    setState(() {
      if (payNow) {
        isSavingAndPaying = true;
      } else {
        isSaving = true;
      }
    });

    final result = isEditing
        ? await viewModel.updateSale(
            sale: sale!,
            clientId: selectedClientId!,
            type: type,
            description: descriptionController.text,
            quantity: _parseQuantity(quantityController.text)!,
            unitPrice: _parseMoney(unitPriceController.text)!,
            soldAt: soldAt,
            status: status,
            notes: notesController.text,
          )
        : await viewModel.addSale(
            clientId: selectedClientId!,
            type: type,
            description: descriptionController.text,
            quantity: _parseQuantity(quantityController.text)!,
            unitPrice: _parseMoney(unitPriceController.text)!,
            soldAt: soldAt,
            status: status,
            notes: notesController.text,
          );

    if (!mounted) return;

    setState(() {
      isSaving = false;
      isSavingAndPaying = false;
    });

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.savedRemotely
              ? 'Venta guardada Online'
              : 'Venta guardada en modo local',
        ),
      ),
    );

    if (payNow) {
      navigator.pushReplacementNamed(
        PaymentFormScreen.routeName,
        arguments: PaymentFormArguments(sale: result.sale),
      );
      return;
    }

    navigator.pop();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: soldAt,
      firstDate: DateTime(2024),
      lastDate: DateTime(2032),
    );
    if (date == null) return;
    setState(() {
      soldAt = date;
    });
  }

  int? _parseQuantity(String value) => int.tryParse(value.trim());

  double? _parseMoney(String value) {
    final normalized = value.replaceAll('RD\$', '').replaceAll(',', '').trim();
    return double.tryParse(normalized);
  }

  double _currentTotal() {
    final quantity = _parseQuantity(quantityController.text) ?? 0;
    final unitPrice = _parseMoney(unitPriceController.text) ?? 0;
    return quantity * unitPrice;
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

  String _statusLabel(String value) {
    return switch (value) {
      'pendiente' => 'Pendiente',
      'cancelado' => 'Cancelado',
      _ => value,
    };
  }
}

class _MissingClientState extends StatelessWidget {
  const _MissingClientState();

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
            'Antes de registrar una venta necesitas crear un cliente.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Crear cliente'),
            onPressed: () =>
                Navigator.pushNamed(context, ClientFormScreen.routeName),
          ),
        ],
      ),
    );
  }
}
