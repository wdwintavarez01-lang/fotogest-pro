import 'package:flutter/material.dart';

import '../models/client.dart';
import '../widgets/app_scope.dart';

class ClientFormScreen extends StatefulWidget {
  const ClientFormScreen({super.key});

  static const routeName = '/clients/new';

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final notesController = TextEditingController();
  Client? client;
  bool didLoadArguments = false;
  bool isSaving = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = AppScope.of(context);
    if (!didLoadArguments) {
      didLoadArguments = true;
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments is Client) {
        client = arguments;
        nameController.text = arguments.name;
        phoneController.text = arguments.phone;
        notesController.text = arguments.notes;
      }
    }
    final isEditing = client != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar cliente' : 'Nuevo cliente'),
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
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final name = value?.trim() ?? '';
                      if (name.isEmpty) {
                        return 'El nombre es obligatorio';
                      }
                      if (name.length < 3) {
                        return 'Escribe al menos 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telefono',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final phone = value?.trim() ?? '';
                      final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
                      if (phone.isEmpty) {
                        return 'El telefono es obligatorio';
                      }
                      if (digits.length < 10) {
                        return 'Escribe un telefono valido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notas',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                    maxLines: 4,
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
                          ? 'Actualizar cliente'
                          : 'Guardar cliente',
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
                                ? await viewModel.updateClient(
                                    client: client!,
                                    name: nameController.text,
                                    phone: phoneController.text,
                                    notes: notesController.text,
                                  )
                                : await viewModel.addClient(
                                    name: nameController.text,
                                    phone: phoneController.text,
                                    notes: notesController.text,
                                  );
                            if (!mounted) return;
                            setState(() {
                              isSaving = false;
                            });
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  savedRemotely
                                      ? 'Cliente guardado en Firebase'
                                      : 'Cliente guardado en modo local',
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
}
