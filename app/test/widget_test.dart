import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tombox/data/local/app_database.dart';
import 'package:tombox/data/local/database_provider.dart';
import 'package:tombox/main.dart';

void main() {
  testWidgets('App carrega a tela inicial de Unidades com sucesso', (WidgetTester tester) async {
    final testDb = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const TomboxApp(),
      ),
    );

    // Permite que o microtask do router, Riverpod e o banco inicializem
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Inventário Patrimonial Offline'), findsOneWidget);
    expect(find.text('Importar CSV'), findsOneWidget);
    expect(find.text('Carregar Dados de Demonstração'), findsOneWidget);
    expect(find.text('Acessar Salas'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    await testDb.close();
  });
}
