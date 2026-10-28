import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import '../../data/local/app_database.dart';
import '../eventos/evento_service.dart';
import '../eventos/evento_v2.dart';
import 'fechamento_models.dart';
import 'termo_pdf_service.dart';

/// Serviço responsável pelo processo de fechamento de salas e emissão de termos
class FechamentoService {
  /// Obtém o resumo dos dados da sala para fechamento e conferência
  static Future<ResumoFechamentoSala> obterResumoFechamento(
    AppDatabase db,
    String salaId,
  ) async {
    // 1. Obter local/sala
    final sala = await (db.select(db.locais)..where((l) => l.id.equals(salaId))).getSingleOrNull();
    final salaNome = sala?.nome ?? 'Sala $salaId';
    final unidadeId = sala?.unidadeId ?? 'unidade_01';

    // 2. Obter unidade
    final unidade = await (db.select(db.unidades)..where((u) => u.id.equals(unidadeId))).getSingleOrNull();
    final unidadeNome = unidade?.nome ?? 'Tribunal de Justiça do Pará';

    // 3. Obter bens esperados nesta sala
    final bensEsperados = await (db.select(db.bens)..where((b) => b.localEsperadoId.equals(salaId))).get();

    // 4. Obter eventos desta sala para conferência
    final eventosSala = await (db.select(db.eventos)..where((e) => e.localId.equals(salaId))).get();

    final tombamentosLidos = <String>{};
    for (final e in eventosSala) {
      if (e.tombamento != null && e.tombamento!.isNotEmpty) {
        if (e.tipo == TiposEvento.leitura ||
            e.tipo == TiposEvento.confirmacao ||
            e.tipo == TiposEvento.leituraManual ||
            e.tipo == TiposEvento.estado) {
          tombamentosLidos.add(e.tombamento!);
        }
      }
    }

    final itens = <ItemTermoBem>[];
    int totalConferidos = 0;
    int totalNaoEncontrados = 0;

    for (final b in bensEsperados) {
      final conferido = tombamentosLidos.contains(b.tombamento);
      if (conferido) {
        totalConferidos++;
        itens.add(
          ItemTermoBem(
            tombamento: b.tombamento,
            descricao: b.descricao,
            categoria: b.categoria ?? 'Geral',
            situacao: 'conferido',
            estadoConservacao: 'BOM',
          ),
        );
      } else {
        totalNaoEncontrados++;
        itens.add(
          ItemTermoBem(
            tombamento: b.tombamento,
            descricao: b.descricao,
            categoria: b.categoria ?? 'Geral',
            situacao: 'pendente',
            estadoConservacao: 'NÃO LOCALIZADO',
          ),
        );
      }
    }

    // 5. Último evento registrado na base para a cadeia de auditoria
    final ultimoEvento = await (db.select(db.eventos)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.seq)]))
        .getSingleOrNull();

    final hashUltimo = ultimoEvento?.hash ?? EventoV2.hashInicial;

    return ResumoFechamentoSala(
      salaId: salaId,
      salaNome: salaNome,
      unidadeId: unidadeId,
      unidadeNome: unidadeNome,
      totalEsperados: bensEsperados.length,
      totalConferidos: totalConferidos,
      totalNaoEncontrados: totalNaoEncontrados,
      totalOutraSala: 0,
      totalSemCadastro: 0,
      totalDivergencias: totalNaoEncontrados,
      bens: itens,
      hashUltimoEvento: hashUltimo,
    );
  }

  /// Fecha a sala gerando o PDF do termo, calculando seu SHA-256 e emitindo os eventos imutáveis
  static Future<ResultadoFechamento> fecharSalaComTermo({
    required AppDatabase db,
    required DadosTermoResponsabilidade dados,
    required String autorPublicKey,
    required String aparelhoId,
  }) async {
    // 1. Gera os bytes do PDF do termo
    final pdfBytes = await TermoPdfService.gerarTermoPdf(dados);

    // 2. Calcula SHA-256 do arquivo PDF
    final pdfHash = sha256.convert(pdfBytes).toString();

    // 3. Emite evento FECHAMENTO_SALA
    final eventoFechamento = await EventoService.registrar(
      db: db,
      tipo: TiposEvento.fechamentoSala,
      localId: dados.resumo.salaId,
      aparelhoId: aparelhoId,
      conferente: dados.conferenteNome,
      payload: {
        'sala_id': dados.resumo.salaId,
        'sala_nome': dados.resumo.salaNome,
        'unidade_id': dados.resumo.unidadeId,
        'total_esperados': dados.resumo.totalEsperados,
        'total_conferidos': dados.resumo.totalConferidos,
        'total_nao_encontrados': dados.resumo.totalNaoEncontrados,
        'taxa_cobertura': dados.resumo.taxaConferencia,
        'pdf_hash': pdfHash,
        'responsavel_nome': dados.responsavelNome,
        'responsavel_matricula': dados.responsavelMatricula,
      },
    );

    // 4. Emite evento TERMO_ASSINADO com o hash do documento
    final eventoTermo = await EventoService.registrar(
      db: db,
      tipo: TiposEvento.termoAssinado,
      localId: dados.resumo.salaId,
      aparelhoId: aparelhoId,
      conferente: dados.conferenteNome,
      payload: {
        'sala_id': dados.resumo.salaId,
        'pdf_hash': pdfHash,
        'signatario_nome': dados.responsavelNome,
        'signatario_matricula': dados.responsavelMatricula,
        'signatario_cargo': dados.responsavelCargo,
        'data_hora_assinatura': dados.dataHora.toUtc().toIso8601String(),
        'tamanho_pdf_bytes': pdfBytes.length,
      },
    );

    return ResultadoFechamento(
      pdfBytes: pdfBytes,
      pdfHash: pdfHash,
      eventoFechamentoId: eventoFechamento.id,
      eventoTermoId: eventoTermo.id,
      dataHora: dados.dataHora,
    );
  }
}
