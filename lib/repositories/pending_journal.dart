import 'dart:convert';

/// Una sola escritura persistente conserva la instantanea y su cola por UID.
/// Nunca se cuenta una operacion rechazada como dato confirmado.
class PendingJournal {
  PendingJournal({required this.persist, required this.send});

  final Future<void> Function(String) persist;
  final Future<Map<String, Map<String, dynamic>>> Function(Map<String, dynamic>)
  send;
  Map<String, Map<String, dynamic>> confirmed = {};
  final List<Map<String, dynamic>> pending = [];
  String? rejection;

  void restore(String? value) {
    if (value == null) return;
    final data = jsonDecode(value) as Map<String, dynamic>;
    confirmed = (data['confirmed'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, Map<String, dynamic>.from(value as Map)),
    );
    pending.addAll(
      (data['pending'] as List).map(
        (value) => Map<String, dynamic>.from(value as Map),
      ),
    );
    rejection = data['rejection'] as String?;
  }

  Future<void> save() => persist(
    jsonEncode({
      'confirmed': confirmed,
      'pending': pending,
      'rejection': rejection,
    }),
  );

  Map<String, Map<String, dynamic>> get visible {
    final result = confirmed.map((key, value) => MapEntry(key, {...value}));
    if (rejection != null) return result;
    for (final operation in pending) {
      final key = operation['path'] as String;
      final data = Map<String, dynamic>.from(operation['data'] as Map);
      final old = result[key] ?? <String, dynamic>{};
      result[key] = {
        ...old,
        ...data,
        'revision': (operation['revision'] as int) + 1,
      };
      if (key.startsWith('pagos/')) {
        final target = data['eventoId'] != ''
            ? 'eventos/${data['eventoId']}'
            : 'ventas/${data['ventaId']}';
        final account = result[target];
        if (account != null) {
          account['totalAbonado'] =
              ((account['totalAbonado'] ?? 0) as num) + (data['monto'] as num);
          account['abonadoCentavos'] =
              ((account['abonadoCentavos'] ?? 0) as int) +
              ((data['montoCentavos'] ?? 0) as int);
          account['revision'] = ((account['revision'] ?? 0) as int) + 1;
        }
      }
    }
    return result;
  }

  Future<void> enqueue(Map<String, dynamic> operation) async {
    if (rejection != null) {
      throw StateError('Resuelve los cambios rechazados desde Sincronizacion.');
    }
    pending.add(operation);
    try {
      await save();
    } catch (_) {
      pending.removeLast();
      rethrow;
    }
  }

  Future<void> sync({bool retry = false}) async {
    if (retry) rejection = null;
    if (rejection != null) return;
    while (pending.isNotEmpty) {
      try {
        final updated = await send(pending.first);
        final oldConfirmed = confirmed;
        final operation = pending.removeAt(0);
        confirmed = {...confirmed, ...updated};
        try {
          await save();
        } catch (_) {
          confirmed = oldConfirmed;
          pending.insert(0, operation);
          rethrow;
        }
      } on RetryWhenOnline {
        return;
      } catch (error) {
        rejection = error is StateError
            ? error.message.toString()
            : 'Firebase rechazo el cambio. Revisa permisos y datos.';
        await save();
        return;
      }
    }
  }

  Future<void> discardPending() async {
    final old = [...pending];
    final oldRejection = rejection;
    pending.clear();
    rejection = null;
    try {
      await save();
    } catch (_) {
      pending.addAll(old);
      rejection = oldRejection;
      rethrow;
    }
  }
}

class RetryWhenOnline implements Exception {}
