import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import '../identidade/identidade_service.dart';

/// Tipos oficiais de evento na Arquitetura v2
class TiposEvento {
  static const String unidadeCriada = 'UNIDADE_CRIADA';
  static const String bemImportado = 'BEM_IMPORTADO';
  static const String membroAdicionado = 'MEMBRO_ADICIONADO';
  static const String membroRevogado = 'MEMBRO_REVOGADO';
  static const String aberturaSala = 'ABERTURA_SALA';
  static const String leitura = 'LEITURA';
  static const String confirmacao = 'CONFIRMACAO';
  static const String leituraManual = 'LEITURA_MANUAL';
  static const String estado = 'ESTADO';
  static const String observacao = 'OBSERVACAO';
  static const String foto = 'FOTO';
  static const String movimentacao = 'MOVIMENTACAO';
  static const String bemNovo = 'BEM_NOVO';
  static const String fechamentoSala = 'FECHAMENTO_SALA';
  static const String termoAssinado = 'TERMO_ASSINADO';
  static const String divergenciaResolvida = 'DIVERGENCIA_RESOLVIDA';
  static const String atributoProposto = 'ATRIBUTO_PROPOSTO';
  static const String homologacao = 'HOMOLOGACAO';
}

/// Representa um Evento imutável assinado criptograficamente (Arquitetura v2)
class EventoV2 {
  static const String hashInicial =
      '0000000000000000000000000000000000000000000000000000000000000000';

  final String id; // UUID v4
  final String unidadeId;
  final String tipo;
  final String autor; // Chave pública Ed25519 em hexadecimal
  final int seq; // Contador sequencial crescente por autor
  final String hashAnterior; // SHA-256 do último evento do mesmo autor
  final Map<String, String> conhecidos; // Vector clock: autor -> hash do último visto
  final DateTime timestamp; // Relógio com fuso (ISO8601 UTC)
  final Map<String, dynamic> payload; // Dados da operação
  final String hash; // SHA-256 do JSON canônico sem hash e assinatura
  final String assinatura; // Assinatura Ed25519 do hash

  const EventoV2({
    required this.id,
    required this.unidadeId,
    required this.tipo,
    required this.autor,
    required this.seq,
    required this.hashAnterior,
    required this.conhecidos,
    required this.timestamp,
    required this.payload,
    required this.hash,
    required this.assinatura,
  });

  /// Ordena recursivamente mapas e listas para JSON determinístico
  static dynamic _canonizar(dynamic obj) {
    if (obj is Map) {
      final chavesOrdenadas = obj.keys.map((e) => e.toString()).toList()..sort();
      final mapaOrdenado = <String, dynamic>{};
      for (final k in chavesOrdenadas) {
        mapaOrdenado[k] = _canonizar(obj[k]);
      }
      return mapaOrdenado;
    } else if (obj is List) {
      return obj.map(_canonizar).toList();
    }
    return obj;
  }

  /// Normaliza timestamp para precisão de segundos em UTC, garantindo determinismo
  /// entre serializações no SQLite (Drift), JSON e transmissão de rede.
  static DateTime normalizarTimestamp(DateTime dt) {
    return DateTime.fromMillisecondsSinceEpoch(
      (dt.toUtc().millisecondsSinceEpoch ~/ 1000) * 1000,
      isUtc: true,
    );
  }

  /// Gera a representação canônica em JSON (sem hash e sem assinatura)
  static String gerarJsonCanonico({
    required String id,
    required String unidadeId,
    required String tipo,
    required String autor,
    required int seq,
    required String hashAnterior,
    required Map<String, String> conhecidos,
    required DateTime timestamp,
    required Map<String, dynamic> payload,
  }) {
    final mapaBase = <String, dynamic>{
      'autor': autor,
      'conhecidos': conhecidos,
      'hash_anterior': hashAnterior,
      'id': id,
      'payload': payload,
      'seq': seq,
      'timestamp': normalizarTimestamp(timestamp).toIso8601String(),
      'tipo': tipo,
      'unidade_id': unidadeId,
    };
    final canonico = _canonizar(mapaBase);
    return jsonEncode(canonico);
  }

  /// Calcula o hash SHA-256 a partir dos campos canônicos do evento
  static String calcularHash({
    required String id,
    required String unidadeId,
    required String tipo,
    required String autor,
    required int seq,
    required String hashAnterior,
    required Map<String, String> conhecidos,
    required DateTime timestamp,
    required Map<String, dynamic> payload,
  }) {
    final jsonCanonico = gerarJsonCanonico(
      id: id,
      unidadeId: unidadeId,
      tipo: tipo,
      autor: autor,
      seq: seq,
      hashAnterior: hashAnterior,
      conhecidos: conhecidos,
      timestamp: normalizarTimestamp(timestamp),
      payload: payload,
    );
    return sha256.convert(utf8.encode(jsonCanonico)).toString();
  }

  /// Constrói e assina digitalmente um novo EventoV2
  static Future<EventoV2> criar({
    required String id,
    required String unidadeId,
    required String tipo,
    required String autor,
    required int seq,
    required String hashAnterior,
    required Map<String, String> conhecidos,
    DateTime? timestamp,
    required Map<String, dynamic> payload,
    SimpleKeyPair? keyPair,
  }) async {
    final agora = normalizarTimestamp(timestamp ?? DateTime.now());
    final hashCalculado = calcularHash(
      id: id,
      unidadeId: unidadeId,
      tipo: tipo,
      autor: autor,
      seq: seq,
      hashAnterior: hashAnterior,
      conhecidos: conhecidos,
      timestamp: agora,
      payload: payload,
    );

    final assinaturaCalculada = await IdentidadeService.assinar(
      hashCalculado,
      keyPair: keyPair,
    );

    return EventoV2(
      id: id,
      unidadeId: unidadeId,
      tipo: tipo,
      autor: autor,
      seq: seq,
      hashAnterior: hashAnterior,
      conhecidos: conhecidos,
      timestamp: agora,
      payload: payload,
      hash: hashCalculado,
      assinatura: assinaturaCalculada,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unidade_id': unidadeId,
      'tipo': tipo,
      'autor': autor,
      'seq': seq,
      'hash_anterior': hashAnterior,
      'conhecidos': conhecidos,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'payload': payload,
      'hash': hash,
      'assinatura': assinatura,
    };
  }

  factory EventoV2.fromMap(Map<String, dynamic> map) {
    Map<String, String> parseConhecidos(dynamic val) {
      if (val is Map) {
        return val.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
      if (val is String && val.isNotEmpty) {
        try {
          final decoded = jsonDecode(val);
          if (decoded is Map) {
            return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
          }
        } catch (_) {}
      }
      return {};
    }

    Map<String, dynamic> parsePayload(dynamic val) {
      if (val is Map<String, dynamic>) return val;
      if (val is Map) return val.map((k, v) => MapEntry(k.toString(), v));
      if (val is String && val.isNotEmpty) {
        try {
          final decoded = jsonDecode(val);
          if (decoded is Map) {
            return decoded.map((k, v) => MapEntry(k.toString(), v));
          }
        } catch (_) {}
      }
      return {};
    }

    return EventoV2(
      id: map['id'] as String,
      unidadeId: map['unidade_id'] as String? ?? map['unidadeId'] as String? ?? 'unidade_demo',
      tipo: map['tipo'] as String,
      autor: map['autor'] as String,
      seq: (map['seq'] as num).toInt(),
      hashAnterior: map['hash_anterior'] as String? ?? map['hashAnterior'] as String? ?? hashInicial,
      conhecidos: parseConhecidos(map['conhecidos']),
      timestamp: normalizarTimestamp(DateTime.parse(map['timestamp'].toString())),
      payload: parsePayload(map['payload']),
      hash: map['hash'] as String,
      assinatura: map['assinatura'] as String,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory EventoV2.fromJson(String str) =>
      EventoV2.fromMap(jsonDecode(str) as Map<String, dynamic>);
}
