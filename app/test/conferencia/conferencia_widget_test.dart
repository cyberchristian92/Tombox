import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tombox/data/local/app_database.dart';
import 'package:tombox/data/local/database_provider.dart';
import 'package:tombox/domain/importacao/csv_importer.dart';
import 'package:tombox/features/conferencia/screens/conferencia_screen.dart';

void main() {
  testWidgets('Abrir sala com bens esperados mostra contagem correta e nunca 0 de 0', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final file = File('assets/demo/unidade_demo.csv');
    final bytes = file.readAsBytesSync();
    final dados = CsvImporter.processarCsv(
      bytes: bytes,
      nomeArquivo: 'unidade_demo.csv',
    );

    await db.salvarUnidadeCompleta(
      unidade: dados.unidade,
      listaLocais: dados.locais,
      listaBens: dados.bens,
      salasConferencia: dados.salas,
    );

    // Pega a primeira sala
    final sala = dados.salas.first;
    final salaLocalId = sala.localId.value;
    final bensDaSala = dados.bens.where((b) => b.localEsperadoId.value == salaLocalId).length;
    expect(bensDaSala, greaterThan(0));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp(
          home: ConferenciaScreen(salaId: salaLocalId),
        ),
      ),
    );

    // Permite carregamento assíncrono dos streams
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // Verifica que NÃO mostra "0 de 0"
    expect(find.textContaining('0 de 0'), findsNothing);
    // Verifica que mostra "0 de $bensDaSala"
    expect(find.textContaining('0 de $bensDaSala'), findsWidgets);

    await db.close();
  });
}
