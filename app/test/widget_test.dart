import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tombox/main.dart';

void main() {
  testWidgets('App carrega a tela inicial de Unidades com sucesso', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TomboxApp(),
      ),
    );

    // Permite que o microtask do router e do Riverpod estabilize
    await tester.pumpAndSettle();

    // Verifica que a tela inicial renderizou os elementos principais
    expect(find.text('Inventário Patrimonial Offline'), findsOneWidget);
    expect(find.text('Importar CSV'), findsOneWidget);
    expect(find.text('Carregar Dados de Demonstração'), findsOneWidget);
    expect(find.text('Acessar Salas'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
}
