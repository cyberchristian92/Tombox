import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tombox/core/routes/app_router.dart';
import 'package:tombox/data/local/app_database.dart';
import 'package:tombox/data/local/database_provider.dart';
import 'package:tombox/main.dart';

void main() {
  testWidgets('Navegação entre telas vazias via GoRouter', (WidgetTester tester) async {
    final testDb = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const TomboxApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // 1. Início -> Importação
    appRouter.go('/importacao');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Relatório de Qualidade do CSV'), findsOneWidget);

    // 2. Importação -> Salas
    appRouter.go('/salas');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Salas da Unidade'), findsOneWidget);

    // 3. Salas -> Conferência
    appRouter.go('/conferencia/sala-01');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('12 de 18 bens conferidos'), findsOneWidget);
    expect(find.text('Pipeline da Câmera (ML Kit)'), findsOneWidget);

    // 4. Conferência -> Ficha do Bem
    appRouter.go('/bem/10023');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Ficha do Bem #10023'), findsOneWidget);
    expect(find.text('Estado de Conservação'), findsOneWidget);

    // 5. Ficha do Bem -> Exportação
    appRouter.go('/exportacao');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Resumo da Conferência'), findsOneWidget);
    expect(find.text('Exportar CSV de Resultado (share_plus)'), findsOneWidget);

    // 6. Exportação -> Configurações
    appRouter.go('/configuracoes');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Identidade Visual Trocável'), findsOneWidget);
    expect(find.text('Padrão (TJPA)'), findsOneWidget);
    expect(find.text('Neutro (Sem Instituição)'), findsOneWidget);

    // 7. Retorno para o Início
    appRouter.go('/');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Inventário Patrimonial Offline'), findsOneWidget);

    await testDb.close();
  });
}
