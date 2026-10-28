import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tombox/data/local/app_database.dart';
import 'package:tombox/domain/eventos/evento_v2.dart';
import 'package:tombox/domain/exportacao/epcis_service.dart';
import 'package:tombox/domain/exportacao/exportacao_service.dart';
import 'package:tombox/domain/fechamento/fechamento_models.dart';
import 'package:tombox/domain/fechamento/fechamento_service.dart';
import 'package:tombox/domain/fechamento/termo_pdf_service.dart';
import 'package:tombox/domain/identidade/identidade_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());

    // Popula unidade e sala de teste com colunas exatas do Drift
    await db.into(db.unidades).insert(
          UnidadesCompanion.insert(
            id: 'unid_01',
            nome: 'Fórum Cível de Belém',
            dataImportacao: DateTime.now().toUtc(),
            arquivoOrigem: 'carga_inicial.csv',
          ),
        );

    await db.into(db.locais).insert(
          LocaisCompanion.insert(
            id: 'sala_101',
            unidadeId: 'unid_01',
            nome: 'Gabinete 101',
            tipo: 'sala',
            caminhoCompleto: 'Fórum Cível > Gabinete 101',
          ),
        );

    await db.into(db.bens).insert(
          BensCompanion.insert(
            tombamento: '045120',
            unidadeId: 'unid_01',
            descricao: 'Notebook Dell Latitude 5420',
            localEsperadoId: 'sala_101',
            categoria: const Value('Informática'),
          ),
        );

    await db.into(db.bens).insert(
          BensCompanion.insert(
            tombamento: '045121',
            unidadeId: 'unid_01',
            descricao: 'Monitor Dell 24 P2419H',
            localEsperadoId: 'sala_101',
            categoria: const Value('Informática'),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('Fechamento de Sala e Termo de Responsabilidade (Bloco F)', () {
    test('Calcula resumo de fechamento da sala corretamente', () async {
      final resumo = await FechamentoService.obterResumoFechamento(db, 'sala_101');
      expect(resumo.totalEsperados, equals(2));
      expect(resumo.totalConferidos, equals(0));
      expect(resumo.totalNaoEncontrados, equals(2));
      expect(resumo.taxaConferencia, equals(0.0));
      expect(resumo.bens.length, equals(2));
    });

    test('Gera PDF do Termo de Responsabilidade com imagem de assinatura e dados institucionais', () async {
      final resumo = await FechamentoService.obterResumoFechamento(db, 'sala_101');

      // Gera bytes mínimos de PNG transparente para teste
      final pngSimulado = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82,
      ]);

      final dados = DadosTermoResponsabilidade(
        resumo: resumo,
        responsavelNome: 'Dra. Maria Helena Silva',
        responsavelMatricula: 'TJPA-8841',
        responsavelCargo: 'Diretora de Secretaria',
        conferenteNome: 'Carlos Eduardo',
        conferenteMatricula: 'TJPA-1234',
        chaveConferente: 'ED25-9B1C-44A2',
        dataHora: DateTime.now().toUtc(),
        assinaturaBytes: pngSimulado,
      );

      final pdfBytes = await TermoPdfService.gerarTermoPdf(dados);
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));

      final hash = sha256.convert(pdfBytes).toString();
      expect(hash.length, equals(64));
    });

    test('Fechamento de sala emite eventos FECHAMENTO_SALA e TERMO_ASSINADO com hash do PDF', () async {
      final resumo = await FechamentoService.obterResumoFechamento(db, 'sala_101');
      final id = await IdentidadeService.obterOuCriarIdentidade();

      final dados = DadosTermoResponsabilidade(
        resumo: resumo,
        responsavelNome: 'Dr. Roberto Magalhães',
        responsavelMatricula: 'TJPA-7712',
        responsavelCargo: 'Juiz de Direito',
        conferenteNome: 'Rosilene Miranda',
        conferenteMatricula: 'TJPA-0099',
        chaveConferente: id.impressaoCurta,
        dataHora: DateTime.now().toUtc(),
        assinaturaBytes: Uint8List(0),
      );

      final res = await FechamentoService.fecharSalaComTermo(
        db: db,
        dados: dados,
        autorPublicKey: id.publicKeyHex,
        aparelhoId: id.impressaoCurta,
      );

      expect(res.pdfBytes, isNotEmpty);
      expect(res.pdfHash, isNotEmpty);

      // Confere se os eventos foram gravados no banco
      final eventosGravados = await db.select(db.eventos).get();
      expect(eventosGravados.any((e) => e.tipo == TiposEvento.fechamentoSala), isTrue);
      expect(eventosGravados.any((e) => e.tipo == TiposEvento.termoAssinado), isTrue);

      final evTermo = eventosGravados.firstWhere((e) => e.tipo == TiposEvento.termoAssinado);
      final payload = jsonDecode(evTermo.payload);
      expect(payload['pdf_hash'], equals(res.pdfHash));
      expect(payload['signatario_nome'], equals('Dr. Roberto Magalhães'));
    });
  });

  group('Exportação de Resultados e Auditoria (Bloco F)', () {
    test('Proteção contra injeção de fórmulas CSV (CWE-1236)', () {
      expect(ExportacaoService.sanitizarCwe1236('=cmd|...'), equals("'=cmd|..."));
      expect(ExportacaoService.sanitizarCwe1236('+123'), equals("'+123"));
      expect(ExportacaoService.sanitizarCwe1236('-456'), equals("'-456"));
      expect(ExportacaoService.sanitizarCwe1236('@soma()'), equals("'@soma()"));
      expect(ExportacaoService.sanitizarCwe1236('Notebook Dell'), equals('Notebook Dell'));
    });

    test('Exportação CSV no perfil Thema-GRP e perfil Genérico', () async {
      final csvThema = await ExportacaoService.exportarCsv(
        db: db,
        perfil: PerfilExportacao.themaGrp,
      );
      expect(csvThema, contains('Numero_Patrimonio'));
      expect(csvThema, contains('Situacao_Inventario'));
      expect(csvThema, contains('045120'));

      final csvGenerico = await ExportacaoService.exportarCsv(
        db: db,
        perfil: PerfilExportacao.genericoAuditoria,
      );
      expect(csvGenerico, contains('tombamento'));
      expect(csvGenerico, contains('hash_evento'));
      expect(csvGenerico, contains('assinatura_valida'));
    });

    test('Geração do Relatório Geral Consolidado em PDF da Unidade', () async {
      final pdfBytes = await ExportacaoService.gerarRelatorioUnidadePdf(db: db);
      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('Exportação no padrão GS1 EPCIS 2.0 JSON-LD', () async {
      final epcisJsonLd = await EpcisService.exportarEpcisJsonLd(db: db);
      expect(epcisJsonLd, contains('EPCISDocument'));
      expect(epcisJsonLd, contains('2.0'));
      expect(epcisJsonLd, contains('https://ref.gs1.org/standards/epcis/2.0.0/epcis-context.jsonld'));

      final doc = jsonDecode(epcisJsonLd) as Map<String, dynamic>;
      expect(doc['schemaVersion'], equals('2.0'));
      expect(doc['epcisBody'], isNotNull);
    });
  });
}
