import 'dart:convert';
import '../../data/local/app_database.dart';
import '../eventos/evento_v2.dart';

/// Serviço responsável por transformar a cadeia de eventos imutáveis do Tombox
/// no padrão global GS1 EPCIS 2.0 (Electronic Product Code Information Services) em JSON-LD
class EpcisService {
  /// Gera o documento EPCIS 2.0 JSON-LD a partir dos eventos da unidade
  static Future<String> exportarEpcisJsonLd({
    required AppDatabase db,
    String? unidadeId,
  }) async {
    final query = db.select(db.eventos);
    if (unidadeId != null && unidadeId.isNotEmpty) {
      query.where((tbl) => tbl.unidadeId.equals(unidadeId));
    }
    final eventosRows = await query.get();

    final eventList = <Map<String, dynamic>>[];

    for (final e in eventosRows) {
      Map<String, dynamic> payload = {};
      try {
        final decoded = jsonDecode(e.payload);
        if (decoded is Map) payload = Map<String, dynamic>.from(decoded);
      } catch (_) {}

      final dataIso = e.timestamp.toUtc().toIso8601String();
      final tombamento = e.tombamento ?? payload['tombamento']?.toString() ?? 'DESCONHECIDO';
      final epc = 'urn:epc:id:sgtin:tjpa.patrimonio.$tombamento';
      final local = e.localId.isNotEmpty ? e.localId : 'geral';
      final readPoint = 'urn:epc:id:sgln:tjpa.${e.unidadeId}.$local';

      if (e.tipo == TiposEvento.leitura ||
          e.tipo == TiposEvento.confirmacao ||
          e.tipo == TiposEvento.leituraManual ||
          e.tipo == TiposEvento.estado) {
        eventList.add({
          'type': 'ObjectEvent',
          'action': 'OBSERVE',
          'bizStep': 'urn:epcglobal:cbv:bizstep:inspecting',
          'disposition': 'urn:epcglobal:cbv:disp:active',
          'eventTime': dataIso,
          'eventTimeZoneOffset': '-03:00',
          'epcList': [epc],
          'readPoint': {'id': readPoint},
          'tjpa:eventoId': e.id,
          'tjpa:seq': e.seq,
          'tjpa:autor': e.autor,
          'tjpa:hashEvento': e.hash,
          'tjpa:assinatura': e.assinatura,
          'tjpa:tipoEvento': e.tipo,
        });
      } else if (e.tipo == TiposEvento.foto) {
        final fotoHash = payload['hash_foto']?.toString() ?? payload['foto_hash']?.toString() ?? '';
        eventList.add({
          'type': 'ObjectEvent',
          'action': 'OBSERVE',
          'bizStep': 'urn:epcglobal:cbv:bizstep:inspecting',
          'disposition': 'urn:epcglobal:cbv:disp:active',
          'eventTime': dataIso,
          'eventTimeZoneOffset': '-03:00',
          'epcList': [epc],
          'readPoint': {'id': readPoint},
          'tjpa:fotoHashSha256': fotoHash,
          'tjpa:tamanhoBytes': payload['tamanho_bytes'],
          'tjpa:eventoId': e.id,
        });
      } else if (e.tipo == TiposEvento.movimentacao) {
        final localDestino = payload['novo_local_id']?.toString() ?? local;
        eventList.add({
          'type': 'ObjectEvent',
          'action': 'OBSERVE',
          'bizStep': 'urn:epcglobal:cbv:bizstep:relocating',
          'disposition': 'urn:epcglobal:cbv:disp:in_transit',
          'eventTime': dataIso,
          'eventTimeZoneOffset': '-03:00',
          'epcList': [epc],
          'readPoint': {'id': readPoint},
          'destinationList': [
            {
              'type': 'urn:epcglobal:cbv:sdt:location',
              'destination': 'urn:epc:id:sgln:tjpa.${e.unidadeId}.$localDestino',
            }
          ],
          'tjpa:eventoId': e.id,
        });
      } else if (e.tipo == TiposEvento.termoAssinado || e.tipo == TiposEvento.fechamentoSala) {
        final pdfHash = payload['pdf_hash']?.toString() ?? '';
        eventList.add({
          'type': 'TransactionEvent',
          'action': 'ADD',
          'bizStep': 'urn:epcglobal:cbv:bizstep:closing',
          'disposition': 'urn:epcglobal:cbv:disp:conformed',
          'eventTime': dataIso,
          'eventTimeZoneOffset': '-03:00',
          'readPoint': {'id': readPoint},
          'bizTransactionList': [
            {
              'type': 'urn:epcglobal:cbv:btt:inv',
              'bizTransaction': 'urn:epc:id:sgln:tjpa.termo.$pdfHash',
            }
          ],
          'tjpa:signatarioNome': payload['signatario_nome'] ?? payload['responsavel_nome'],
          'tjpa:signatarioMatricula': payload['signatario_matricula'] ?? payload['responsavel_matricula'],
          'tjpa:pdfHashSha256': pdfHash,
          'tjpa:eventoId': e.id,
        });
      }
    }

    final epcisDoc = {
      '@context': [
        'https://ref.gs1.org/standards/epcis/2.0.0/epcis-context.jsonld',
        {
          'tjpa': 'https://tjpa.jus.br/epcis/v1/',
        }
      ],
      'type': 'EPCISDocument',
      'schemaVersion': '2.0',
      'creationDate': DateTime.now().toUtc().toIso8601String(),
      'epcisBody': {
        'eventList': eventList,
      },
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(epcisDoc);
  }
}
