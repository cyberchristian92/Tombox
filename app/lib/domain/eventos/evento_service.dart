import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/app_database.dart';
import '../identidade/identidade_service.dart';
import 'evento_v2.dart';
import 'evento_validador.dart';

class EventoService {
  static const _uuid = Uuid();
  static const String hashInicial = EventoV2.hashInicial;

  /// Gera JSON canônico com chaves ordenadas alfabeticamente para cálculo de hash
  static String gerarJsonCanonico(Map<String, dynamic> mapa) {
    return EventoV2.gerarJsonCanonico(
      id: mapa['id']?.toString() ?? '',
      unidadeId: mapa['unidade_id']?.toString() ?? 'unidade_demo',
      tipo: mapa['tipo']?.toString() ?? '',
      autor: mapa['autor']?.toString() ?? '',
      seq: (mapa['seq'] as num?)?.toInt() ?? 1,
      hashAnterior: mapa['hash_anterior']?.toString() ?? hashInicial,
      conhecidos: mapa['conhecidos'] is Map
          ? (mapa['conhecidos'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()))
          : {},
      timestamp: mapa['timestamp'] != null
          ? (DateTime.tryParse(mapa['timestamp'].toString()) ?? DateTime.now())
          : DateTime.now(),
      payload: mapa['payload'] is Map<String, dynamic>
          ? mapa['payload'] as Map<String, dynamic>
          : {},
    );
  }

  /// Calcula o hash SHA-256 do JSON canônico
  static String calcularHashEvento(Map<String, dynamic> dadosSemHash) {
    return EventoV2.calcularHash(
      id: dadosSemHash['id']?.toString() ?? '',
      unidadeId: dadosSemHash['unidade_id']?.toString() ?? 'unidade_demo',
      tipo: dadosSemHash['tipo']?.toString() ?? '',
      autor: dadosSemHash['autor']?.toString() ?? '',
      seq: (dadosSemHash['seq'] as num?)?.toInt() ?? 1,
      hashAnterior: dadosSemHash['hash_anterior']?.toString() ?? hashInicial,
      conhecidos: dadosSemHash['conhecidos'] is Map
          ? (dadosSemHash['conhecidos'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()))
          : {},
      timestamp: dadosSemHash['timestamp'] != null
          ? (DateTime.tryParse(dadosSemHash['timestamp'].toString()) ?? DateTime.now())
          : DateTime.now(),
      payload: dadosSemHash['payload'] is Map<String, dynamic>
          ? dadosSemHash['payload'] as Map<String, dynamic>
          : {},
    );
  }

  /// Registra um evento imutável no banco com assinatura digital Ed25519 e hash encadeado
  static Future<EventoV2> registrar({
    required AppDatabase db,
    required String tipo,
    required String localId,
    required String aparelhoId,
    required String conferente,
    String unidadeId = 'unidade_demo',
    String? tombamento,
    Map<String, dynamic>? payload,
    String? hashFoto,
  }) async {
    // 1. Obter identidade criptográfica local (Ed25519)
    final identidade = await IdentidadeService.obterOuCriarIdentidade();
    final autorChavePublica = identidade.publicKeyHex;

    // 2. Buscar último evento deste autor no banco local
    final ultimoEvento = await (db.select(db.eventos)
          ..where((tbl) => tbl.autor.equals(autorChavePublica))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.seq)])
          ..limit(1))
        .getSingleOrNull();

    final proximaSeq = (ultimoEvento?.seq ?? 0) + 1;
    final hashAnterior = ultimoEvento?.hash ?? hashInicial;

    // 3. Montar mapa de conhecidos (último hash de cada autor diferente)
    final todosEventos = await db.select(db.eventos).get();
    final conhecidos = <String, String>{};
    for (final e in todosEventos) {
      if (e.autor != autorChavePublica && e.autor.isNotEmpty) {
        conhecidos[e.autor] = e.hash;
      }
    }

    final id = _uuid.v4();
    final agora = DateTime.now().toUtc();
    final payloadMap = Map<String, dynamic>.from(payload ?? <String, dynamic>{});
    if (tombamento != null) payloadMap['tombamento'] = tombamento;
    if (localId.isNotEmpty) payloadMap['local_id'] = localId;
    if (hashFoto != null) payloadMap['hash_foto'] = hashFoto;
    payloadMap['conferente'] = conferente;
    payloadMap['aparelho_id'] = aparelhoId;

    // 4. Criar e assinar EventoV2
    final eventoV2 = await EventoV2.criar(
      id: id,
      unidadeId: unidadeId,
      tipo: tipo,
      autor: autorChavePublica,
      seq: proximaSeq,
      hashAnterior: hashAnterior,
      conhecidos: conhecidos,
      timestamp: agora,
      payload: payloadMap,
    );

    // 5. Salvar na tabela de eventos do Drift
    final eventoCompanion = EventosCompanion(
      id: Value(eventoV2.id),
      unidadeId: Value(eventoV2.unidadeId),
      seq: Value(eventoV2.seq),
      tipo: Value(eventoV2.tipo),
      autor: Value(eventoV2.autor),
      tombamento: Value(tombamento),
      localId: Value(localId),
      aparelhoId: Value(aparelhoId),
      conferente: Value(conferente),
      timestamp: Value(agora),
      payload: Value(jsonEncode(payloadMap)),
      hashFoto: Value(hashFoto),
      hashAnterior: Value(eventoV2.hashAnterior),
      conhecidos: Value(jsonEncode(conhecidos)),
      hash: Value(eventoV2.hash),
      assinatura: Value(eventoV2.assinatura),
    );

    await db.registrarEvento(eventoCompanion);

    // Feedback por vibração
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}

    return eventoV2;
  }

  /// Processa um evento externo (por exemplo recebido por sincronização)
  /// Se válido, persiste; se inválido, envia para a quarentena.
  static Future<bool> aplicarEventoExterno({
    required AppDatabase db,
    required EventoV2 evento,
  }) async {
    // 1. Verificar se o evento já existe
    final existente = await (db.select(db.eventos)
          ..where((tbl) => tbl.id.equals(evento.id)))
        .getSingleOrNull();
    if (existente != null) {
      return true; // Idempotente
    }

    // 2. Buscar último evento do mesmo autor
    final ultimoEventoAutor = await (db.select(db.eventos)
          ..where((tbl) => tbl.autor.equals(evento.autor))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.seq)])
          ..limit(1))
        .getSingleOrNull();

    EventoV2? ultimoDoAutorConvertido;
    if (ultimoEventoAutor != null) {
      ultimoDoAutorConvertido = EventoV2(
        id: ultimoEventoAutor.id,
        unidadeId: ultimoEventoAutor.unidadeId,
        tipo: ultimoEventoAutor.tipo,
        autor: ultimoEventoAutor.autor,
        seq: ultimoEventoAutor.seq,
        hashAnterior: ultimoEventoAutor.hashAnterior,
        conhecidos: {},
        timestamp: ultimoEventoAutor.timestamp,
        payload: {},
        hash: ultimoEventoAutor.hash,
        assinatura: ultimoEventoAutor.assinatura,
      );
    }

    // 3. Validar assinatura, hash e sequência
    final resultado = await EventoValidador.validar(
      evento: evento,
      ultimoEventoDoAutor: ultimoDoAutorConvertido,
    );

    if (!resultado.valido) {
      await db.registrarQuarentena(
        id: evento.id,
        eventoJson: evento.toJson(),
        motivo: resultado.mensagem ?? 'Validação falhou',
      );
      return false;
    }

    // 4. Evento válido: persistir
    final tombamento = evento.payload['tombamento']?.toString();
    final localId = evento.payload['local_id']?.toString() ?? '';
    final conferente = evento.payload['conferente']?.toString() ?? 'Conferente';
    final aparelhoId = evento.payload['aparelho_id']?.toString() ?? evento.autor.substring(0, 8);
    final hashFoto = evento.payload['hash_foto']?.toString();

    final companion = EventosCompanion(
      id: Value(evento.id),
      unidadeId: Value(evento.unidadeId),
      seq: Value(evento.seq),
      tipo: Value(evento.tipo),
      autor: Value(evento.autor),
      tombamento: Value(tombamento),
      localId: Value(localId),
      aparelhoId: Value(aparelhoId),
      conferente: Value(conferente),
      timestamp: Value(evento.timestamp),
      payload: Value(jsonEncode(evento.payload)),
      hashFoto: Value(hashFoto),
      hashAnterior: Value(evento.hashAnterior),
      conhecidos: Value(jsonEncode(evento.conhecidos)),
      hash: Value(evento.hash),
      assinatura: Value(evento.assinatura),
    );

    await db.registrarEvento(companion);
    return true;
  }
}
