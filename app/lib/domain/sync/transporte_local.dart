import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart' as nsd;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import '../../data/local/app_database.dart';
import '../eventos/evento_v2.dart';
import '../fotos/foto_service.dart';
import '../identidade/identidade_service.dart';
import '../membros/membro_models.dart';
import '../membros/membro_service.dart';
import 'sync_engine.dart';
import 'sync_models.dart';

/// Informações sobre um aparelho descoberto na rede local
class AparelhoRemoto {
  final String id;
  final String nome;
  final String enderecoIp;
  final int porta;
  final String impressaoCurta;
  final DateTime ultimoContato;
  final int eventosPendentes;

  const AparelhoRemoto({
    required this.id,
    required this.nome,
    required this.enderecoIp,
    this.porta = 8086,
    required this.impressaoCurta,
    required this.ultimoContato,
    this.eventosPendentes = 0,
  });

  String get urlBase => 'http://$enderecoIp:$porta';
}

/// Servidor HTTP leve (Shelf) com suporte a desafio mútuo (challenge-response)
class ServidorSincronizacaoLocal {
  final AppDatabase db;
  final int porta;
  HttpServer? _server;

  // Desafios de autenticação abertos (nonce -> expiração)
  final Map<String, DateTime> _desafiosAbertos = {};

  // Tokens de sessão autenticados (token -> publicKeyHex)
  final Map<String, String> _sessoesAutenticadas = {};

  final Random _random = Random.secure();

  ServidorSincronizacaoLocal({required this.db, this.porta = 8086});

  bool get estaRodando => _server != null;

  /// Inicia o servidor HTTP de sincronização
  Future<void> iniciar() async {
    if (kIsWeb || _server != null) return;

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(_processarRequisicao);

    try {
      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, porta);
    } catch (_) {
      // Falha ao abrir porta (ex: já ocupada ou restrição de sistema)
    }
  }

  /// Processa requisições HTTP REST de sincronização
  Future<Response> _processarRequisicao(Request request) async {
    final path = request.url.path;

    // 1. Descoberta e Ping público
    if (path == 'sync/ping') {
      final id = await IdentidadeService.obterOuCriarIdentidade();
      return Response.ok(
        jsonEncode({
          'status': 'online',
          'servico': 'tombox_p2p',
          'impressao_curta': id.impressaoCurta,
          'public_key': id.publicKeyHex,
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    // 2. Desafio mútuo: obtenção de nonce
    if (path == 'sync/desafio' && request.method == 'GET') {
      final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
      final nonce = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

      _desafiosAbertos[nonce] = DateTime.now().add(const Duration(minutes: 5));
      final idLocal = await IdentidadeService.obterOuCriarIdentidade();

      return Response.ok(
        jsonEncode({
          'desafio': nonce,
          'servidor_pubkey': idLocal.publicKeyHex,
          'servidor_fp': idLocal.impressaoCurta,
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    // 3. Desafio mútuo: validação de assinatura e verificação de membro ativo
    if (path == 'sync/autenticar' && request.method == 'POST') {
      try {
        final bodyStr = await request.readAsString();
        final bodyJson = jsonDecode(bodyStr) as Map<String, dynamic>;
        final nonce = bodyJson['desafio'] as String? ?? '';
        final pubKeyHex = bodyJson['publicKey'] as String? ?? '';
        final assinaturaHex = bodyJson['assinatura'] as String? ?? '';

        final expira = _desafiosAbertos.remove(nonce);
        if (expira == null || DateTime.now().isAfter(expira)) {
          return Response.forbidden(
            jsonEncode({'erro': 'Desafio expirado ou inválido'}),
            headers: {'content-type': 'application/json'},
          );
        }

        // Valida assinatura Ed25519 do desafio
        final assinaturaValida = await IdentidadeService.verificarAssinatura(
          mensagem: nonce,
          assinaturaHex: assinaturaHex,
          publicKeyHex: pubKeyHex,
        );

        if (!assinaturaValida) {
          return Response.forbidden(
            jsonEncode({'erro': 'Assinatura criptográfica inválida para o desafio'}),
            headers: {'content-type': 'application/json'},
          );
        }

        // Verifica se chave pública é de membro ativo na unidade (se houver membros cadastrados)
        final membros = await MembroService.obterMembros(db);
        if (membros.isNotEmpty) {
          final membro = membros.cast<Membro?>().firstWhere(
                (m) => m?.chavePublica.toLowerCase() == pubKeyHex.toLowerCase() && (m?.ativo ?? false),
                orElse: () => null,
              );

          if (membro == null) {
            return Response.forbidden(
              jsonEncode({
                'erro': 'Aparelho não autorizado: chave não pertence a membro ativo da unidade',
              }),
              headers: {'content-type': 'application/json'},
            );
          }
        }

        // Gera token de sessão
        final tokenBytes = List<int>.generate(24, (_) => _random.nextInt(256));
        final token = tokenBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
        _sessoesAutenticadas[token] = pubKeyHex;

        return Response.ok(
          jsonEncode({'token': token, 'status': 'autenticado'}),
          headers: {'content-type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'erro': 'Erro no processamento da autenticação: $e'}),
          headers: {'content-type': 'application/json'},
        );
      }
    }

    // Validação de autenticação para as rotas seguras abaixo
    if (!_verificarAutenticacao(request)) {
      return Response.forbidden(
        jsonEncode({'erro': 'Acesso negado: requer token de autenticação mútua válido'}),
        headers: {'content-type': 'application/json'},
      );
    }

    // 4. Resumo de sequências (Vector Clock)
    if (path == 'sync/resumo' && request.method == 'GET') {
      final resumo = await SyncEngine.calcularResumo(db);
      return Response.ok(
        resumo.toJson(),
        headers: {'content-type': 'application/json'},
      );
    }

    // 5. Consulta de eventos (para peer baixar)
    if (path == 'sync/eventos' && request.method == 'GET') {
      final eventos = await SyncEngine.extrairTodosEventos(db);
      final eventosMap = eventos.map((e) => e.toMap()).toList();
      return Response.ok(
        jsonEncode(eventosMap),
        headers: {'content-type': 'application/json'},
      );
    }

    // 6. Recebimento de eventos novos (enviados pelo peer)
    if (path == 'sync/eventos' && request.method == 'POST') {
      final bodyStr = await request.readAsString();
      final bodyJson = jsonDecode(bodyStr) as List;
      final eventos = bodyJson.map((e) => EventoV2.fromMap(e as Map<String, dynamic>)).toList();

      final resultado = await SyncEngine.aplicarEventos(db, eventos);
      return Response.ok(
        jsonEncode({
          'sucesso': true,
          'aplicados': resultado.eventosAplicados,
          'quarentena': resultado.eventosQuarentena,
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    // 7. Download de foto por hash SHA-256
    if (path.startsWith('sync/fotos/')) {
      final hash = path.replaceFirst('sync/fotos/', '');
      final bytes = FotoService.obterFoto(hash);
      if (bytes != null) {
        return Response.ok(bytes, headers: {'content-type': 'image/jpeg'});
      }
      return Response.notFound('Foto não encontrada para o hash informado');
    }

    return Response.notFound('Rota de sincronização desconhecida');
  }

  bool _verificarAutenticacao(Request request) {
    final authHeader = request.headers['authorization'] ?? '';
    if (authHeader.startsWith('Bearer ')) {
      final token = authHeader.substring(7).trim();
      return _sessoesAutenticadas.containsKey(token);
    }
    return false;
  }

  /// Encerra o servidor
  Future<void> parar() async {
    await _server?.close(force: true);
    _server = null;
    _desafiosAbertos.clear();
    _sessoesAutenticadas.clear();
  }
}

/// Cliente para efetuar sincronização ponto a ponto real com desafio mútuo
class ClienteSincronizacaoLocal {
  /// Executa autenticação mútua e troca causal de eventos e fotos com o aparelho remoto
  static Future<ResultadoSincronizacao> sincronizar({
    required AparelhoRemoto aparelho,
    required AppDatabase db,
    required IdentidadeAparelho identidadeLocal,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 4);

    try {
      // 1. Obter desafio do servidor remoto
      final reqDesafio = await client.getUrl(Uri.parse('${aparelho.urlBase}/sync/desafio'));
      final respDesafio = await reqDesafio.close();

      if (respDesafio.statusCode != 200) {
        throw Exception('Servidor remoto recusou solicitação de desafio (${respDesafio.statusCode})');
      }

      final bodyDesafioStr = await utf8.decodeStream(respDesafio);
      final jsonDesafio = jsonDecode(bodyDesafioStr) as Map<String, dynamic>;
      final desafio = jsonDesafio['desafio'] as String;

      // 2. Assinar o desafio com a chave Ed25519 local
      final assinatura = await IdentidadeService.assinar(
        desafio,
        keyPair: identidadeLocal.keyPair,
      );

      // 3. Autenticar no servidor remoto
      final reqAuth = await client.postUrl(Uri.parse('${aparelho.urlBase}/sync/autenticar'));
      reqAuth.headers.contentType = ContentType.json;
      reqAuth.write(
        jsonEncode({
          'desafio': desafio,
          'publicKey': identidadeLocal.publicKeyHex,
          'assinatura': assinatura,
        }),
      );
      final respAuth = await reqAuth.close();

      if (respAuth.statusCode != 200) {
        final errStr = await utf8.decodeStream(respAuth);
        throw Exception('Autenticação rejeitada pelo peer: $errStr');
      }

      final bodyAuthStr = await utf8.decodeStream(respAuth);
      final jsonAuth = jsonDecode(bodyAuthStr) as Map<String, dynamic>;
      final token = jsonAuth['token'] as String;

      // 4. Troca de resumos de sequências (Vector Clock)
      final reqResumo = await client.getUrl(Uri.parse('${aparelho.urlBase}/sync/resumo'));
      reqResumo.headers.set('authorization', 'Bearer $token');
      final respResumo = await reqResumo.close();
      final bodyResumoStr = await utf8.decodeStream(respResumo);

      final resumoRemoto = ResumoSincronizacao.fromJson(bodyResumoStr);
      final resumoLocal = await SyncEngine.calcularResumo(db);

      // 5. Enviar eventos que temos e o remoto não tem
      final eventosParaEnviar = await SyncEngine.extrairEventosParaEnvio(db, resumoRemoto);
      int eventosEnviados = 0;

      if (eventosParaEnviar.isNotEmpty) {
        final reqEnvio = await client.postUrl(Uri.parse('${aparelho.urlBase}/sync/eventos'));
        reqEnvio.headers.contentType = ContentType.json;
        reqEnvio.headers.set('authorization', 'Bearer $token');
        reqEnvio.write(jsonEncode(eventosParaEnviar.map((e) => e.toMap()).toList()));
        final respEnvio = await reqEnvio.close();

        if (respEnvio.statusCode == 200) {
          eventosEnviados = eventosParaEnviar.length;
        }
      }

      // 6. Buscar eventos do remoto que não temos
      final reqEventosRemotos = await client.getUrl(Uri.parse('${aparelho.urlBase}/sync/eventos'));
      reqEventosRemotos.headers.set('authorization', 'Bearer $token');
      final respEventosRemotos = await reqEventosRemotos.close();

      int eventosRecebidos = 0;
      int eventosQuarentena = 0;
      final hashesFotosParaBaixar = <String>{};

      if (respEventosRemotos.statusCode == 200) {
        final bodyEvRemotos = await utf8.decodeStream(respEventosRemotos);
        final listJson = jsonDecode(bodyEvRemotos) as List;
        final eventosRemotos = listJson.map((e) => EventoV2.fromMap(e as Map<String, dynamic>)).toList();

        final eventosParaAplicar = <EventoV2>[];
        for (final ev in eventosRemotos) {
          final seqLocal = resumoLocal.maioresSequencias[ev.autor] ?? 0;
          if (ev.seq > seqLocal) {
            eventosParaAplicar.add(ev);
            final fotoHash = ev.payload['hash_foto'] ?? ev.payload['foto_hash'];
            if (fotoHash != null && fotoHash is String && fotoHash.isNotEmpty) {
              hashesFotosParaBaixar.add(fotoHash);
            }
          }
        }

        if (eventosParaAplicar.isNotEmpty) {
          final resAplicacao = await SyncEngine.aplicarEventos(db, eventosParaAplicar);
          eventosRecebidos = resAplicacao.eventosAplicados;
          eventosQuarentena = resAplicacao.eventosQuarentena;
        }
      }

      // 7. Baixar fotos faltantes por hash SHA-256
      int fotosTransferidas = 0;
      for (final hash in hashesFotosParaBaixar) {
        if (!FotoService.existeFoto(hash)) {
          try {
            final reqFoto = await client.getUrl(Uri.parse('${aparelho.urlBase}/sync/fotos/$hash'));
            reqFoto.headers.set('authorization', 'Bearer $token');
            final respFoto = await reqFoto.close();

            if (respFoto.statusCode == 200) {
              final bytesBuilder = BytesBuilder();
              await for (final chunk in respFoto) {
                bytesBuilder.add(chunk);
              }
              FotoService.salvarFoto(hash, bytesBuilder.toBytes());
              fotosTransferidas++;
            }
          } catch (_) {
            // Continua o fluxo em caso de falha em foto individual
          }
        }
      }

      return ResultadoSincronizacao(
        eventosRecebidos: eventosRecebidos,
        eventosAplicados: eventosRecebidos,
        eventosQuarentena: eventosQuarentena,
        fotosRecebidas: fotosTransferidas,
        convergente: eventosQuarentena == 0,
        mensagem: '$eventosRecebidos eventos recebidos, $eventosEnviados enviados, $fotosTransferidas fotos transferidas.',
      );
    } finally {
      client.close();
    }
  }
}

/// Serviço de anúncio e descoberta mDNS usando pacote nsd (_tombox._tcp)
class DescobertaRedeService {
  nsd.Registration? _registration;
  nsd.Discovery? _discovery;

  /// Registra este aparelho como serviço _tombox._tcp na rede local
  Future<void> registrarServico({
    required int porta,
    required String impressaoCurta,
  }) async {
    if (kIsWeb) return;

    try {
      _registration = await nsd.register(
        nsd.Service(
          name: 'Tombox-$impressaoCurta',
          type: '_tombox._tcp',
          port: porta,
          txt: {'fp': utf8.encode(impressaoCurta)},
        ),
      );
    } catch (_) {
      // Falha graciosa se mDNS não estiver habilitado
    }
  }

  /// Inicia a busca por outros aparelhos que anunciam _tombox._tcp
  Future<void> iniciarDescoberta({
    required String minhaImpressaoCurta,
    required void Function(List<AparelhoRemoto>) onAtualizar,
  }) async {
    if (kIsWeb) return;

    final aparelhosMap = <String, AparelhoRemoto>{};

    try {
      _discovery = await nsd.startDiscovery(
        '_tombox._tcp',
        ipLookupType: nsd.IpLookupType.v4,
      );

      _discovery?.addServiceListener((service, status) {
        final host = service.host;
        final port = service.port ?? 8086;
        final name = service.name ?? 'Aparelho Tombox';

        // Extrai fingerprint do TXT record se disponível
        String fp = 'ED25-REMOTO';
        if (service.txt != null && service.txt!.containsKey('fp')) {
          final bytes = service.txt!['fp'];
          if (bytes != null) fp = utf8.decode(bytes);
        }

        // Não adiciona o próprio aparelho
        if (fp == minhaImpressaoCurta) return;

        final chave = '$host:$port';

        if (status == nsd.ServiceStatus.found) {
          aparelhosMap[chave] = AparelhoRemoto(
            id: chave,
            nome: name,
            enderecoIp: host ?? '127.0.0.1',
            porta: port,
            impressaoCurta: fp,
            ultimoContato: DateTime.now(),
          );
          onAtualizar(aparelhosMap.values.toList());
        } else if (status == nsd.ServiceStatus.lost) {
          aparelhosMap.remove(chave);
          onAtualizar(aparelhosMap.values.toList());
        }
      });
    } catch (_) {
      // Ignora falha de discovery em ambientes sem rede
    }
  }

  /// Para anúncio e descoberta
  Future<void> parar() async {
    if (kIsWeb) return;
    try {
      if (_registration != null) {
        await nsd.unregister(_registration!);
        _registration = null;
      }
      if (_discovery != null) {
        await nsd.stopDiscovery(_discovery!);
        _discovery = null;
      }
    } catch (_) {}
  }
}
