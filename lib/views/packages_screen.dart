import 'package:flutter/material.dart';

import '../models/photo_package.dart';
import '../utils/formatters.dart';
import '../widgets/app_scope.dart';
import '../widgets/fotogest_bottom_nav.dart';
import 'package_form_screen.dart';

class PackagesScreen extends StatelessWidget {
  const PackagesScreen({super.key});

  static const routeName = '/packages';

  @override
  Widget build(BuildContext context) {
    final viewModel = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Servicios')),
      bottomNavigationBar: const FotogestBottomNav(
        currentRoute: PackagesScreen.routeName,
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Nuevo'),
        onPressed: () =>
            Navigator.pushNamed(context, PackageFormScreen.routeName),
      ),
      body: SafeArea(
        child: viewModel.packages.isEmpty
            ? const Center(child: Text('No hay servicios registrados'))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: viewModel.packages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final service = viewModel.packages[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  service.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              Text(
                                Formatters.money(service.price),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(service.description),
                          const SizedBox(height: 8),
                          Chip(
                            avatar: Icon(
                              service.active
                                  ? Icons.check_circle_outline
                                  : Icons.pause_circle_outline,
                              size: 18,
                            ),
                            label: Text(service.active ? 'Activo' : 'Inactivo'),
                          ),
                          const Divider(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Editar'),
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    PackageFormScreen.routeName,
                                    arguments: service,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Eliminar'),
                                  onPressed: () =>
                                      _confirmDelete(context, service),
                                ),
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

  Future<void> _confirmDelete(
    BuildContext context,
    PhotoPackage service,
  ) async {
    final viewModel = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (viewModel.hasEventsForPackage(service.id)) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No puedes eliminar un servicio usado en eventos.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar servicio'),
          content: const Text('Esta accion quitara el servicio de la lista.'),
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

    final deletedRemotely = await viewModel.deletePackage(service.id);
    if (!context.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          deletedRemotely
              ? 'Servicio eliminado Online'
              : 'Servicio eliminado en modo local',
        ),
      ),
    );
  }
}
