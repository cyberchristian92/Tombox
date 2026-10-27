import 'dart:async';
import 'package:camera/camera.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/database_provider.dart';
import '../../../domain/casamento/casamento_models.dart';
import '../../../domain/casamento/casamento_motor.dart';
import '../../../domain/casamento/estabilidade_filtro.dart';
import '../../../domain/eventos/evento_service.dart';
import '../pipeline/camera_pipeline.dart';
import '../widgets/camera_overlay_painter.dart';

class ConferenciaScreen extends ConsumerStatefulWidget {
  final String salaId;

  const ConferenciaScreen({
    super.key,
    required this.salaId,
  });

  @override
  ConsumerState<ConferenciaScreen> createState() => _ConferenciaScreenState();
}

class _ConferenciaScreenState extends ConsumerState<ConferenciaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  CameraController? _cameraController;
  CameraPipeline? _pipeline;
  StreamSubscription<DeteccaoSessao>? _deteccaoSubscription;

  List<CaixaVisivel> _caixasVisiveis = [];
  ResultadoCasamento? _leituraProvavel;

  bool _cameraIniciada = false;
  bool _lanternaAtiva = false;
  bool _modoUmaPlaqueta = false;

  final Set<String> _tombamentosLidos = {};
  final Set<String> _tombamentosOutraSala = {};

  List<Bem> _bensEsperados = [];
  List<Bem> _todosBensUnidade = [];
  Local? _dadosSala;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _carregarDadosSala();
  }

  Future<void> _carregarDadosSala() async {
    final db = ref.read(databaseProvider);

    // Carrega dados da sala
    _dadosSala = await (db.select(db.locais)
          ..where((l) => l.id.equals(widget.salaId)))
        .getSingleOrNull();

    // Carrega todos os bens da unidade e os esperados para a sala
    _todosBensUnidade = await db.select(db.bens).get();
    _bensEsperados = _todosBensUnidade
        .where((b) => b.localEsperadoId == widget.salaId)
        .toList();

    // Carrega leituras prévias desta sala
    final eventosSala = await (db.select(db.eventos)
          ..where((e) => e.localId.equals(widget.salaId)))
        .get();

    for (final evt in eventosSala) {
      if (evt.tombamento != null) {
        if (_bensEsperados.any((b) => b.tombamento == evt.tombamento)) {
          _tombamentosLidos.add(evt.tombamento!);
        } else {
          _tombamentosOutraSala.add(evt.tombamento!);
        }
      }
    }

    if (mounted) {
      setState(() {});
      _inicializarPipelineECamera();
    }
  }

  Future<void> _inicializarPipelineECamera() async {
    final bensSalaSet = _bensEsperados.map((b) => b.tombamento).toSet();
    final todosBensSet = _todosBensUnidade.map((b) => b.tombamento).toSet();

    final motor = CasamentoMotor(
      bensSala: bensSalaSet,
      todosBensUnidade: todosBensSet,
    );

    final estabilidade = EstabilidadeFiltro();
    // Marca bens já lidos no cache para não re-vibrar
    for (final lido in _tombamentosLidos) {
      estabilidade.marcarConfirmado(lido);
    }
    for (final outra in _tombamentosOutraSala) {
      estabilidade.marcarConfirmado(outra);
    }

    _pipeline = CameraPipeline(
      motor: motor,
      estabilidade: estabilidade,
      onConfirmado: _processarConfirmacao,
    );

    _deteccaoSubscription = _pipeline!.stream.listen((sessao) {
      if (mounted) {
        setState(() {
          _caixasVisiveis = sessao.caixasVisiveis;
          _leituraProvavel = sessao.leituraProvavel;
        });
      }
    });

    // Inicialização da Câmera física com fallback defensivo
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty && mounted) {
        final cameraTraseira = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );

        _cameraController = CameraController(
          cameraTraseira,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.nv21,
        );

        await _cameraController!.initialize();

        if (mounted) {
          setState(() {
            _cameraIniciada = true;
          });

          await _cameraController!.startImageStream((image) {
            _pipeline?.processarQuadro(
              cameraImage: image,
              camera: cameraTraseira,
            );
          });
        }
      }
    } catch (_) {
      // Ambiente sem câmera (emulador, desktop ou teste de widget) - continua com UI mockada
    }
  }

  Future<void> _processarConfirmacao(
    String tombamento,
    String formaLeitura,
    bool daSala,
  ) async {
    final db = ref.read(databaseProvider);

    await EventoService.registrar(
      db: db,
      tipo: formaLeitura == 'manual'
          ? 'LEITURA_MANUAL'
          : (formaLeitura == 'codigo' ? 'CONFIRMACAO' : 'LEITURA'),
      localId: widget.salaId,
      aparelhoId: 'aparelho-local-01',
      conferente: 'Rosilene Silva',
      tombamento: tombamento,
      payload: {
        'formaLeitura': formaLeitura,
        'pertenceSala': daSala,
      },
    );

    if (mounted) {
      setState(() {
        if (daSala) {
          _tombamentosLidos.add(tombamento);
        } else {
          _tombamentosOutraSala.add(tombamento);
        }
        _leituraProvavel = null;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _deteccaoSubscription?.cancel();
    _pipeline?.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalEsperados = _bensEsperados.length;
    final totalLidos = _tombamentosLidos.length;

    final bensFaltando = _bensEsperados
        .where((b) => !_tombamentosLidos.contains(b.tombamento))
        .toList();

    final bensLidosLista = _bensEsperados
        .where((b) => _tombamentosLidos.contains(b.tombamento))
        .toList();

    final nomeExibicaoSala = _dadosSala?.nome ?? 'Sala ${widget.salaId}';

    return AppScaffold(
      title: 'Conferência - $nomeExibicaoSala',
      actions: [
        IconButton(
          icon: Icon(_lanternaAtiva ? Icons.flash_on : Icons.flash_off),
          tooltip: 'Lanterna',
          onPressed: () async {
            if (_cameraController != null && _cameraIniciada) {
              setState(() => _lanternaAtiva = !_lanternaAtiva);
              await _cameraController!.setFlashMode(
                _lanternaAtiva ? FlashMode.torch : FlashMode.off,
              );
            } else {
              setState(() => _lanternaAtiva = !_lanternaAtiva);
            }
          },
        ),
        IconButton(
          icon: Icon(_modoUmaPlaqueta
              ? Icons.filter_center_focus
              : Icons.center_focus_weak),
          tooltip: 'Modo Uma Plaqueta',
          onPressed: () async {
            setState(() => _modoUmaPlaqueta = !_modoUmaPlaqueta);
            if (_cameraController != null && _cameraIniciada) {
              await _cameraController!.setZoomLevel(_modoUmaPlaqueta ? 2.0 : 1.0);
            }
          },
        ),
      ],
      body: Column(
        children: [
          // Contador de progresso superior
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: theme.colorScheme.primaryContainer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$totalLidos de $totalEsperados bens conferidos',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(48, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Fechar Sala'),
                  onPressed: () => _confirmarFechamento(context),
                ),
              ],
            ),
          ),

          // Área da Câmera em Tela Cheia com Sobreposição de Caixas
          Expanded(
            flex: 5,
            child: Container(
              color: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_cameraIniciada && _cameraController != null)
                    CameraPreview(_cameraController!)
                  else
                    _buildFallbackCameraView(theme),

                  // CustomPainter desenha caixas verdes, amarelas e vermelhas
                  CustomPaint(
                    painter: CameraOverlayPainter(
                      caixas: _caixasVisiveis,
                      cameraImageSize: _cameraController?.value.previewSize ??
                          const Size(640, 480),
                    ),
                  ),

                  // Chip de leitura provável (Toque para confirmar)
                  if (_leituraProvavel != null)
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ActionChip(
                          avatar: const Icon(
                            Icons.touch_app,
                            size: 18,
                            color: Colors.black,
                          ),
                          backgroundColor: Colors.amberAccent,
                          label: Text(
                            '${_leituraProvavel!.tombamentoIdentificado}? Toque para confirmar leitura provável',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          onPressed: () {
                            if (_pipeline != null && _leituraProvavel != null) {
                              _pipeline!.confirmarProvavelManual(_leituraProvavel!);
                            }
                          },
                        ),
                      ),
                    ),

                  // Botão de busca manual no canto inferior direito
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: FloatingActionButton.small(
                      heroTag: 'manual_search_fab',
                      tooltip: 'Busca Manual',
                      child: const Icon(Icons.search),
                      onPressed: () => _abrirBuscaManual(context),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Abas inferiores (Lidos, Faltando, Outra Sala)
          Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              indicatorColor: theme.colorScheme.primary,
              tabs: [
                Tab(text: 'Lidos ($totalLidos)'),
                Tab(text: 'Faltando (${bensFaltando.length})'),
                Tab(text: 'Outra Sala (${_tombamentosOutraSala.length})'),
              ],
            ),
          ),

          // Conteúdo das Abas
          Expanded(
            flex: 4,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildListaBens(context, bensLidosLista, Colors.green),
                _buildListaBens(context, bensFaltando, Colors.red),
                _buildListaOutraSala(context, Colors.amber),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackCameraView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 64,
            color: Colors.white.withAlpha(120),
          ),
          const SizedBox(height: 8),
          Text(
            'Visor da Câmera Ativo',
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'OCR & Códigos de Barra operando a cada 200 ms',
            style: TextStyle(
              color: Colors.white.withAlpha(140),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          // Botão simulador para testes rápidos em desktop/ambiente de desenvolvimento
          ElevatedButton.icon(
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Simular Leitura de Plaqueta'),
            onPressed: () {
              if (_bensEsperados.isNotEmpty) {
                final primeiroNaoLido = _bensEsperados.firstWhere(
                  (b) => !_tombamentosLidos.contains(b.tombamento),
                  orElse: () => _bensEsperados.first,
                );
                _processarConfirmacao(primeiroNaoLido.tombamento, 'simulado', true);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListaBens(BuildContext context, List<Bem> lista, Color cor) {
    if (lista.isEmpty) {
      return const Center(
        child: Text('Nenhum bem nesta lista.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final bem = lista[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: cor.withAlpha(40),
            child: Icon(Icons.inventory_2, color: cor, size: 20),
          ),
          title: Text('#${bem.tombamento} • ${bem.descricao}'),
          subtitle: Text(bem.categoria ?? 'Sem categoria'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/bem/${bem.tombamento}'),
        );
      },
    );
  }

  Widget _buildListaOutraSala(BuildContext context, Color cor) {
    if (_tombamentosOutraSala.isEmpty) {
      return const Center(
        child: Text('Nenhum bem de outra sala localizado aqui.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _tombamentosOutraSala.length,
      itemBuilder: (context, index) {
        final tomb = _tombamentosOutraSala.elementAt(index);
        final bem = _todosBensUnidade.firstWhere(
          (b) => b.tombamento == tomb,
          orElse: () => Bem(
            tombamento: tomb,
            unidadeId: '',
            descricao: 'Bem da unidade (sala divergente)',
            localEsperadoId: '',
          ),
        );

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: cor.withAlpha(40),
            child: Icon(Icons.warning_amber, color: cor, size: 20),
          ),
          title: Text('#$tomb • ${bem.descricao}'),
          subtitle: const Text('Pertence a outra sala desta unidade'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/bem/$tomb'),
        );
      },
    );
  }

  void _abrirBuscaManual(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Busca Manual de Plaqueta'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Número do Tombamento',
            hintText: 'Ex: 010001',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.text,
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('Confirmar'),
            onPressed: () {
              final digitado = controller.text.trim();
              if (digitado.isNotEmpty) {
                Navigator.of(ctx).pop();
                final daSala = _bensEsperados.any((b) => b.tombamento == digitado);
                _processarConfirmacao(digitado, 'manual', daSala);
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmarFechamento(BuildContext context) {
    final totalEsperados = _bensEsperados.length;
    final totalLidos = _tombamentosLidos.length;
    final pendentes = totalEsperados - totalLidos;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fechar Conferência da Sala?'),
        content: Text(
          '$totalLidos de $totalEsperados bens foram conferidos. Existem $pendentes bens não localizados nesta sala. Deseja fechar e exportar o resultado?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('Confirmar Fechamento'),
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await (db.update(db.conferenciaSalas)
                    ..where((c) => c.localId.equals(widget.salaId)))
                  .write(
                ConferenciaSalasCompanion(
                  status: const Value('fechada'),
                  fim: Value(DateTime.now()),
                ),
              );

              await EventoService.registrar(
                db: db,
                tipo: 'FECHAMENTO_SALA',
                localId: widget.salaId,
                aparelhoId: 'aparelho-local-01',
                conferente: 'Rosilene Silva',
                payload: {
                  'totalLidos': totalLidos,
                  'totalEsperados': totalEsperados,
                  'pendentes': pendentes,
                },
              );

              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                context.push('/exportacao');
              }
            },
          ),
        ],
      ),
    );
  }
}
