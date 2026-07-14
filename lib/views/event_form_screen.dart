import 'package:flutter/material.dart';

import '../models/photo_event.dart';
import '../models/photo_package.dart';
import '../utils/formatters.dart';
import '../widgets/app_scope.dart';
import 'client_form_screen.dart';
import 'package_form_screen.dart';

class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key});

  static const routeName = '/events/new';

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final formKey = GlobalKey<FormState>();
  final typeController = TextEditingController();
  final locationController = TextEditingController();
  PhotoEvent? event;
  String? selectedClientId;
  String? selectedPackageId;
  String status = 'programado';
  DateTime selectedDateTime = DateTime.now().add(const Duration(days: 1));
  bool didLoadArguments = false;
  bool isSaving = false;

  static const statuses = [
    'programado',
    'en_proceso',
    'completado',
    'cancelado',
  ];

  @override
  void dispose() {
    typeController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = AppScope.of(context);
    final clients = viewModel.clients;
    final availableServices = _availableServices(viewModel.packages);

    if (!didLoadArguments) {
      didLoadArguments = true;
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments is PhotoEvent) {
        event = arguments;
        selectedClientId = arguments.clientId;
        selectedPackageId = arguments.packageId;
        typeController.text = arguments.type;
        locationController.text = arguments.location;
        status = arguments.status;
        selectedDateTime = arguments.dateTime;
        if (!statuses.contains(status)) {
          status = 'programado';
        }
      } else {
        selectedClientId = clients.isEmpty ? null : clients.first.id;
        selectedPackageId = availableServices.isEmpty
            ? null
            : availableServices.first.id;
      }
    }

    final isEditing = event != null;
    final cannotCreate = clients.isEmpty || availableServices.isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar evento' : 'Nuevo evento')),
      body: SafeArea(
        child: cannotCreate
            ? _MissingDataState(
                needsClient: clients.isEmpty,
                needsService: availableServices.isEmpty,
              )
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
                          initialValue: selectedPackageId,
                          decoration: const InputDecoration(
                            labelText: 'Servicio',
                            prefixIcon: Icon(Icons.inventory_2_outlined),
                          ),
                          items: [
                            for (final service in availableServices)
                              DropdownMenuItem(
                                value: service.id,
                                child: Text(
                                  '${service.name} - '
                                  '${Formatters.money(service.price)}',
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedPackageId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Selecciona un servicio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: typeController,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de evento',
                            prefixIcon: Icon(Icons.event_note_outlined),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            final type = value?.trim() ?? '';
                            if (type.isEmpty) {
                              return 'El tipo de evento es obligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: locationController,
                          decoration: const InputDecoration(
                            labelText: 'Ubicacion',
                            prefixIcon: Icon(Icons.place_outlined),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            final location = value?.trim() ?? '';
                            if (location.isEmpty) {
                              return 'La ubicacion es obligatoria';
                            }
                            return null;
                          },
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
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.schedule_outlined),
                            title: const Text('Fecha y hora'),
                            subtitle: Text(
                              '${Formatters.date(selectedDateTime)} - '
                              '${Formatters.time(selectedDateTime)}',
                            ),
                            trailing: const Icon(Icons.edit_calendar_outlined),
                            onTap: _pickDateTime,
                          ),
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
                                ? 'Actualizar evento'
                                : 'Guardar evento',
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
                                      ? await viewModel.updateEvent(
                                          event: event!,
                                          clientId: selectedClientId!,
                                          packageId: selectedPackageId!,
                                          type: typeController.text,
                                          dateTime: selectedDateTime,
                                          location: locationController.text,
                                          status: status,
                                        )
                                      : await viewModel.addEvent(
                                          clientId: selectedClientId!,
                                          packageId: selectedPackageId!,
                                          type: typeController.text,
                                          dateTime: selectedDateTime,
                                          location: locationController.text,
                                          status: status,
                                        );
                                  if (!mounted) return;
                                  setState(() {
                                    isSaving = false;
                                  });
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        savedRemotely
                                            ? 'Evento guardado Online'
                                            : 'Evento guardado en modo local',
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

  List<PhotoPackage> _availableServices(List<PhotoPackage> services) {
    final activeServices = services.where((service) => service.active).toList();
    if (event == null) return activeServices;
    final currentService = services.where((service) {
      return service.id == event!.packageId && !service.active;
    }).toList();
    return [...activeServices, ...currentService];
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDateTime,
      firstDate: DateTime(2024),
      lastDate: DateTime(2032),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
    );
    if (time == null) return;

    setState(() {
      selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String _statusLabel(String value) {
    return switch (value) {
      'programado' => 'Programado',
      'en_proceso' => 'En proceso',
      'completado' => 'Completado',
      'cancelado' => 'Cancelado',
      _ => value,
    };
  }
}

class _MissingDataState extends StatelessWidget {
  const _MissingDataState({
    required this.needsClient,
    required this.needsService,
  });

  final bool needsClient;
  final bool needsService;

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
            'Antes de crear un evento necesitas tener al menos un cliente y un servicio activo.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          if (needsClient)
            FilledButton.icon(
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Crear cliente'),
              onPressed: () =>
                  Navigator.pushNamed(context, ClientFormScreen.routeName),
            ),
          if (needsClient && needsService) const SizedBox(height: 10),
          if (needsService)
            OutlinedButton.icon(
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Crear servicio'),
              onPressed: () =>
                  Navigator.pushNamed(context, PackageFormScreen.routeName),
            ),
        ],
      ),
    );
  }
}
