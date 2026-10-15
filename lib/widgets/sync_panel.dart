import 'package:flutter/material.dart';
import 'app_scope.dart';

class SyncPanel extends StatelessWidget {
  const SyncPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = AppScope.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sincronizacion: ${vm.pendingCount} cambios pendientes',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              vm.syncError ?? vm.connectionMessage ?? 'Actualizando datos...',
            ),
            if (vm.pendingCount > 0)
              const Text(
                'Los saldos incluyen cambios pendientes. Solo un abono confirmado por Firebase esta registrado en el servidor.',
              ),
            TextButton.icon(
              icon: const Icon(Icons.sync),
              label: const Text('Actualizar y reintentar'),
              onPressed: vm.busy
                  ? null
                  : () async {
                      try {
                        await vm.synchronize();
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No se pudo sincronizar. Los pendientes se conservan.',
                              ),
                            ),
                          );
                        }
                      }
                    },
            ),
            if (vm.pendingCount > 0)
              TextButton(
                onPressed: vm.busy
                    ? null
                    : () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Descartar pendientes'),
                            content: const Text(
                              'Se quitaran todos los cambios aun no confirmados de este dispositivo. Los datos confirmados permanecen. Si el servidor ya recibio un cambio antes de un corte, reaparecera al actualizar.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Descartar'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true) return;
                        try {
                          await vm.discardPending();
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No se pudieron descartar los pendientes.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                child: const Text('Descartar pendientes'),
              ),
          ],
        ),
      ),
    );
  }
}
