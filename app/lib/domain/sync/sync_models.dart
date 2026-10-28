import 'dart:convert';
import 'dart:typed_data';
import '../eventos/evento_v2.dart';

/// Resumo dos eventos conhecidos por autor (Vector Clock)
class ResumoSincronizacao {
  final String aparelhoId;
  final String autorPublicKey;
  final Map<String, int> maioresSequencias; // autor -> maior seq
  final String? assinatura; // Assinatura Ed25519 do resumo

  const ResumoSincronizacao({
    required this.aparelhoId,
    required this.autorPublicKey,
    required this.maioresSequencias,
    this.assinatura,
  });

  Map<String, dynamic> toMap() {
    return {
      'aparelho_id': aparelhoId,
      'autor_public_key': autorPublicKey,
      'maiores_sequencias': maioresSequencias,
      if (assinatura != null) 'assinatura': assinatura,
    };
  }

  factory ResumoSincronizacao.fromMap(Map<String, dynamic> map) {
    final seqsRaw = map['maiores_sequencias'];
    final seqs = <String, int>{};
    if (seqsRaw is Map) {
      seqsRaw.forEach((k, v) {
        seqs[k.toString()] = (v as num).toInt();
      });
    }
    return ResumoSincronizacao(
      aparelhoId: map['aparelho_id'] as String? ?? 'aparelho',
      autorPublicKey: map['autor_public_key'] as String? ?? '',
      maioresSequencias: seqs,
      assinatura: map['assinatura'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ResumoSincronizacao.fromJson(String source) =>
      ResumoSincronizacao.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

/// Pacote de transferência de dados (eventos e fotos)
class PacoteSincronizacao {
  final String unidadeId;
  final String remetente;
  final List<EventoV2> eventos;
  final Map<String, Uint8List> fotos; // sha256 -> bytes

  const PacoteSincronizacao({
    required this.unidadeId,
    required this.remetente,
    required this.eventos,
    this.fotos = const {},
  });

  Map<String, dynamic> toMapSemFotos() {
    return {
      'unidade_id': unidadeId,
      'remetente': remetente,
      'eventos': eventos.map((e) => e.toMap()).toList(),
      'hashes_fotos': fotos.keys.toList(),
    };
  }
}

/// Resultado consolidado da sincronização
class ResultadoSincronizacao {
  final int eventosRecebidos;
  final int eventosAplicados;
  final int eventosQuarentena;
  final int fotosRecebidas;
  final bool convergente;
  final String? mensagem;

  const ResultadoSincronizacao({
    required this.eventosRecebidos,
    required this.eventosAplicados,
    required this.eventosQuarentena,
    required this.fotosRecebidas,
    required this.convergente,
    this.mensagem,
  });

  @override
  String toString() {
    return 'ResultadoSincronizacao(recebidos: $eventosRecebidos, aplicados: $eventosAplicados, quarentena: $eventosQuarentena, fotos: $fotosRecebidas, convergente: $convergente)';
  }
}
