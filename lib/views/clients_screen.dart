import 'package:flutter/material.dart';

import '../widgets/app_scope.dart';
import '../widgets/fotogest_bottom_nav.dart';
import 'client_form_screen.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  static const routeName = '/clients';

  @override
  Widget build(BuildContext context) {
    final viewModel = AppScope.of(context);
    final clients = viewModel.clients;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Clientes'),
      ),
      bottomNavigationBar: const FotogestBottomNav(
        currentRoute: ClientsScreen.routeName,
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Nuevo'),
        onPressed: () =>
            Navigator.pushNamed(context, ClientFormScreen.routeName),
      ),
      body: SafeArea(
        child: clients.isEmpty
            ? const Center(child: Text('No hay clientes registrados'))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: clients.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final client = clients[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(client.name.characters.first.toUpperCase()),
                      ),
                      title: Text(client.name),
                      subtitle: Text('${client.phone}\n${client.notes}'),
                      isThreeLine: client.notes.isNotEmpty,
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Editar',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => Navigator.pushNamed(
                              context,
                              ClientFormScreen.routeName,
                              arguments: client,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Eliminar',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmDelete(context, client.id),
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

  Future<void> _confirmDelete(BuildContext context, String clientId) async {
    final viewModel = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar cliente'),
          content: const Text('Esta accion quitara el cliente de la lista.'),
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

    final deletedRemotely = await viewModel.deleteClient(clientId);
    if (!context.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          deletedRemotely
              ? 'Cliente eliminado de Firebase'
              : 'Cliente eliminado en modo local',
        ),
      ),
    );
  }
}
