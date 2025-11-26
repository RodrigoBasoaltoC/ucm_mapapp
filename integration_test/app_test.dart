import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ucm_mapp_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Ingresar como invitado lleva al mapa', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('guestButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mapView')), findsOneWidget);
  });

  testWidgets('Mostrar error si email o password vacíos', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    expect(find.text('Por favor, introduce email y contraseña.'), findsOneWidget);
  });

  testWidgets('Escribir email y password correctamente', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('emailField')), 'test@test.com');
    await tester.enterText(find.byKey(const Key('passwordField')), '123456');

    expect(find.text('test@test.com'), findsOneWidget);
    expect(find.text('123456'), findsOneWidget);
  });
}