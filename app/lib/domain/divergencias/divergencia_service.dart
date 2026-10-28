import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/app_database.dart';
import '../eventos/evento_service.dart';
import '../eventos/evento_v2.dart';
import '../identidade/identidade_service.dart';
import 'divergencia_models.dart';

/// Motor de detecção, diagnóstico e resolução de divergências patrimoniais
class DivergenciaService {
  static const _uuid = Uuid();

  /// Calcula a fila atualizada de divergências a partir do estado do banco
  static Future<List<DivergenciaItem>> obterFilaDivergencias(AppDatabase db) async {
    final todosBens = await db.select(db.bens).get();
    final todosLocais = await db.select(db.locais).get();
    final mapaLocais = {for (final l in todosLocais) l.id: l.nome};

    final conferenciasSalas = await db.select(db.conferenciaSalas).get();
    final salasFechadasOuEmAndamento = conferenciasSalas
        .where((c) => c.status == 'concluida' || c.status == 'em_andamento')
        .map((c) => c.localId)
        .toSet();

    final eventosLeitura = await (db.select(db.eventos)
          ..where((tbl) => tbl.tipo.isIn(const [
                TiposEvento.leitura,
                TiposEvento.confirmacao,
                TiposEvento.leituraManual,
                TiposEvento.bemNovo,
              ]))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.seq)]))
        .get();

    final eventosResolucao = await (db.select(db.eventos)
          ..where((tbl) => tbl.tipo.equals(TiposEvento.divergenciaResolvida)))
        .get();

    final tombamentosResolvidos = <String, String>{};
    for (final ev in eventosResolucao) {
      try {
        final payload = jsonDecode(ev.payload);
        if (payload is Map && payload['tombamento'] != null) {
          tombamentosResolvidos[payload['tombamento'].toString()] =
              payload['decisao']?.toString() ?? 'Resolvida';
        }
      } catch (_) {}
    }

    final leiturasPorTombamento = <String, List<Evento>>{};
    for (final e in eventosLeitura) {
      final t = e.tombamento;
      if (t != null && t.isNotEmpty) {
        leiturasPorTombamento.putIfAbsent(t, () => []).add(e);
      }
    }

    final listaDivergencias = <DivergenciaItem>[];
    final mapaBens = {for (final b in todosBens) b.tombamento: b};

    // 1. Bens lidos em salas divergentes ou conflitos entre conferentes
    for (final entry in leiturasPorTombamento.entries) {
      final tombamento = entry.key;
      final leituras = entry.value;
      final bem = mapaBens[tombamento];

      // Caso A: Bem não cadastrado previamente no CSV
      if (bem == null) {
        final ultimaLeitura = leituras.last;
        final localNome = mapaLocais[ultimaLeitura.localId] ?? ultimaLeitura.localId;
        final resolvida = tombamentosResolvidos.containsKey(tombamento);

        listaDivergencias.add(
          DivergenciaItem(
            id: 'div_sem_cad_$tombamento',
            tombamento: tombamento,
            descricao: 'Item não cadastrado na base oficial da unidade',
            tipo: TipoDivergencia.semCadastro,
            localEsperadoId: 'desconhecido',
            localEsperadoNome: 'Não cadastrado',
            localEncontradoId: ultimaLeitura.localId,
            localEncontradoNome: localNome,
            causaProvavel: 'Bem adquirido recentemente, doado ou transferido sem cadastro no Thema-GRP.',
            proximoPasso: 'Emitir plaqueta provisória e solicitar regularização patrimonial.',
            resolvida: resolvida,
            resolucao: tombamentosResolvidos[tombamento],
            dataCriacao: ultimaLeitura.timestamp,
          ),
        );
        continue;
      }

      // Caso B: Conflito de conferência (múltiplas leituras com locais ou estados discordantes)
      final locaisDistintos = leituras.map((l) => l.localId).toSet();
      final conferentesDistintos = leituras.map((l) => l.conferente).toSet();

      if (locaisDistintos.length > 1 && conferentesDistintos.length > 1) {
        final leituraA = leituras.first;
        final leituraB = leituras.last;
        final resolvida = tombamentosResolvidos.containsKey(tombamento);

        listaDivergencias.add(
          DivergenciaItem(
            id: 'div_conflito_$tombamento',
            tombamento: tombamento,
            descricao: bem.descricao,
            tipo: TipoDivergencia.conflitoConferentes,
            localEsperadoId: bem.localEsperadoId,
            localEsperadoNome: mapaLocais[bem.localEsperadoId] ?? bem.localEsperadoId,
            localEncontradoId: leituraB.localId,
            localEncontradoNome: mapaLocais[leituraB.localId] ?? leituraB.localId,
            causaProvavel: 'Dois conferentes registraram localizações distintas durante o inventário.',
            proximoPasso: 'Analisar evidências fotográficas e confirmar a localização verídica.',
            conflito: ConflitoLadoALado(
              conferenteA: leituraA.conferente,
              dataA: leituraA.timestamp,
              salaA: mapaLocais[leituraA.localId] ?? leituraA.localId,
              hashFotoA: leituraA.hashFoto,
              conferenteB: leituraB.conferente,
              dataB: leituraB.timestamp,
              salaB: mapaLocais[leituraB.localId] ?? leituraB.localId,
              hashFotoB: leituraB.hashFoto,
            ),
            resolvida: resolvida,
            resolucao: tombamentosResolvidos[tombamento],
            dataCriacao: leituraB.timestamp,
          ),
        );
        continue;
      }

      // Caso C: Encontrado em sala divergente
      final ultimaLeitura = leituras.last;
      if (ultimaLeitura.localId != bem.localEsperadoId) {
        final resolvida = tombamentosResolvidos.containsKey(tombamento);
        final localEncontradoNome = mapaLocais[ultimaLeitura.localId] ?? ultimaLeitura.localId;
        final localEsperadoNome = mapaLocais[bem.localEsperadoId] ?? bem.localEsperadoId;

        listaDivergencias.add(
          DivergenciaItem(
            id: 'div_sala_$tombamento',
            tombamento: tombamento,
            descricao: bem.descricao,
            tipo: TipoDivergencia.salaIncorreta,
            localEsperadoId: bem.localEsperadoId,
            localEsperadoNome: localEsperadoNome,
            localEncontradoId: ultimaLeitura.localId,
            localEncontradoNome: localEncontradoNome,
            causaProvavel: 'Movimentação física de setor sem emissão da guia de transferência.',
            proximoPasso: 'Aprovar transferência para $localEncontradoNome e atualizar carga.',
            resolvida: resolvida,
            resolucao: tombamentosResolvidos[tombamento],
            dataCriacao: ultimaLeitura.timestamp,
          ),
        );
      }
    }

    // 2. Bens não localizados em salas já conferidas
    for (final bem in todosBens) {
      if (salasFechadasOuEmAndamento.contains(bem.localEsperadoId)) {
        final leituras = leiturasPorTombamento[bem.tombamento];
        if (leituras == null || leituras.isEmpty) {
          final resolvida = tombamentosResolvidos.containsKey(bem.tombamento);
          final localNome = mapaLocais[bem.localEsperadoId] ?? bem.localEsperadoId;

          listaDivergencias.add(
            DivergenciaItem(
              id: 'div_nao_loc_${bem.tombamento}',
              tombamento: bem.tombamento,
              descricao: bem.descricao,
              tipo: TipoDivergencia.naoLocalizado,
              localEsperadoId: bem.localEsperadoId,
              localEsperadoNome: localNome,
              causaProvavel: 'Bem não encontrado na varredura. Possível extravio, baixa pendente ou recolhimento.',
              proximoPasso: 'Realizar busca nas salas vizinhas ou registrar baixa patrimonial provisória.',
              resolvida: resolvida,
              resolucao: tombamentosResolvidos[bem.tombamento],
              dataCriacao: DateTime.now().toUtc(),
            ),
          );
        }
      }
    }

    // Ordenar: primeiro não resolvidas, depois por data
    listaDivergencias.sort((a, b) {
      if (a.resolvida != b.resolvida) {
        return a.resolvida ? 1 : -1;
      }
      return b.dataCriacao.compareTo(a.dataCriacao);
    });

    return listaDivergencias;
  }

  /// Resolve uma divergência individual emitindo evento DIVERGENCIA_RESOLVIDA assinado pelo gestor
  static Future<EventoV2> resolverDivergencia({
    required AppDatabase db,
    required String unidadeId,
    required String tombamento,
    required String decisao,
    required String justificativa,
    String? novoLocalId,
    required SimpleKeyPair keyPairGestor,
  }) async {
    final autorGestor = IdentidadeService.bytesParaHex(
      (await keyPairGestor.extractPublicKey()).bytes,
    );

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
      'tombamento': tombamento,
      'decisao': decisao,
      'justificativa': justificativa,
    };
    if (novoLocalId != null && novoLocalId.isNotEmpty) {
      payload['novo_local_id'] = novoLocalId;
    }

    final evento = await EventoV2.criar(
      id: _uuid.v4(),
      unidadeId: unidadeId,
      tipo: TiposEvento.divergenciaResolvida,
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

  /// Resolve um lote de divergências de uma vez só
  static Future<List<EventoV2>> resolverEmLote({
    required AppDatabase db,
    required String unidadeId,
    required List<DivergenciaItem> itens,
    required String decisao,
    required String justificativa,
    required SimpleKeyPair keyPairGestor,
  }) async {
    final eventos = <EventoV2>[];
    for (final item in itens) {
      final ev = await resolverDivergencia(
        db: db,
        unidadeId: unidadeId,
        tombamento: item.tombamento,
        decisao: decisao,
        justificativa: justificativa,
        novoLocalId: item.localEncontradoId,
        keyPairGestor: keyPairGestor,
      );
      eventos.add(ev);
    }
    return eventos;
  }
}
