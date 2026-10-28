import 'dart:convert';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tombox/data/local/app_database.dart';
import 'package:tombox/domain/eventos/evento_v2.dart';
import 'package:tombox/domain/ia/etiqueta_ocr_service.dart';
import 'package:tombox/domain/ia/mapeamento_categorias.dart';
import 'package:tombox/domain/identidade/identidade_service.dart';
import 'package:tombox/domain/provisorio/cartela_qr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());

    await db.into(db.unidades).insert(
          UnidadesCompanion.insert(
            id: 'unid_teste',
            nome: 'Comarca de Breves',
            dataImportacao: DateTime.now().toUtc(),
            arquivoOrigem: 'breves.csv',
          ),
        );

    await db.into(db.locais).insert(
          LocaisCompanion.insert(
            id: 'sala_201',
            unidadeId: 'unid_teste',
            nome: 'Secretaria Única',
            tipo: 'sala',
            caminhoCompleto: 'Fórum > Secretaria Única',
          ),
        );

    // Bem pré-existente com número de série cadastrado
    await db.into(db.bens).insert(
          BensCompanion.insert(
            tombamento: '100001',
            unidadeId: 'unid_teste',
            descricao: 'Notebook Dell Latitude 5420',
            localEsperadoId: 'sala_201',
            categoria: const Value('Informática'),
            numeroSerie: const Value('8XYZ123'),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('MapeamentoCategorias (IA Visual)', () {
    test('sugere Informática para laptop/computer/monitor', () {
      final s1 = MapeamentoCategorias.sugerir([
        {'text': 'laptop', 'confidence': 0.94},
      ]);
      expect(s1.categoria, equals('Informática'));
      expect(s1.rotuloOrigem, equals('laptop'));
      expect(s1.confianca, closeTo(0.94, 0.01));

      final s2 = MapeamentoCategorias.sugerir([
        {'text': 'computer monitor', 'confidence': 0.88},
      ]);
      expect(s2.categoria, equals('Informática'));
    });

    test('sugere Mobiliário em Geral para chair e desk', () {
      final s = MapeamentoCategorias.sugerir([
        {'text': 'office chair', 'confidence': 0.91},
      ]);
      expect(s.categoria, equals('Mobiliário em Geral'));
    });

    test('sugere Aparelhos de Climatização para air conditioner', () {
      final s = MapeamentoCategorias.sugerir([
        {'text': 'air conditioner', 'confidence': 0.85},
      ]);
      expect(s.categoria, equals('Aparelhos de Climatização'));
    });

    test('fallback para Mobiliário em Geral quando rótulo é desconhecido', () {
      final s = MapeamentoCategorias.sugerir([
        {'text': 'unknown metallic widget', 'confidence': 0.50},
      ]);
      expect(s.categoria, equals('Mobiliário em Geral'));
      expect(s.rotuloOrigem, equals('objeto geral'));
    });

    test('sugestaoSimuladaWeb explicita marca de simulação', () {
      final sim = MapeamentoCategorias.sugestaoSimuladaWeb();
      expect(sim.isSimulacao, isTrue);
      expect(sim.categoria, contains('simulação'));
      expect(sim.rotuloOrigem, contains('simulação'));
    });
  });

  group('EtiquetaOcrService (Extração OCR e Duplicidade)', () {
    test('extrai fabricante Dell, Service Tag e modelo Latitude', () async {
      const textoOcr = '''
DELL INC.
MODEL: LATITUDE 5420
SERVICE TAG: 9ABC456
EXPRESS SERVICE CODE: 202938482
INPUT: 19.5V 3.34A
MADE IN BRAZIL
''';

      final dados = await EtiquetaOcrService.analisarEtiqueta(
        textoOcr: textoOcr,
        db: db,
      );

      expect(dados.fabricante, equals('Dell'));
      expect(dados.numeroSerie, equals('9ABC456'));
      expect(dados.modelo, contains('LATITUDE 5420'));
      expect(dados.isDuplicado, isFalse);
    });

    test('extrai fabricante HP e serial S/N geral', () async {
      const textoOcr = '''
HP INC.
MODEL: PROBOOK 440 G8
S/N: 5CD1234XYZ
PROD ID: 2X7Y9EA
''';

      final dados = await EtiquetaOcrService.analisarEtiqueta(
        textoOcr: textoOcr,
        db: db,
      );

      expect(dados.fabricante, equals('HP'));
      expect(dados.numeroSerie, equals('5CD1234XYZ'));
      expect(dados.isDuplicado, isFalse);
    });

    test('detecta duplicidade se número de série já estiver cadastrado no banco', () async {
      // O banco tem um bem com serial '8XYZ123'
      const textoComSerialExistente = '''
DELL COMPUTER
MODEL: LATITUDE 5420
SERVICE TAG: 8XYZ123
''';

      final dados = await EtiquetaOcrService.analisarEtiqueta(
        textoOcr: textoComSerialExistente,
        db: db,
      );

      expect(dados.numeroSerie, equals('8XYZ123'));
      expect(dados.isDuplicado, isTrue);
      expect(dados.bemDuplicadoEncontrado, isNotNull);
      expect(dados.bemDuplicadoEncontrado!.tombamento, equals('100001'));
      expect(dados.bemDuplicadoEncontrado!.descricao, contains('Latitude 5420'));
    });
  });

  group('CartelaQrService (PDF A4)', () {
    test('gera documento PDF válido com 24 etiquetas adesivas', () async {
      final pdfBytes = await CartelaQrService.gerarCartelaA4(
        numeroInicial: 1,
        quantidade: 24,
        prefixoAparelho: 'PROV-000',
      );

      expect(pdfBytes, isNotEmpty);
      // Cabeçalho PDF padrão %PDF-
      final cabecalho = String.fromCharCodes(pdfBytes.take(5));
      expect(cabecalho, equals('%PDF-'));
    });
  });

  group('Fluxo de Cadastro de Bem Novo Provisório', () {
    test('cria evento BEM_NOVO assinado e persiste bem provisório no banco', () async {
      final identidade = await IdentidadeService.obterOuCriarIdentidade();

      final payload = {
        'tombamento': 'PROV-000-001',
        'is_provisorio': true,
        'descricao': 'Cadeira Giratória Ergonômica',
        'categoria': 'Mobiliário em Geral',
        'local_id': 'sala_201',
        'fabricante': 'Flexform',
        'modelo': 'Uni Me',
        'numero_serie': 'SN-998877',
        'estado_conservacao': 'BOM',
        'proveniencia': {
          'categoria': {'metodo': 'IA_IMAGE_LABELING', 'rotulo': 'office chair', 'confianca': 0.92},
          'fabricante': {'metodo': 'OCR_ETIQUETA', 'confianca': 0.90},
          'numero_serie': {'metodo': 'OCR_ETIQUETA', 'confianca': 0.95},
        },
      };

      final evento = await EventoV2.criar(
        id: 'ev_bem_novo_001',
        unidadeId: 'unid_teste',
        tipo: 'BEM_NOVO',
        autor: identidade.publicKeyHex,
        seq: 1,
        hashAnterior: 'GENESIS',
        conhecidos: {},
        payload: payload,
        keyPair: identidade.keyPair,
      );

      expect(evento.tipo, equals('BEM_NOVO'));
      expect(evento.assinatura, isNotEmpty);
      final valido = await IdentidadeService.verificarAssinatura(
        mensagem: evento.hash,
        assinaturaHex: evento.assinatura,
        publicKeyHex: identidade.publicKeyHex,
      );
      expect(valido, isTrue);

      // Inserção no banco de dados
      await db.into(db.bens).insert(
            BensCompanion.insert(
              tombamento: 'PROV-000-001',
              unidadeId: 'unid_teste',
              descricao: 'Cadeira Giratória Ergonômica',
              localEsperadoId: 'sala_201',
              categoria: const Value('Mobiliário em Geral'),
              fabricante: const Value('Flexform'),
              modelo: const Value('Uni Me'),
              numeroSerie: const Value('SN-998877'),
            ),
          );

      // Registra evento no banco
      await db.into(db.eventos).insert(
            EventosCompanion.insert(
              id: evento.id,
              unidadeId: const Value('unid_teste'),
              seq: evento.seq,
              tipo: evento.tipo,
              autor: Value(evento.autor),
              tombamento: const Value('PROV-000-001'),
              localId: 'sala_201',
              aparelhoId: identidade.impressaoCurta,
              conferente: 'Servidor TJPA',
              timestamp: evento.timestamp,
              payload: Value(jsonEncode(evento.payload)),
              hashAnterior: evento.hashAnterior,
              conhecidos: Value(jsonEncode(evento.conhecidos)),
              hash: evento.hash,
              assinatura: Value(evento.assinatura),
            ),
          );

      final bemSalvo = await (db.select(db.bens)..where((b) => b.tombamento.equals('PROV-000-001'))).getSingle();
      expect(bemSalvo.tombamento, equals('PROV-000-001'));
      expect(bemSalvo.descricao, equals('Cadeira Giratória Ergonômica'));
      expect(bemSalvo.fabricante, equals('Flexform'));
      expect(bemSalvo.modelo, equals('Uni Me'));

      final eventosSalvos = await (db.select(db.eventos)..where((e) => e.tombamento.equals('PROV-000-001'))).get();
      expect(eventosSalvos.length, equals(1));
      expect(eventosSalvos.first.tipo, equals('BEM_NOVO'));
    });
  });
}
