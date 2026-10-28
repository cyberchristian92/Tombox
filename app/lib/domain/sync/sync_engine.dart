import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import '../../data/local/app_database.dart';
import '../eventos/evento_service.dart';
import '../eventos/evento_v2.dart';
import '../fotos/foto_service.dart';
import '../identidade/identidade_service.dart';
import 'sync_models.dart';

/// Motor de sincronização em Dart puro (Arquitetura v2)
class SyncEngine {
  /// Gera o resumo das sequências conhecidas pelo banco local (Vector Clock)
  static Future<ResumoSincronizacao> calcularResumo(
    AppDatabase db, {
    String aparelhoId = 'local_device',
    String? autorPublicKey,
  }) async {
    final todosEventos = await (db.select(db.eventos)
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.autor),
            (tbl) => OrderingTerm.asc(tbl.seq),
          ]))
        .get();

    final maioresSequencias = <String, int>{};
    for (final e in todosEventos) {
      final autor = e.autor;
      if (autor.isNotEmpty) {
        final seqAtual = maioresSequencias[autor] ?? 0;
        if (e.seq > seqAtual) {
          maioresSequencias[autor] = e.seq;
        }
      }
    }

    String pubKey = autorPublicKey ?? '';
    if (pubKey.isEmpty) {
      try {
        final id = await IdentidadeService.obterOuCriarIdentidade();
        pubKey = id.publicKeyHex;
      } catch (_) {}
    }

    final resumoSemAssinatura = ResumoSincronizacao(
      aparelhoId: aparelhoId,
      autorPublicKey: pubKey,
      maioresSequencias: maioresSequencias,
    );

    String? assinatura;
    if (pubKey.isNotEmpty) {
      try {
        assinatura = await IdentidadeService.assinar(resumoSemAssinatura.toJson());
      } catch (_) {}
    }

    return ResumoSincronizacao(
      aparelhoId: aparelhoId,
      autorPublicKey: pubKey,
      maioresSequencias: maioresSequencias,
      assinatura: assinatura,
    );
  }

  /// Calcula quais eventos o banco local possui que o aparelho remoto ainda não viu
  static Future<List<EventoV2>> extrairEventosParaEnvio(
    AppDatabase db,
    ResumoSincronizacao resumoRemoto,
  ) async {
    final todosEventos = await (db.select(db.eventos)
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.autor),
            (tbl) => OrderingTerm.asc(tbl.seq),
          ]))
        .get();

    final eventosParaEnviar = <EventoV2>[];

    for (final e in todosEventos) {
      final maiorSeqRemoto = resumoRemoto.maioresSequencias[e.autor] ?? 0;
      if (e.seq > maiorSeqRemoto) {
        Map<String, String> parseConhecidos(String jsonStr) {
          try {
            final decoded = jsonDecode(jsonStr);
            if (decoded is Map) {
              return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
            }
          } catch (_) {}
          return {};
        }

        Map<String, dynamic> parsePayload(String jsonStr) {
          try {
            final decoded = jsonDecode(jsonStr);
            if (decoded is Map<String, dynamic>) return decoded;
            if (decoded is Map) {
              return decoded.map((k, v) => MapEntry(k.toString(), v));
            }
          } catch (_) {}
          return {};
        }

        eventosParaEnviar.add(
          EventoV2(
            id: e.id,
            unidadeId: e.unidadeId,
            tipo: e.tipo,
            autor: e.autor,
            seq: e.seq,
            hashAnterior: e.hashAnterior,
            conhecidos: parseConhecidos(e.conhecidos),
            timestamp: EventoV2.normalizarTimestamp(e.timestamp),
            payload: parsePayload(e.payload),
            hash: e.hash,
            assinatura: e.assinatura,
          ),
        );
      }
    }

    return eventosParaEnviar;
  }

  /// Retorna todos os eventos locais persistidos ordenados por autor e sequência
  static Future<List<EventoV2>> extrairTodosEventos(AppDatabase db) async {
    final todosEventos = await (db.select(db.eventos)
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.autor),
            (tbl) => OrderingTerm.asc(tbl.seq),
          ]))
        .get();

    final lista = <EventoV2>[];
    for (final e in todosEventos) {
      Map<String, String> parseConhecidos(String jsonStr) {
        try {
          final decoded = jsonDecode(jsonStr);
          if (decoded is Map) {
            return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
          }
        } catch (_) {}
        return {};
      }

      Map<String, dynamic> parsePayload(String jsonStr) {
        try {
          final decoded = jsonDecode(jsonStr);
          if (decoded is Map<String, dynamic>) return decoded;
          if (decoded is Map) {
            return decoded.map((k, v) => MapEntry(k.toString(), v));
          }
        } catch (_) {}
        return {};
      }

      lista.add(
        EventoV2(
          id: e.id,
          unidadeId: e.unidadeId,
          tipo: e.tipo,
          autor: e.autor,
          seq: e.seq,
          hashAnterior: e.hashAnterior,
          conhecidos: parseConhecidos(e.conhecidos),
          timestamp: EventoV2.normalizarTimestamp(e.timestamp),
          payload: parsePayload(e.payload),
          hash: e.hash,
          assinatura: e.assinatura,
        ),
      );
    }
    return lista;
  }

  /// Aplica uma lista de eventos recebidos externamente de forma estrita e idempotente
  static Future<ResultadoSincronizacao> aplicarEventos(
    AppDatabase db,
    List<EventoV2> eventosRecebidos, {
    Map<String, Uint8List>? fotosRecebidas,
  }) async {
    int aplicados = 0;
    int quarentena = 0;
    int fotosSalvas = 0;

    // 1. Armazenar fotos associadas recebidas
    if (fotosRecebidas != null && fotosRecebidas.isNotEmpty) {
      for (final entry in fotosRecebidas.entries) {
        if (!FotoService.existeFoto(entry.key)) {
          FotoService.processarBytes(entry.value);
          fotosSalvas++;
        }
      }
    }

    // 2. Ordenar eventos por autor e por sequência crescente
    final eventosOrdenados = List<EventoV2>.from(eventosRecebidos)
      ..sort((a, b) {
        final cmpAutor = a.autor.compareTo(b.autor);
        if (cmpAutor != 0) return cmpAutor;
        return a.seq.compareTo(b.seq);
      });

    // 3. Aplicar cada evento
    for (final evento in eventosOrdenados) {
      // Idempotência estrita: se o evento já existe localmente, é ignorado sem erro
      final jaExiste = await (db.select(db.eventos)
            ..where((tbl) => tbl.id.equals(evento.id)))
          .getSingleOrNull() != null;
      if (jaExiste) {
        continue;
      }

      final sucesso = await EventoService.aplicarEventoExterno(
        db: db,
        evento: evento,
      );
      if (sucesso) {
        aplicados++;
      } else {
        quarentena++;
      }
    }

    return ResultadoSincronizacao(
      eventosRecebidos: eventosRecebidos.length,
      eventosAplicados: aplicados,
      eventosQuarentena: quarentena,
      fotosRecebidas: fotosSalvas,
      convergente: quarentena == 0,
      mensagem: quarentena == 0
          ? 'Sincronização concluída com sucesso ($aplicados eventos aplicados).'
          : 'Sincronização com $quarentena evento(s) inválido(s) retido(s) em quarentena.',
    );
  }

  /// Empacota todos os eventos e fotos da unidade em um arquivo `.tombox` (zip compactado)
  static Future<Uint8List> exportarPacoteTombox(
    AppDatabase db, {
    String unidadeId = 'unidade_demo',
  }) async {
    final archive = Archive();
    final resumo = await calcularResumo(db);

    final todosEventosDb = await (db.select(db.eventos)
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.autor),
            (tbl) => OrderingTerm.asc(tbl.seq),
          ]))
        .get();

    final listaEventosMap = <Map<String, dynamic>>[];
    final hashesFotosParaIncluir = <String>{};

    for (final e in todosEventosDb) {
      dynamic payload;
      try {
        payload = jsonDecode(e.payload);
      } catch (_) {
        payload = {};
      }

      dynamic conhecidos;
      try {
        conhecidos = jsonDecode(e.conhecidos);
      } catch (_) {
        conhecidos = {};
      }

      listaEventosMap.add({
        'id': e.id,
        'unidade_id': e.unidadeId,
        'tipo': e.tipo,
        'autor': e.autor,
        'seq': e.seq,
        'hash_anterior': e.hashAnterior,
        'conhecidos': conhecidos,
        'timestamp': EventoV2.normalizarTimestamp(e.timestamp).toIso8601String(),
        'payload': payload,
        'hash': e.hash,
        'assinatura': e.assinatura,
      });

      if (e.hashFoto != null && e.hashFoto!.isNotEmpty) {
        hashesFotosParaIncluir.add(e.hashFoto!);
      }
    }

    // 1. Arquivo manifest.json
    final manifest = {
      'versao_tombox': '2.0.0',
      'unidade_id': unidadeId,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'total_eventos': listaEventosMap.length,
      'resumo': resumo.toMap(),
      'total_fotos': hashesFotosParaIncluir.length,
    };
    final manifestJson = jsonEncode(manifest);
    final manifestBytes = utf8.encode(manifestJson);
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));

    // 2. Arquivo eventos.json
    final eventosJson = jsonEncode(listaEventosMap);
    final eventosBytes = utf8.encode(eventosJson);
    archive.addFile(ArchiveFile('eventos.json', eventosBytes.length, eventosBytes));

    // 3. Pasta fotos/
    for (final hash in hashesFotosParaIncluir) {
      final bytesFoto = FotoService.obterFoto(hash);
      if (bytesFoto != null) {
        archive.addFile(ArchiveFile('fotos/$hash.jpg', bytesFoto.length, bytesFoto));
      }
    }

    // Comprime e gera os bytes do zip .tombox
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);
    return Uint8List.fromList(zipBytes);
  }

  /// Descompacta e importa um arquivo `.tombox` validando assinaturas e aplicando eventos
  static Future<ResultadoSincronizacao> importarPacoteTombox(
    AppDatabase db,
    Uint8List zipBytes,
  ) async {
    final zipDecoder = ZipDecoder();
    final archive = zipDecoder.decodeBytes(zipBytes);

    ArchiveFile? arquivoManifest;
    ArchiveFile? arquivoEventos;
    final fotosExtraidas = <String, Uint8List>{};

    for (final file in archive) {
      if (file.name == 'manifest.json') {
        arquivoManifest = file;
      } else if (file.name == 'eventos.json') {
        arquivoEventos = file;
      } else if (file.name.startsWith('fotos/')) {
        final nome = file.name.replaceFirst('fotos/', '').replaceAll('.jpg', '').replaceAll('.webp', '');
        final bytes = file.content as List<int>;
        fotosExtraidas[nome] = Uint8List.fromList(bytes);
      }
    }

    if (arquivoManifest == null || arquivoEventos == null) {
      throw Exception('Pacote .tombox corrompido: manifest.json ou eventos.json ausente.');
    }

    final eventosJsonStr = utf8.decode(arquivoEventos.content as List<int>);
    final eventosListaDynamic = jsonDecode(eventosJsonStr) as List;

    final eventosParaAplicar = <EventoV2>[];
    for (final item in eventosListaDynamic) {
      if (item is Map) {
        eventosParaAplicar.add(EventoV2.fromMap(Map<String, dynamic>.from(item)));
      }
    }

    return await aplicarEventos(
      db,
      eventosParaAplicar,
      fotosRecebidas: fotosExtraidas,
    );
  }
}
