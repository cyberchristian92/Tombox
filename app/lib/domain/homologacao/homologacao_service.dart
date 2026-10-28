import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/app_database.dart';
import '../divergencias/divergencia_service.dart';
import '../eventos/evento_service.dart';
import '../eventos/evento_v2.dart';
import '../identidade/identidade_service.dart';
import 'homologacao_models.dart';

/// Serviço responsável pelo fluxo formal de homologação pelo Gestor Patrimonial
class HomologacaoService {
  static const _uuid = Uuid();

  /// Verifica se uma sala específica já foi homologada pelo gestor
  static Future<bool> isSalaHomologada(AppDatabase db, String salaId) async {
    final evHomologacao = await (db.select(db.eventos)
          ..where((tbl) => tbl.tipo.equals(TiposEvento.homologacao)))
        .get();

    for (final e in evHomologacao) {
      try {
        final payload = jsonDecode(e.payload);
        if (payload is Map && payload['sala_id'] == salaId) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  /// Retorna o panorama de homologação de todas as salas da unidade
  static Future<List<StatusHomologacaoSala>> obterStatusSalas(AppDatabase db) async {
    final todosLocais = await db.select(db.locais).get();
    final salas = todosLocais.where((l) => l.tipo == 'sala').toList();

    final todosBens = await db.select(db.bens).get();
    final eventosLeitura = await (db.select(db.eventos)
          ..where((tbl) => tbl.tipo.isIn(const [
                TiposEvento.leitura,
                TiposEvento.confirmacao,
                TiposEvento.leituraManual,
              ])))
        .get();

    final tombamentosLidos = eventosLeitura
        .map((e) => e.tombamento)
        .where((t) => t != null && t.isNotEmpty)
        .toSet();

    final todasDivergencias = await DivergenciaService.obterFilaDivergencias(db);
    final divergenciasPendentesPorSala = <String, int>{};
    for (final div in todasDivergencias) {
      if (!div.resolvida) {
        divergenciasPendentesPorSala[div.localEsperadoId] =
            (divergenciasPendentesPorSala[div.localEsperadoId] ?? 0) + 1;
      }
    }

    final eventosHomologacao = await (db.select(db.eventos)
          ..where((tbl) => tbl.tipo.equals(TiposEvento.homologacao)))
        .get();

    final mapaHomologacoes = <String, Evento>{};
    for (final eh in eventosHomologacao) {
      try {
        final payload = jsonDecode(eh.payload);
        if (payload is Map && payload['sala_id'] != null) {
          mapaHomologacoes[payload['sala_id'].toString()] = eh;
        }
      } catch (_) {}
    }

    final resultado = <StatusHomologacaoSala>[];

    for (final sala in salas) {
      final bensDaSala = todosBens.where((b) => b.localEsperadoId == sala.id).toList();
      final conferidos = bensDaSala.where((b) => tombamentosLidos.contains(b.tombamento)).length;
      final pendentes = divergenciasPendentesPorSala[sala.id] ?? 0;

      final evH = mapaHomologacoes[sala.id];
      final homologada = evH != null;
      DateTime? dataH;
      String? homologadoPor;
      String? obs;

      if (evH != null) {
        dataH = evH.timestamp;
        homologadoPor = evH.conferente.isNotEmpty ? evH.conferente : evH.autor.substring(0, 8);
        try {
          final p = jsonDecode(evH.payload);
          if (p is Map) obs = p['observacao']?.toString();
        } catch (_) {}
      }

      resultado.add(
        StatusHomologacaoSala(
          salaId: sala.id,
          salaNome: sala.nome,
          caminhoCompleto: sala.caminhoCompleto,
          homologada: homologada,
          dataHomologacao: dataH,
          homologadoPor: homologadoPor,
          totalBens: bensDaSala.length,
          bensConferidos: conferidos,
          divergenciasPendentes: pendentes,
          observacao: obs,
        ),
      );
    }

    return resultado;
  }

  /// Emite evento HOMOLOGACAO assinado pelo Gestor para aprovar os resultados da sala
  static Future<EventoV2> homologarSala({
    required AppDatabase db,
    required String unidadeId,
    required String salaId,
    required SimpleKeyPair keyPairGestor,
    String? observacao,
  }) async {
    final autorGestor = IdentidadeService.bytesParaHex(
      (await keyPairGestor.extractPublicKey()).bytes,
    );

    // 1. Obter bens lidos da sala
    final bensDaSala = await (db.select(db.bens)
          ..where((tbl) => tbl.localEsperadoId.equals(salaId)))
        .get();

    final eventosLeitura = await (db.select(db.eventos)
          ..where((tbl) => tbl.localId.equals(salaId) & tbl.tipo.isIn(const [
                TiposEvento.leitura,
                TiposEvento.confirmacao,
                TiposEvento.leituraManual,
              ])))
        .get();

    final tombamentosHomologados = eventosLeitura
        .map((e) => e.tombamento)
        .where((t) => t != null && t.isNotEmpty)
        .toSet()
        .toList();

    // 2. Obter maior sequência e hash anterior do gestor
    final ultimoEventoGestor = await (db.select(db.eventos)
          ..where((tbl) => tbl.autor.equals(autorGestor))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.seq)])
          ..limit(1))
        .getSingleOrNull();

    final seq = (ultimoEventoGestor?.seq ?? 0) + 1;
    final hashAnterior = ultimoEventoGestor?.hash ?? EventoV2.hashInicial;

    final todosEventos = await db.select(db.eventos).get();
    final conhecidos = <String, String>{};
    for (final e in todosEventos) {
      if (e.autor != autorGestor && e.autor.isNotEmpty) {
        conhecidos[e.autor] = e.hash;
      }
    }

    final payload = <String, dynamic>{
      'sala_id': salaId,
      'total_bens_sala': bensDaSala.length,
      'tombamentos_homologados': tombamentosHomologados,
      'observacao': observacao ?? 'Conferência patrimonial homologada sem ressalvas pelo Gestor.',
      'data_homologacao': DateTime.now().toUtc().toIso8601String(),
    };

    final evento = await EventoV2.criar(
      id: _uuid.v4(),
      unidadeId: unidadeId,
      tipo: TiposEvento.homologacao,
      autor: autorGestor,
      seq: seq,
      hashAnterior: hashAnterior,
      conhecidos: conhecidos,
      payload: payload,
      keyPair: keyPairGestor,
    );

    await EventoService.aplicarEventoExterno(db: db, evento: evento);
    return evento;
  }

  /// Homologa múltiplas salas em lote
  static Future<List<EventoV2>> homologarEmLote({
    required AppDatabase db,
    required String unidadeId,
    required List<String> salaIds,
    required SimpleKeyPair keyPairGestor,
    String? observacao,
  }) async {
    final eventos = <EventoV2>[];
    for (final salaId in salaIds) {
      final ev = await homologarSala(
        db: db,
        unidadeId: unidadeId,
        salaId: salaId,
        keyPairGestor: keyPairGestor,
        observacao: observacao,
      );
      eventos.add(ev);
    }
    return eventos;
  }

  /// Retorna apenas os bens homologados pelo Gestor (utilizado no relatório oficial)
  static Future<List<Bem>> obterBensHomologados(AppDatabase db) async {
    final salasStatus = await obterStatusSalas(db);
    final salasHomologadas = salasStatus
        .where((s) => s.homologada)
        .map((s) => s.salaId)
        .toSet();

    if (salasHomologadas.isEmpty) return [];

    return await (db.select(db.bens)
          ..where((tbl) => tbl.localEsperadoId.isIn(salasHomologadas)))
        .get();
  }
}
