import 'package:flutter_test/flutter_test.dart';

import 'package:fotogest_pro/main.dart';

void main() {
  testWidgets('muestra la pantalla inicial de FotoGest Pro', (tester) async {
    await tester.pumpWidget(const FotoGestApp());

    expect(find.text('FotoGest Pro'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
