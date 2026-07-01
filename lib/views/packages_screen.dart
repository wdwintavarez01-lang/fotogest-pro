import 'package:flutter/material.dart';

import '../utils/formatters.dart';
import '../widgets/app_scope.dart';

class PackagesScreen extends StatelessWidget {
  const PackagesScreen({super.key});

  static const routeName = '/packages';

  @override
  Widget build(BuildContext context) {
    final viewModel = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Paquetes')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: viewModel.packages.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final package = viewModel.packages[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(package.name),
                subtitle: Text(package.description),
                trailing: Text(
                  Formatters.money(package.price),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
