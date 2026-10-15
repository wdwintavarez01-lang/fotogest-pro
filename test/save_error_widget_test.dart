import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fotogest_pro/main.dart';
import 'package:fotogest_pro/views/client_form_screen.dart';

void main() {
  testWidgets(
    'W02 fallo de Firebase conserva formulario y habilita reintento',
    (tester) async {
      await tester.pumpWidget(const FotoGestApp());
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .pushNamed(ClientFormScreen.routeName);
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Cliente Prueba');
      await tester.enterText(fields.at(1), '8095550123');
      await tester.ensureVisible(find.text('Guardar cliente'));
      await tester.tap(find.text('Guardar cliente'));
      await tester.pumpAndSettle();
      expect(find.byType(ClientFormScreen), findsOneWidget);
      expect(
        find.textContaining('Firebase no esta disponible'),
        findsOneWidget,
      );
      expect(find.text('Cliente Prueba'), findsOneWidget);
      expect(find.text('Guardando...'), findsNothing);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Guardar cliente'),
      );
      expect(button.onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );
}
