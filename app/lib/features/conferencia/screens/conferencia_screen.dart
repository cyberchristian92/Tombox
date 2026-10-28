import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/barra_busca.dart';
import '../../../core/widgets/linha_bem.dart';
import '../../../core/widgets/chip_status.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/database_provider.dart';
import '../../../data/local/perfil_provider.dart';
import '../../../data/local/queries_provider.dart';
import '../../../domain/casamento/casamento_models.dart';
import '../../../domain/casamento/casamento_motor.dart';
import '../../../domain/casamento/estabilidade_filtro.dart';
import '../../../domain/eventos/evento_service.dart';
import '../../configuracoes/providers/diagnostico_provider.dart';
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
  late String _salaIdAtual;

  CameraController? _cameraController;
  CameraPipeline? _pipeline;
  StreamSubscription<DeteccaoSessao>? _deteccaoSubscription;

  List<CaixaVisivel> _caixasVisiveis = [];
  ResultadoCasamento? _leituraProvavel;
  List<TextoBrutoDeteccao> _textosBrutos = [];
  int _tempoProcessamentoMs = 0;
  double _fps = 0.0;
  int _sensorOrientation = 90;

  bool _cameraIniciada = false;
  bool _lanternaAtiva = false;
  bool _modoUmaPlaqueta = false;

  final Set<String> _tombamentosLidos = {};
  final Set<String> _tombamentosOutraSala = {};
  String? _ultimoLidoTombamento;
  String? _ultimoLidoDescricao;

  List<Bem> _bensEsperados = [];
  List<Bem> _todosBensUnidade = [];
  Local? _dadosSala;
  bool _motorIniciado = false;

  @override
  void initState() {
    super.initState();
    _salaIdAtual = widget.salaId;
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_salaIdAtual == 'sem_sala' || _salaIdAtual.isEmpty) {
        _mostrarModalEscolherSala();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _deteccaoSubscription?.cancel();
    _pipeline?.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  void _sincronizarMotor(DadosConferenciaSala dados) {
    _dadosSala = dados.sala;
    _bensEsperados = dados.bensEsperados;
    _todosBensUnidade = dados.todosBensUnidade;
    _tombamentosLidos.addAll(dados.tombamentosLidos);
    _tombamentosOutraSala.addAll(dados.tombamentosOutraSala);

    if (!_motorIniciado && !kIsWeb && _bensEsperados.isNotEmpty) {
      _motorIniciado = true;
      _inicializarPipelineECamera();
    }
  }

  Future<void> _inicializarPipelineECamera() async {
    if (kIsWeb) return;

    final bensSalaSet = _bensEsperados.map((b) => b.tombamento).toSet();
    final todosBensSet = _todosBensUnidade.map((b) => b.tombamento).toSet();

    final motor = CasamentoMotor(
      bensSala: bensSalaSet,
      todosBensUnidade: todosBensSet,
    );

    final estabilidade = EstabilidadeFiltro();
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
          _textosBrutos = sessao.textosBrutos;
          _tempoProcessamentoMs = sessao.tempoProcessamentoMs;
          _fps = sessao.fps;
        });
      }
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final traseira = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );

        _sensorOrientation = traseira.sensorOrientation;

        _cameraController = CameraController(
          traseira,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.nv21,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _cameraIniciada = true);
          await _cameraController!.startImageStream((cameraImage) {
            _pipeline?.processarQuadro(
              cameraImage: cameraImage,
              camera: traseira,
            );
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _cameraIniciada = false);
      }
    }
  }

  Future<void> _processarConfirmacao(
    String tombamento,
    String origem,
    bool pertenceASala,
  ) async {
    final db = ref.read(databaseProvider);

    final bemEncontrado = _todosBensUnidade.firstWhere(
      (b) => b.tombamento == tombamento,
      orElse: () => Bem(
        tombamento: tombamento,
        unidadeId: _dadosSala?.unidadeId ?? '',
        descricao: 'Bem lido em campo',
        localEsperadoId: _salaIdAtual,
      ),
    );

    setState(() {
      if (pertenceASala) {
        _tombamentosLidos.add(tombamento);
      } else {
        _tombamentosOutraSala.add(tombamento);
      }
      _ultimoLidoTombamento = tombamento;
      _ultimoLidoDescricao = bemEncontrado.descricao;
      _leituraProvavel = null;
    });

    final perfil = ref.read(perfilProvider);
    final conferenteStr = perfil.configurado
        ? '${perfil.nome} (${perfil.matricula})'
        : 'Conferente Local';

    // Registra evento no banco com hash encadeado
    await EventoService.registrar(
      db: db,
      tipo: 'CONFIRMACAO',
      localId: _salaIdAtual,
      aparelhoId: perfil.aparelhoId,
      conferente: conferenteStr,
      tombamento: tombamento,
      payload: {
        'origem': origem,
        'pertence_a_sala': pertenceASala,
        'descricao': bemEncontrado.descricao,
      },
    );

    // Toast de confirmação visual rápido
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          backgroundColor: pertenceASala ? AppTokens.statusEncontrado : AppTokens.statusOutraSala,
          content: Row(
            children: [
              Icon(
                pertenceASala ? Icons.check_circle : Icons.swap_horiz,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$tombamento · ${bemEncontrado.descricao}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dadosAsync = ref.watch(dadosConferenciaSalaProvider(_salaIdAtual));

    return Scaffold(
      backgroundColor: Colors.black,
      body: dadosAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                Text('Erro ao carregar conferência: $e',
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Voltar'),
                ),
              ],
            ),
          ),
        ),
        data: (dados) {
          _sincronizarMotor(dados);

          final totalEsperados = dados.bensEsperados.length;
          final totalLidos = _tombamentosLidos.length;
          final totalOutraSala = _tombamentosOutraSala.length;
          final totalPendentes = (totalEsperados - totalLidos).clamp(0, totalEsperados);
          final progresso = totalEsperados > 0 ? (totalLidos / totalEsperados).clamp(0.0, 1.0) : 0.0;

          final bensFaltando = dados.bensEsperados
              .where((b) => !_tombamentosLidos.contains(b.tombamento))
              .toList();

          final bensLidosLista = dados.bensEsperados
              .where((b) => _tombamentosLidos.contains(b.tombamento))
              .toList();

          final bensOutraSalaLista = dados.todosBensUnidade
              .where((b) => _tombamentosOutraSala.contains(b.tombamento))
              .toList();

          final modoDiagnostico = ref.watch(modoDiagnosticoProvider);

          return Stack(
            children: [
              // 1. Câmera ou Fallback Web em Tela Cheia
              Positioned.fill(
                child: _cameraIniciada && _cameraController != null && !kIsWeb
                    ? CameraPreview(_cameraController!)
                    : _buildFallbackCameraView(theme),
              ),

              // 2. Sobreposição de Caixas do OCR/Barcode (Mobile)
              if (_cameraIniciada && !kIsWeb)
                Positioned.fill(
                  child: CustomPaint(
                    painter: CameraOverlayPainter(
                      caixas: _caixasVisiveis,
                      cameraImageSize: _cameraController?.value.previewSize != null
                          ? Size(
                              _cameraController!.value.previewSize!.width,
                              _cameraController!.value.previewSize!.height,
                            )
                          : const Size(480, 640),
                      modoDiagnostico: modoDiagnostico,
                      textosBrutos: _textosBrutos,
                      tempoProcessamentoMs: _tempoProcessamentoMs,
                      fps: _fps,
                      sensorOrientation: _sensorOrientation,
                    ),
                  ),
                ),

              // 3. Topo Translúcido com Nome da Sala, Migalhas e Progresso
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(200),
                      borderRadius: BorderRadius.circular(AppTokens.raioBloco),
                      border: Border.all(color: Colors.white.withAlpha(40)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Linha 1: Voltar, Migalhas e Fechar Sala
                        Row(
                          children: [
                            InkWell(
                              onTap: () => context.pop(),
                              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dados.migalhas.isNotEmpty ? dados.migalhas : 'Unidade Ativa',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withAlpha(180),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => _mostrarModalEscolherSala(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(30),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.swap_horiz, size: 14, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text('Trocar', style: TextStyle(color: Colors.white, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTokens.statusEncontrado,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(40, 30),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () => _confirmarFechamento(context),
                              child: const Text('Fechar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Linha 2: Nome da sala em até duas linhas (nunca cortado)
                        Text(
                          dados.sala.nome,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Linha 3: Barra fina de progresso com "X de Y bens conferidos"
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$totalLidos de $totalEsperados bens conferidos',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${(progresso * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: AppTokens.statusEncontrado,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progresso,
                            minHeight: 5,
                            backgroundColor: Colors.white.withAlpha(40),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTokens.statusEncontrado),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Botões de Controle Flutuantes à Direita
              Positioned(
                right: 16,
                top: 150,
                child: Column(
                  children: [
                    _buildFloatingButton(
                      icone: _lanternaAtiva ? Icons.flash_on : Icons.flash_off,
                      ativo: _lanternaAtiva,
                      tooltip: 'Lanterna',
                      onPressed: () async {
                        setState(() => _lanternaAtiva = !_lanternaAtiva);
                        if (_cameraController != null && _cameraIniciada) {
                          await _cameraController!.setFlashMode(
                            _lanternaAtiva ? FlashMode.torch : FlashMode.off,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildFloatingButton(
                      icone: _modoUmaPlaqueta ? Icons.filter_center_focus : Icons.center_focus_weak,
                      ativo: _modoUmaPlaqueta,
                      tooltip: 'Modo Uma Plaqueta',
                      onPressed: () async {
                        setState(() => _modoUmaPlaqueta = !_modoUmaPlaqueta);
                        if (_cameraController != null && _cameraIniciada) {
                          await _cameraController!.setZoomLevel(_modoUmaPlaqueta ? 2.0 : 1.0);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildFloatingButton(
                      icone: Icons.search,
                      tooltip: 'Busca Manual',
                      onPressed: () => _abrirBuscaManual(context),
                    ),
                  ],
                ),
              ),

              // 5. Cartão Flutuante de Leitura Provável
              if (_leituraProvavel != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 120,
                  child: _buildCardLeituraProvavel(_leituraProvavel!),
                ),

              // 6. Folha Inferior Arrastável (Bottom Sheet) com Contadores e Abas
              DraggableScrollableSheet(
                initialChildSize: 0.16,
                minChildSize: 0.14,
                maxChildSize: 0.75,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTokens.raioFolha),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: theme.brightness == Brightness.dark
                              ? AppTokens.linhaEscura
                              : AppTokens.linha,
                          width: 1,
                        ),
                      ),
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.zero,
                      children: [
                        // Puxador central
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 8, bottom: 6),
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface.withAlpha(60),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // Cabeçalho Recolhido: Três contadores coloridos e último lido
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPillContador(
                                icone: AppTokens.iconeEncontrado,
                                cor: AppTokens.statusEncontrado,
                                count: totalLidos,
                                rotulo: 'Lidos',
                              ),
                              _buildPillContador(
                                icone: AppTokens.iconePendente,
                                cor: AppTokens.statusPendente,
                                count: totalPendentes,
                                rotulo: 'Faltando',
                              ),
                              _buildPillContador(
                                icone: AppTokens.iconeOutraSala,
                                cor: AppTokens.statusOutraSala,
                                count: totalOutraSala,
                                rotulo: 'Outra Sala',
                              ),
                            ],
                          ),
                        ),

                        if (_ultimoLidoTombamento != null) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
                            child: Row(
                              children: [
                                const Icon(Icons.check, size: 14, color: AppTokens.statusEncontrado),
                                const SizedBox(width: 6),
                                Text(
                                  'Último: ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface.withAlpha(140),
                                  ),
                                ),
                                Text(
                                  '$_ultimoLidoTombamento · ${_ultimoLidoDescricao ?? ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTokens.tombamentoPequeno.copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const Divider(height: 16),

                        // Abas quando expandida
                        TabBar(
                          controller: _tabController,
                          labelColor: theme.colorScheme.primary,
                          unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(140),
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          tabs: [
                            Tab(text: 'Lidos ($totalLidos)'),
                            Tab(text: 'Faltando ($totalPendentes)'),
                            Tab(text: 'Outra Sala ($totalOutraSala)'),
                          ],
                        ),

                        SizedBox(
                          height: 400,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildListaAba(bensLidosLista, StatusBem.encontrado, 'Nenhum bem lido ainda'),
                              _buildListaAba(bensFaltando, StatusBem.pendente, 'Todos os bens desta sala foram conferidos!'),
                              _buildListaAba(bensOutraSalaLista, StatusBem.outraSala, 'Nenhum bem de outra sala registrado'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icone,
    required VoidCallback onPressed,
    required String tooltip,
    bool ativo = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ativo ? Colors.white : Colors.black.withAlpha(180),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withAlpha(80)),
      ),
      child: IconButton(
        icon: Icon(icone, color: ativo ? Colors.black : Colors.white, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildPillContador({
    required IconData icone,
    required Color cor,
    required int count,
    required String rotulo,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cor.withAlpha(20),
        borderRadius: BorderRadius.circular(AppTokens.raioCarimbo),
        border: Border.all(color: cor.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 14, color: cor),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              color: cor,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            rotulo,
            style: TextStyle(
              color: cor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaAba(List<Bem> bens, StatusBem status, String msgVazia) {
    if (bens.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 40, color: Colors.grey.withAlpha(120)),
              const SizedBox(height: 8),
              Text(msgVazia, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final sit = status == StatusBem.encontrado
        ? SituacaoBem.conferido
        : (status == StatusBem.outraSala
            ? SituacaoBem.outraSala
            : SituacaoBem.pendente);

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: bens.length,
      itemBuilder: (context, idx) {
        final b = bens[idx];
        return LinhaBem(
          tombamento: b.tombamento,
          descricao: b.descricao,
          categoria: b.categoria,
          situacao: sit,
          onTap: () => context.push('/bens/${b.tombamento}'),
        );
      },
    );
  }

  Widget _buildCardLeituraProvavel(ResultadoCasamento resultado) {
    final tombamento = resultado.tombamentoIdentificado ?? resultado.textoNormalizado;
    final pertenceASala = resultado.classificacao == ClassificacaoPlaqueta.verde;
    final confianca = resultado.menorDistancia ?? 0.0;

    return Card(
      color: Colors.black.withAlpha(220),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.raioBloco),
        side: const BorderSide(color: AppTokens.statusOutraSala, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline, color: AppTokens.statusOutraSala, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Leitura Provável Detectada',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  'Distância: ${confianca.toStringAsFixed(1)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tombamento: $tombamento',
              style: AppTokens.tombamentoMedio.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white30),
                    ),
                    onPressed: () => setState(() => _leituraProvavel = null),
                    child: const Text('Não é'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTokens.statusEncontrado),
                    onPressed: () => _processarConfirmacao(
                      tombamento,
                      'provavel_confirmado',
                      pertenceASala,
                    ),
                    child: const Text('É este'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackCameraView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_off_outlined,
              size: 64,
              color: Colors.white.withAlpha(140),
            ),
            const SizedBox(height: 12),
            const Text(
              'Câmera disponível apenas no app Android',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Esta é uma prévia web visual para validação de design e navegação.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha(160),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
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
      ),
    );
  }

  void _mostrarModalEscolherSala() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.raioFolha)),
      ),
      builder: (ctx) {
        final salasAsync = ref.watch(salasStreamProvider);
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(AppTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Em qual sala você está?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: salasAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Erro: $e')),
                    data: (salas) {
                      return ListView.separated(
                        itemCount: salas.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final s = salas[idx];
                          return ListTile(
                            leading: const Icon(Icons.meeting_room_outlined),
                            title: Text(s.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${s.predioEAndar} · ${s.totalBens} bens'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pop(ctx);
                              setState(() {
                                _salaIdAtual = s.id;
                                _motorIniciado = false;
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _abrirBuscaManual(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.raioFolha)),
      ),
      builder: (ctx) {
        final controller = TextEditingController();
        String filtro = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bensFiltrados = _todosBensUnidade.where((b) {
              if (filtro.isEmpty) return true;
              final q = filtro.toLowerCase();
              return b.tombamento.toLowerCase().contains(q) ||
                  b.descricao.toLowerCase().contains(q);
            }).take(10).toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Busca Manual de Plaqueta',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  BarraBusca(
                    controller: controller,
                    hintText: 'Digite o tombamento ou descrição...',
                    onChanged: (val) => setModalState(() => filtro = val),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      itemCount: bensFiltrados.length,
                      itemBuilder: (context, idx) {
                        final b = bensFiltrados[idx];
                        final ehDestaSala = b.localEsperadoId == _salaIdAtual;
                        return ListTile(
                          title: Text(b.tombamento, style: AppTokens.tombamentoMedio),
                          subtitle: Text(b.descricao, maxLines: 1),
                          trailing: ElevatedButton(
                            child: const Text('Confirmar'),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _processarConfirmacao(b.tombamento, 'manual', ehDestaSala);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmarFechamento(BuildContext context) {
    final total = _bensEsperados.length;
    final lidos = _tombamentosLidos.length;
    final pendentes = total - lidos;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fechar Conferência da Sala?'),
        content: Text(
          'Resumo da conferência:\n\n'
          '• $lidos bens conferidos nesta sala\n'
          '• $pendentes bens pendentes\n'
          '• ${_tombamentosOutraSala.length} bens de outra sala registrados\n\n'
          'Deseja fechar esta sala agora?',
        ),
        actions: [
          TextButton(
            child: const Text('Continuar Conferindo'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            child: const Text('Confirmar e Fechar'),
            onPressed: () async {
              Navigator.pop(ctx);
              final db = ref.read(databaseProvider);
              await db.fecharSala(_salaIdAtual);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sala fechada com sucesso!'),
                    backgroundColor: AppTokens.statusEncontrado,
                  ),
                );
                context.pop();
              }
            },
          ),
        ],
      ),
    );
  }
}
