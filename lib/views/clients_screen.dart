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
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          itemCount: viewModel.clients.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final client = viewModel.clients[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(client.name.characters.first.toUpperCase()),
                ),
                title: Text(client.name),
                subtitle: Text('${client.phone}\n${client.notes}'),
                isThreeLine: client.notes.isNotEmpty,
                trailing: IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {},
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
