import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/app_database.dart';

class EventoService {
  static const _uuid = Uuid();
  static const String hashInicial =
      '0000000000000000000000000000000000000000000000000000000000000000';

  /// Gera JSON canônico com chaves ordenadas alfabeticamente para cálculo de hash
  static String gerarJsonCanonico(Map<String, dynamic> mapa) {
    final chavesOrdenadas = mapa.keys.toList()..sort();
    final mapaOrdenado = <String, dynamic>{};
    for (final k in chavesOrdenadas) {
      mapaOrdenado[k] = mapa[k];
    }
    return jsonEncode(mapaOrdenado);
  }

  /// Calcula o hash SHA-256 do JSON canônico
  static String calcularHashEvento(Map<String, dynamic> dadosSemHash) {
    final jsonCanonico = gerarJsonCanonico(dadosSemHash);
    return sha256.convert(utf8.encode(jsonCanonico)).toString();
  }

  /// Registra um evento imutável no banco com hash encadeado
  static Future<void> registrar({
    required AppDatabase db,
    required String tipo,
    required String localId,
    required String aparelhoId,
    required String conferente,
    String? tombamento,
    Map<String, dynamic>? payload,
    String? hashFoto,
  }) async {
    final ultimoEvento = await db.obterUltimoEvento(aparelhoId);
    final proximaSeq = (ultimoEvento?.seq ?? 0) + 1;
    final hashAnterior = ultimoEvento?.hash ?? hashInicial;

    final id = _uuid.v4();
    final agora = DateTime.now().toUtc();
    final payloadMap = payload ?? <String, dynamic>{};
    final payloadJson = jsonEncode(payloadMap);

    final dadosParaHash = <String, dynamic>{
      'aparelhoId': aparelhoId,
      'conferente': conferente,
      'hashAnterior': hashAnterior,
      'hashFoto': hashFoto,
      'id': id,
      'localId': localId,
      'payload': payloadJson,
      'seq': proximaSeq,
      'timestamp': agora.toIso8601String(),
      'tipo': tipo,
      'tombamento': tombamento,
    };

    final hashCalculado = calcularHashEvento(dadosParaHash);

    final eventoCompanion = EventosCompanion(
      id: Value(id),
      seq: Value(proximaSeq),
      tipo: Value(tipo),
      tombamento: Value(tombamento),
      localId: Value(localId),
      aparelhoId: Value(aparelhoId),
      conferente: Value(conferente),
      timestamp: Value(agora),
      payload: Value(payloadJson),
      hashFoto: Value(hashFoto),
      hashAnterior: Value(hashAnterior),
      hash: Value(hashCalculado),
    );

    await db.registrarEvento(eventoCompanion);

    // Feedback por vibração
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }
}
