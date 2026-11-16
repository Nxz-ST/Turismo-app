import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turismo_app/features/benefits/screens/tourism_benefits_screen.dart';
import 'package:turismo_app/features/benefits/services/mock_benefit_catalog.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('el catálogo demo ofrece tres beneficios diferenciados', () {
    final benefits = MockBenefitCatalog.forPlace(
      placeName: 'Lago Soledad',
      category: 'Lago',
    );

    expect(benefits, hasLength(3));
    expect(benefits.map((item) => item.agencyName).toSet(), hasLength(3));
    expect(benefits.first.discountPercentage, 10);
  });

  testWidgets('permite comparar, activar y mostrar un código demo', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TourismBenefitsScreen(
          placeKey: 'community_lago_soledad',
          placeName: 'Lago Soledad',
          category: 'Lago',
          locationLabel: 'Madre de Dios',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Elige cómo viajar'), findsOneWidget);
    expect(find.text('Andes Conecta'), findsOneWidget);

    await tester.tap(find.text('Ver experiencia').first);
    await tester.pumpAndSettle();
    expect(find.text('Activar beneficio'), findsOneWidget);

    await tester.tap(find.text('Activar beneficio'));
    await tester.pumpAndSettle();
    expect(find.text('¿Activar este beneficio?'), findsOneWidget);

    await tester.tap(find.text('Generar mi beneficio'));
    await tester.pumpAndSettle();
    expect(find.text('Solicitud creada'), findsOneWidget);
    expect(find.text('Coordinar por WhatsApp'), findsOneWidget);
    expect(find.textContaining('RUTA-LAGO-AND-'), findsOneWidget);
  });
}
