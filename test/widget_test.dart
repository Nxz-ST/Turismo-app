import 'package:flutter_test/flutter_test.dart';
import 'package:turismo_app/app/app.dart';
import 'package:turismo_app/features/auth/screens/welcome_screen.dart';

void main() {
  testWidgets('muestra la pantalla de bienvenida', (tester) async {
    await tester.pumpWidget(const RutaAmigaApp(initialHome: WelcomeScreen()));

    expect(find.text('RutaAmiga'), findsOneWidget);
    expect(find.text('Comenzar aventura'), findsOneWidget);
  });
}
