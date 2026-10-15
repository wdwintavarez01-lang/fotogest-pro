import 'package:flutter_test/flutter_test.dart';
import 'package:fotogest_pro/repositories/pending_journal.dart';

Map<String, dynamic> operation(String id, {int revision = 0}) => {
  'id': id,
  'path': 'clientes/c1',
  'revision': revision,
  'kind': revision == 0 ? 'create' : 'update',
  'data': {
    'clienteId': 'c1',
    'usuarioId': 'alice',
    'nombre': id,
    'eliminado': false,
  },
};

void main() {
  test('Q01 pendientes y cache sobreviven reinicio sin red', () async {
    String? disk;
    final first = PendingJournal(
      persist: (value) async {
        disk = value;
      },
      send: (_) async => throw RetryWhenOnline(),
    );
    first.confirmed['paquetes/s1'] = {'nombre': 'Retrato'};
    await first.enqueue(operation('primero'));
    await first.sync();
    final reopened = PendingJournal(
      persist: (_) async {},
      send: (_) async => throw RetryWhenOnline(),
    )..restore(disk);
    expect(reopened.pending, hasLength(1));
    expect(reopened.visible['clientes/c1']!['nombre'], 'primero');
    expect(reopened.confirmed['clientes/c1'], isNull);
    expect(reopened.confirmed['paquetes/s1']!['nombre'], 'Retrato');
  });
  test('Q02 recuperacion confirma en orden y vacia la cola', () async {
    final sent = <String>[];
    final journal = PendingJournal(
      persist: (_) async {},
      send: (op) async {
        sent.add(op['id'] as String);
        return {
          op['path'] as String: {
            ...(op['data'] as Map<String, dynamic>),
            'revision': (op['revision'] as int) + 1,
          },
        };
      },
    );
    await journal.enqueue(operation('primero'));
    await journal.enqueue(operation('segundo', revision: 1));
    await journal.sync();
    expect(sent, ['primero', 'segundo']);
    expect(journal.pending, isEmpty);
    expect(journal.confirmed['clientes/c1']!['revision'], 2);
    expect(journal.visible['clientes/c1']!['nombre'], 'segundo');
  });
  test(
    'Q03 rechazo revierte vista y bloquea dependencias sin borrarlas',
    () async {
      var calls = 0;
      final journal = PendingJournal(
        persist: (_) async {},
        send: (_) async {
          calls++;
          throw StateError('Conflicto de revision');
        },
      );
      journal.confirmed['clientes/c1'] = {'nombre': 'Original', 'revision': 1};
      await journal.enqueue(operation('rechazado', revision: 1));
      await journal.enqueue(operation('dependiente', revision: 2));
      await journal.sync();
      expect(calls, 1);
      expect(journal.pending, hasLength(2));
      expect(journal.visible['clientes/c1']!['nombre'], 'Original');
      expect(journal.rejection, 'Conflicto de revision');
      await expectLater(journal.enqueue(operation('nuevo')), throwsStateError);
    },
  );
  test('Q04 descartar solo pendientes conserva confirmados', () async {
    final journal = PendingJournal(
      persist: (_) async {},
      send: (_) async => {},
    );
    journal.confirmed['clientes/c1'] = {'nombre': 'Original'};
    await journal.enqueue(operation('pendiente'));
    await journal.discardPending();
    expect(journal.visible['clientes/c1']!['nombre'], 'Original');
    expect(journal.pending, isEmpty);
  });
  test('Q05 fallo al persistir no simula un guardado', () async {
    final journal = PendingJournal(
      persist: (_) async => throw StateError('Disco lleno'),
      send: (_) async => {},
    );
    await expectLater(
      journal.enqueue(operation('pendiente')),
      throwsStateError,
    );
    expect(journal.pending, isEmpty);
    expect(journal.visible, isEmpty);
  });
  test('Q06 corte tras commit conserva ID para repetir sin duplicar', () async {
    String? disk;
    var fail = false;
    final server = <String, Map<String, dynamic>>{};
    var inserts = 0;
    Future<Map<String, Map<String, dynamic>>> send(
      Map<String, dynamic> op,
    ) async {
      if (!server.containsKey(op['id'])) {
        inserts++;
        server[op['id'] as String] = {'nombre': 'Confirmado'};
      }
      return {'clientes/c1': server[op['id']]!};
    }

    final journal = PendingJournal(
      persist: (value) async {
        if (fail) throw StateError('Corte de almacenamiento');
        disk = value;
      },
      send: send,
    );
    await journal.enqueue(operation('id_estable'));
    fail = true;
    await expectLater(journal.sync(), throwsStateError);
    final reopened = PendingJournal(persist: (_) async {}, send: send)
      ..restore(disk);
    await reopened.sync();
    expect(inserts, 1);
    expect(reopened.pending, isEmpty);
    expect(reopened.visible['clientes/c1']!['nombre'], 'Confirmado');
  });
  test(
    'Q07 abono pendiente reserva saldo y revision sin confirmarlo',
    () async {
      final journal = PendingJournal(
        persist: (_) async {},
        send: (_) async => throw RetryWhenOnline(),
      );
      journal.confirmed['eventos/e1'] = {
        'totalAbonado': 0,
        'abonadoCentavos': 0,
        'revision': 1,
      };
      await journal.enqueue({
        'path': 'pagos/p1',
        'id': 'p1',
        'kind': 'create',
        'revision': 0,
        'data': {
          'eventoId': 'e1',
          'ventaId': '',
          'monto': 30,
          'montoCentavos': 3000,
        },
      });
      expect(journal.visible['eventos/e1']!['totalAbonado'], 30);
      expect(journal.visible['eventos/e1']!['abonadoCentavos'], 3000);
      expect(journal.visible['eventos/e1']!['revision'], 2);
      expect(journal.confirmed['eventos/e1']!['totalAbonado'], 0);
    },
  );
}
