import 'dart:io';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:tombox/brand/brand_provider.dart';
import 'package:tombox/core/routes/app_router.dart';
import 'package:tombox/data/local/app_database.dart';
import 'package:tombox/data/local/database_provider.dart';
import 'package:tombox/data/local/perfil_provider.dart';
import 'package:tombox/data/local/queries_provider.dart';
import 'package:tombox/main.dart';

Future<void> carregarFontesBarlow() async {
  final fontes = [
    ('Barlow', [
      'assets/fonts/Barlow-Regular.ttf',
      'assets/fonts/Barlow-Medium.ttf',
      'assets/fonts/Barlow-SemiBold.ttf',
      'assets/fonts/Barlow-Bold.ttf',
    ]),
    ('BarlowCondensed', [
      'assets/fonts/BarlowCondensed-SemiBold.ttf',
      'assets/fonts/BarlowCondensed-Bold.ttf',
    ]),
    ('BarlowSemiCondensed', [
      'assets/fonts/BarlowSemiCondensed-SemiBold.ttf',
    ]),
    ('RobotoMono', [
      'assets/fonts/RobotoMono.ttf',
    ]),
  ];

  for (final (familia, caminhos) in fontes) {
    final loader = FontLoader(familia);
    for (final caminho in caminhos) {
      final file = File(caminho);
      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        loader.addFont(Future.value(ByteData.sublistView(bytes)));
      }
    }
    await loader.load();
  }
}

Future<AppDatabase> criarBancoSimulado() async {
  final db = AppDatabase(NativeDatabase.memory());

  // 1. Unidade
  await db.into(db.unidades).insert(
        UnidadesCompanion.insert(
          id: 'unid_breves',
          nome: 'Comarca de Breves',
          dataImportacao: DateTime(2026, 10, 28, 8, 0),
          arquivoOrigem: 'breves_patrimonio.csv',
        ),
      );

  // 2. Locais
  final locais = [
    LocaisCompanion.insert(
      id: 'predio_central',
      unidadeId: 'unid_breves',
      nome: 'Fórum Central de Breves',
      tipo: 'predio',
      caminhoCompleto: 'Comarca de Breves › Fórum Central',
    ),
    LocaisCompanion.insert(
      id: 'sala_gabinete',
      unidadeId: 'unid_breves',
      nome: 'Gabinete do Juiz Titular',
      tipo: 'sala',
      caminhoCompleto: 'Fórum Central › 2º Andar › Gabinete do Juiz Titular',
    ),
    LocaisCompanion.insert(
      id: 'sala_secretaria',
      unidadeId: 'unid_breves',
      nome: 'Secretaria Única',
      tipo: 'sala',
      caminhoCompleto: 'Fórum Central › 1º Andar › Secretaria Única',
    ),
    LocaisCompanion.insert(
      id: 'sala_audiencias',
      unidadeId: 'unid_breves',
      nome: 'Sala de Audiências 1',
      tipo: 'sala',
      caminhoCompleto: 'Fórum Central › 1º Andar › Sala de Audiências 1',
    ),
    LocaisCompanion.insert(
      id: 'sala_arquivo',
      unidadeId: 'unid_breves',
      nome: 'Arquivo Geral',
      tipo: 'sala',
      caminhoCompleto: 'Fórum Central › Subsolo › Arquivo Geral',
    ),
    LocaisCompanion.insert(
      id: 'sala_copa',
      unidadeId: 'unid_breves',
      nome: 'Copa / Apoio',
      tipo: 'sala',
      caminhoCompleto: 'Fórum Central › Térreo › Copa / Apoio',
    ),
  ];
  for (final l in locais) {
    await db.into(db.locais).insert(l);
  }

  // 3. Status da Conferencia das Salas (Gabinete: em andamento 7 de 18)
  await db.into(db.conferenciaSalas).insert(
        ConferenciaSalasCompanion.insert(
          localId: 'sala_gabinete',
          status: const Value('em_andamento'),
          inicio: Value(DateTime(2026, 10, 28, 8, 30)),
          conferente: const Value('Rosilene Silva'),
        ),
      );

  await db.into(db.conferenciaSalas).insert(
        ConferenciaSalasCompanion.insert(
          localId: 'sala_secretaria',
          status: const Value('fechada'),
          inicio: Value(DateTime(2026, 10, 28, 7, 0)),
          fim: Value(DateTime(2026, 10, 28, 8, 15)),
          conferente: const Value('Rosilene Silva'),
        ),
      );

  // 4. Bens (18 no Gabinete: 7 lidos + 11 pendentes; 1 de outra sala; 1 sem cadastro)
  final bensGabinete = [
    ('045120', 'Notebook Dell Latitude 5420 Core i7 16GB', 'Informática', 'Dell', 'Latitude 5420', '8XYZ123', true),
    ('045121', 'Monitor Dell 24 Polegadas P2419H', 'Informática', 'Dell', 'P2419H', 'CN-09876', true),
    ('045122', 'Cadeira Giratória Espaldar Alto Braços Reguláveis', 'Mobiliário em Geral', 'Flexform', 'Uni Me', null, true),
    ('045123', 'Mesa Diretor em L com Gaveteiro Volante', 'Mobiliário em Geral', 'Marelli', 'L-Line', null, true),
    ('045124', 'Aparelho de Ar Condicionado Split 12.000 BTUs', 'Aparelhos de Climatização', 'Carrier', 'Hi-Wall', 'SER-44321', true),
    ('045125', 'Impressora Multifuncional Laserjet Pro', 'Máquinas e Equipamentos de Escritório', 'HP', 'M428fdw', 'VNB34211', true),
    ('045126', 'Armário Alto Duas Portas com Fechadura', 'Mobiliário em Geral', 'Marelli', 'Classic', null, true),
    ('045127', 'Poltrona Fixa para Aproximação Revestimento Vinil', 'Mobiliário em Geral', null, null, null, false),
    ('045128', 'Poltrona Fixa para Aproximação Revestimento Vinil', 'Mobiliário em Geral', null, null, null, false),
    ('045129', 'Longarina 3 Lugares Estofada', 'Mobiliário em Geral', null, null, null, false),
    ('045130', 'Fragmentadora de Papel 15 Folhas', 'Máquinas e Equipamentos de Escritório', 'Menno', 'Sec-15', null, false),
    ('045131', 'Quadro Branco Magnético 120x90cm', 'Mobiliário em Geral', null, null, null, false),
    ('045132', 'Estante de Aço 6 Prateleiras Cinza', 'Mobiliário em Geral', null, null, null, false),
    ('045133', 'Scanner de Mesa Alta Resolução', 'Informática', 'Fujitsu', 'ScanSnap', 'FJT-9912', false),
    ('045134', 'Telefone IP Empresarial Viva-Voz', 'Informática', 'Cisco', 'CP-7821', 'FCH2109', false),
    ('045135', 'Lixeira Inox com Pedal 20L', 'Mobiliário em Geral', null, null, null, false),
    ('045136', 'Suporte Ergonômico para Monitor Articulado', 'Informática', null, null, null, false),
    ('045137', 'Desumidificador de Ar Ambiente 20L', 'Aparelhos de Climatização', 'Arsec', '20L', null, false),
  ];

  for (final b in bensGabinete) {
    await db.into(db.bens).insert(
          BensCompanion.insert(
            tombamento: b.$1,
            unidadeId: 'unid_breves',
            descricao: b.$2,
            categoria: Value(b.$3),
            localEsperadoId: 'sala_gabinete',
            fabricante: Value(b.$4),
            modelo: Value(b.$5),
            numeroSerie: Value(b.$6),
            responsavel: const Value('Dra. Maria Helena - Juíza Titular'),
          ),
        );

    if (b.$7) {
      await db.into(db.eventos).insert(
            EventosCompanion.insert(
              id: 'ev_${b.$1}',
              unidadeId: const Value('unid_breves'),
              seq: 1,
              tipo: 'LEITURA',
              tombamento: Value(b.$1),
              localId: 'sala_gabinete',
              aparelhoId: 'ED25-9B1C-44A2',
              conferente: 'Rosilene Silva',
              timestamp: DateTime(2026, 10, 28, 8, 35),
              payload: const Value('{"metodo": "leitura_camera"}'),
              hashAnterior: 'GENESIS',
              hash: 'hash_${b.$1}',
              assinatura: Value('sig_${b.$1}'),
            ),
          );
    }
  }

  // Bem de outra sala
  await db.into(db.bens).insert(
        BensCompanion.insert(
          tombamento: '045150',
          unidadeId: 'unid_breves',
          descricao: 'Nobreak Senoidal 1500VA Bivolt',
          categoria: const Value('Informática'),
          localEsperadoId: 'sala_arquivo',
          fabricante: const Value('APC'),
          modelo: const Value('Back-UPS 1500'),
          responsavel: const Value('Arquivo Geral'),
        ),
      );
  await db.into(db.eventos).insert(
        EventosCompanion.insert(
          id: 'ev_045150',
          unidadeId: const Value('unid_breves'),
          seq: 1,
          tipo: 'LEITURA',
          tombamento: const Value('045150'),
          localId: 'sala_gabinete',
          aparelhoId: 'ED25-9B1C-44A2',
          conferente: 'Rosilene Silva',
          timestamp: DateTime(2026, 10, 28, 8, 42),
          payload: const Value('{"metodo": "leitura_camera", "local_esperado": "sala_arquivo"}'),
          hashAnterior: 'hash_045126',
          hash: 'hash_045150',
          assinatura: const Value('sig_045150'),
        ),
      );

  // Bem provisório
  await db.into(db.bens).insert(
        BensCompanion.insert(
          tombamento: 'PROV-000-001',
          unidadeId: 'unid_breves',
          descricao: 'Projetor Multimídia Portátil 3800 Lumens',
          categoria: const Value('Equipamentos de Áudio e Vídeo'),
          localEsperadoId: 'sala_gabinete',
          fabricante: const Value('Epson'),
          modelo: const Value('PowerLite E20'),
          numeroSerie: const Value('X89K12093'),
          responsavel: const Value('Rosilene Silva'),
        ),
      );

  // Histórico para o bem 045120
  await db.into(db.eventos).insert(
        EventosCompanion.insert(
          id: 'ev_045120_estado',
          unidadeId: const Value('unid_breves'),
          seq: 2,
          tipo: 'ESTADO',
          tombamento: const Value('045120'),
          localId: 'sala_gabinete',
          aparelhoId: 'ED25-9B1C-44A2',
          conferente: 'Rosilene Silva',
          timestamp: DateTime(2026, 10, 28, 8, 36),
          payload: const Value('{"estado_conservacao": "BOM", "detalhes": "Em perfeito estado de funcionamento"}'),
          hashAnterior: 'hash_045120',
          hash: 'hash_045120_estado',
          assinatura: const Value('sig_045120_estado'),
        ),
      );

  return db;
}

Future<void> capturarPng(WidgetTester tester, GlobalKey key, String nomeArquivo) async {
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final file = File('../docs/screenshots/$nomeArquivo');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(pngBytes);

    final hash = md5.convert(pngBytes).toString();
    // ignore: avoid_print
    print('CAPTURA: $nomeArquivo [${pngBytes.length} bytes, MD5: $hash]');
  });
}

class MockUnidadeAtivaIdNotifier extends UnidadeAtivaIdNotifier {
  @override
  String? build() => 'unid_breves';
}

class MockPerfilNotifier extends PerfilNotifier {
  @override
  PerfilUsuario build() {
    return const PerfilUsuario(
      nome: 'Rosilene Silva',
      matricula: 'TJPA-18492',
      papel: 'conferente',
      aparelhoId: 'ED25-9B1C-44A2',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
    await carregarFontesBarlow();
  });

  testWidgets('Gera capturas determinísticas do Tombox v2 (360x800 @2x)', (WidgetTester tester) async {
    final db = await criarBancoSimulado();

    // Configura resolução 360 x 800 @ 2.0x
    await tester.binding.setSurfaceSize(const Size(360, 800));

    final boundaryKey = GlobalKey();

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        unidadeAtivaIdProvider.overrideWith(MockUnidadeAtivaIdNotifier.new),
        perfilProvider.overrideWith(MockPerfilNotifier.new),
      ],
    );

    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: UncontrolledProviderScope(
          container: container,
          child: const TomboxApp(),
        ),
      ),
    );

    // Inicialização do app
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    // 1. Início (Claro)
    appRouter.go('/');
    container.read(themeModeProvider.notifier).setMode(ThemeMode.light);
    await tester.pump(const Duration(milliseconds: 200));
    await capturarPng(tester, boundaryKey, '01-inicio.png');

    // 2. Início (Escuro)
    container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
    await tester.pump(const Duration(milliseconds: 200));
    await capturarPng(tester, boundaryKey, '01-inicio-dark.png');

    // Volta para Claro
    container.read(themeModeProvider.notifier).setMode(ThemeMode.light);

    // 3. Locais
    appRouter.go('/locais');
    await tester.pump(const Duration(milliseconds: 200));
    await capturarPng(tester, boundaryKey, '02-locais.png');

    // 4. Detalhes da Sala (Gabinete)
    appRouter.go('/locais/sala_gabinete');
    await tester.pump(const Duration(milliseconds: 200));
    await capturarPng(tester, boundaryKey, '03-sala.png');

    // 5. Conferência da Sala
    appRouter.go('/conferencia/sala_gabinete');
    await tester.pump(const Duration(milliseconds: 200));
    await capturarPng(tester, boundaryKey, '04-conferir.png');

    // 6. Lista de Bens
    appRouter.go('/bens');
    await tester.pump(const Duration(milliseconds: 200));
    await capturarPng(tester, boundaryKey, '05-bens.png');

    // 7. Ficha do Bem (Claro)
    appRouter.go('/bens/045120');
    await tester.pump(const Duration(milliseconds: 200));
    await capturarPng(tester, boundaryKey, '06-ficha.png');

    // 8. Ficha do Bem (Escuro)
    container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
    await tester.pump(const Duration(milliseconds: 200));
    await capturarPng(tester, boundaryKey, '06-ficha-dark.png');

    // Volta para Claro
    container.read(themeModeProvider.notifier).setMode(ThemeMode.light);

    // 9. Mais
    appRouter.go('/mais');
    await tester.pump(const Duration(milliseconds: 200));
    await capturarPng(tester, boundaryKey, '07-mais.png');

    // 10. Relatório de Importação
    appRouter.go('/importacao');
    await tester.pump(const Duration(milliseconds: 200));
    await capturarPng(tester, boundaryKey, '08-importacao.png');

    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.binding.setSurfaceSize(null);
  });
}
