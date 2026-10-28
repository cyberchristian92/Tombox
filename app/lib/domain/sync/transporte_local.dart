import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import '../../data/local/app_database.dart';
import '../eventos/evento_v2.dart';
import '../fotos/foto_service.dart';
import '../identidade/identidade_service.dart';
import 'sync_engine.dart';

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

/// Servidor HTTP leve (Shelf) embutido no app para troca de eventos
class ServidorSincronizacaoLocal {
  final AppDatabase db;
  final int porta;
  HttpServer? _server;

  ServidorSincronizacaoLocal({required this.db, this.porta = 8086});

  bool get estaRodando => _server != null;

  /// Inicia o servidor HTTP de sincronização
  Future<void> iniciar() async {
    if (_server != null) return;

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(_processarRequisicao);

    try {
      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, porta);
    } catch (_) {
      // Pode falhar na web ou se porta estiver ocupada; fallback suave
    }
  }

  /// Processa requisições HTTP REST de sincronização
  Future<Response> _processarRequisicao(Request request) async {
    final path = request.url.path;

    // 1. Descoberta e Ping
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

    // 2. Resumo de sequências (Vector Clock)
    if (path == 'sync/resumo' && request.method == 'GET') {
      final resumo = await SyncEngine.calcularResumo(db);
      return Response.ok(
        resumo.toJson(),
        headers: {'content-type': 'application/json'},
      );
    }

    // 3. Recebimento de eventos novos
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

    // 4. Download de foto por hash
    if (path.startsWith('sync/fotos/')) {
      final hash = path.replaceFirst('sync/fotos/', '');
      final bytes = FotoService.obterFoto(hash);
      if (bytes != null) {
        return Response.ok(bytes, headers: {'content-type': 'image/jpeg'});
      }
      return Response.notFound('Foto não encontrada');
    }

    return Response.notFound('Rota de sincronização desconhecida');
  }

  /// Encerra o servidor
  Future<void> parar() async {
    await _server?.close(force: true);
    _server = null;
  }
}
