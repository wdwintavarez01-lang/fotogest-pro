import 'package:flutter/material.dart';

import '../models/photo_package.dart';
import '../widgets/app_scope.dart';

class PackageFormScreen extends StatefulWidget {
  const PackageFormScreen({super.key});

  static const routeName = '/services/new';

  @override
  State<PackageFormScreen> createState() => _PackageFormScreenState();
}

class _PackageFormScreenState extends State<PackageFormScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  PhotoPackage? service;
  bool active = true;
  bool didLoadArguments = false;
  bool isSaving = false;

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = AppScope.of(context);
    if (!didLoadArguments) {
      didLoadArguments = true;
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments is PhotoPackage) {
        service = arguments;
        nameController.text = arguments.name;
        descriptionController.text = arguments.description;
        priceController.text = arguments.price.toStringAsFixed(0);
        active = arguments.active;
      }
    }
    final isEditing = service != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar servicio' : 'Nuevo servicio'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del servicio',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final name = value?.trim() ?? '';
                      if (name.isEmpty) return 'El nombre es obligatorio';
                      if (name.length < 3) {
                        return 'Escribe al menos 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripcion',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      final description = value?.trim() ?? '';
                      if (description.isEmpty) {
                        return 'La descripcion es obligatoria';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final price = _parsePrice(value ?? '');
                      if (price == null || price <= 0) {
                        return 'Escribe un precio valido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Servicio activo'),
                    subtitle: const Text('Disponible para nuevos eventos'),
                    value: active,
                    onChanged: (value) {
                      setState(() {
                        active = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      isSaving
                          ? 'Guardando...'
                          : isEditing
                          ? 'Actualizar servicio'
                          : 'Guardar servicio',
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(context);
                            setState(() {
                              isSaving = true;
                            });
                            final savedRemotely = isEditing
                                ? await viewModel.updatePackage(
                                    package: service!,
                                    name: nameController.text,
                                    description: descriptionController.text,
                                    price: _parsePrice(priceController.text)!,
                                    active: active,
                                  )
                                : await viewModel.addPackage(
                                    name: nameController.text,
                                    description: descriptionController.text,
                                    price: _parsePrice(priceController.text)!,
                                    active: active,
                                  );
                            if (!mounted) return;
                            setState(() {
                              isSaving = false;
                            });
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  savedRemotely
                                      ? 'Servicio guardado Online'
                                      : 'Servicio guardado en modo local',
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

  double? _parsePrice(String value) {
    final normalized = value.replaceAll('RD\$', '').replaceAll(',', '').trim();
    return double.tryParse(normalized);
  }
}
