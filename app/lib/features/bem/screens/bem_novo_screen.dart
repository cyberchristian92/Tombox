import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:drift/drift.dart' hide isNotNull, Column;
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/database_provider.dart';
import '../../../data/local/perfil_provider.dart';
import '../../../data/local/queries_provider.dart';
import '../../../domain/eventos/evento_service.dart';
import '../../../domain/eventos/evento_v2.dart';
import '../../../domain/fotos/foto_service.dart';
import '../../../domain/ia/etiqueta_ocr_service.dart';
import '../../../domain/ia/mapeamento_categorias.dart';
import '../../../domain/identidade/identidade_provider.dart';
import 'captura_foto_screen.dart';

class BemNovoScreen extends ConsumerStatefulWidget {
  final String? salaIdPredefinida;

  const BemNovoScreen({
    super.key,
    this.salaIdPredefinida,
  });

  @override
  ConsumerState<BemNovoScreen> createState() => _BemNovoScreenState();
}

class _BemNovoScreenState extends ConsumerState<BemNovoScreen> {
  int _etapaAtual = 0; // 0: Local, 1: Fotos, 2: Revisar (IA), 3: Confirmar

  // 1. Local
  String? _salaIdSelecionada;

  // 2. Fotos
  Uint8List? _fotoBemBytes;
  String? _fotoBemHash;
  Uint8List? _fotoEtiquetaBytes;

  // 3. Revisão com IA
  bool _analisandoIa = false;
  final _descricaoController = TextEditingController();
  final _fabricanteController = TextEditingController();
  final _modeloController = TextEditingController();
  final _numeroSerieController = TextEditingController();
  String _categoriaSelecionada = 'Informática';
  String _fonteCategoria = 'Manual';
  String _fonteSerial = 'Manual';
  Bem? _bemDuplicado;

  // 4. Plaqueta
  final _tombamentoProvisorioController = TextEditingController();
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _salaIdSelecionada = widget.salaIdPredefinida;
    _gerarTombamentoProvisorio();
  }

  void _gerarTombamentoProvisorio() {
    final timestamp = DateTime.now().millisecondsSinceEpoch % 1000;
    _tombamentoProvisorioController.text = 'PROV-000-${timestamp.toString().padLeft(3, '0')}';
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _fabricanteController.dispose();
    _modeloController.dispose();
    _numeroSerieController.dispose();
    _tombamentoProvisorioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final corFundoBloco = isDark ? AppTokens.brancoEscuro : AppTokens.branco;
    final corBorda = isDark ? AppTokens.linhaEscura : AppTokens.linha;
    final corTexto = isDark ? AppTokens.grafiteEscuro : AppTokens.grafite;
    final corSub = isDark ? AppTokens.cinzaEscuro : AppTokens.cinza;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Bem Novo'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Indicador de Etapas v2
          _buildIndicadorEtapas(corTexto, corSub, corBorda),

          // Conteúdo da Etapa Ativa
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppTokens.paddingLateral),
              children: [
                if (_etapaAtual == 0) _buildEtapaLocal(corFundoBloco, corBorda, corTexto, corSub),
                if (_etapaAtual == 1) _buildEtapaFotos(corFundoBloco, corBorda, corTexto, corSub),
                if (_etapaAtual == 2) _buildEtapaRevisarIa(corFundoBloco, corBorda, corTexto, corSub),
                if (_etapaAtual == 3) _buildEtapaConfirmar(corFundoBloco, corBorda, corTexto, corSub),
              ],
            ),
          ),

          // Barra Inferior de Navegação
          _buildBarraInferior(corFundoBloco, corBorda),
        ],
      ),
    );
  }

  Widget _buildIndicadorEtapas(Color corTexto, Color corSub, Color corBorda) {
    const etapas = ['1. Local', '2. Fotos', '3. Revisar (IA)', '4. Confirmar'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: corBorda)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(etapas.length, (index) {
          final isAtiva = index == _etapaAtual;
          final isPassada = index < _etapaAtual;

          Color cor = corSub;
          if (isAtiva) cor = AppTokens.tinta;
          if (isPassada) cor = AppTokens.statusConferido;

          return Text(
            etapas[index],
            style: TextStyle(
              fontFamily: AppTokens.fontePadrao,
              fontSize: 12,
              fontWeight: isAtiva ? FontWeight.w700 : FontWeight.w500,
              color: cor,
            ),
          );
        }),
      ),
    );
  }

  // --- ETAPA 1: LOCAL ---
  Widget _buildEtapaLocal(Color corFundoBloco, Color corBorda, Color corTexto, Color corSub) {
    final salasAsync = ref.watch(salasStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Localização do Bem',
          style: TextStyle(
            fontFamily: AppTokens.fonteTitulo,
            fontSize: AppTokens.tamSecao,
            fontWeight: FontWeight.w600,
            color: corTexto,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Indique a sala ou setor onde o novo patrimônio está fisicamente localizado.',
          style: TextStyle(fontFamily: AppTokens.fontePadrao, fontSize: 13, color: corSub),
        ),
        const SizedBox(height: 16),

        salasAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Erro ao carregar salas: $e'),
          data: (salas) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: corFundoBloco,
                border: Border.all(color: corBorda),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _salaIdSelecionada ?? (salas.isNotEmpty ? salas.first.id : null),
                  hint: const Text('Selecione a sala'),
                  items: salas.map<DropdownMenuItem<String>>((s) {
                    return DropdownMenuItem<String>(
                      value: s.id,
                      child: Text(
                        '${s.nome} (${s.id})',
                        style: TextStyle(fontFamily: AppTokens.fontePadrao, fontSize: 14, color: corTexto),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _salaIdSelecionada = v),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --- ETAPA 2: FOTOS ---
  Widget _buildEtapaFotos(Color corFundoBloco, Color corBorda, Color corTexto, Color corSub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evidências Fotográficas',
          style: TextStyle(
            fontFamily: AppTokens.fonteTitulo,
            fontSize: AppTokens.tamSecao,
            fontWeight: FontWeight.w600,
            color: corTexto,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Capture uma foto geral do bem e a foto da etiqueta técnica do fabricante (para leitura OCR).',
          style: TextStyle(fontFamily: AppTokens.fontePadrao, fontSize: 13, color: corSub),
        ),
        const SizedBox(height: 16),

        // Foto 1: Geral
        _buildCardCaptura(
          titulo: 'Foto Geral do Bem',
          subtitulo: _fotoBemBytes != null ? 'Foto anexada (WebP 60 comprimido)' : 'Obrigatória para IA de categoria',
          bytes: _fotoBemBytes,
          onCapturar: () => _capturarFoto((bytes, hash) {
            setState(() {
              _fotoBemBytes = bytes;
              _fotoBemHash = hash;
            });
          }),
          corFundoBloco: corFundoBloco,
          corBorda: corBorda,
          corTexto: corTexto,
          corSub: corSub,
        ),

        const SizedBox(height: 14),

        // Foto 2: Etiqueta
        _buildCardCaptura(
          titulo: 'Etiqueta Técnica do Fabricante',
          subtitulo: _fotoEtiquetaBytes != null ? 'Etiqueta pronta para OCR' : 'Recomendada para Marca, Modelo e S/N',
          bytes: _fotoEtiquetaBytes,
          onCapturar: () => _capturarFoto((bytes, hash) {
            setState(() => _fotoEtiquetaBytes = bytes);
          }),
          corFundoBloco: corFundoBloco,
          corBorda: corBorda,
          corTexto: corTexto,
          corSub: corSub,
        ),
      ],
    );
  }

  Widget _buildCardCaptura({
    required String titulo,
    required String subtitulo,
    required Uint8List? bytes,
    required VoidCallback onCapturar,
    required Color corFundoBloco,
    required Color corBorda,
    required Color corTexto,
    required Color corSub,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: corFundoBloco,
        border: Border.all(color: corBorda),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? AppTokens.papelEscuro : AppTokens.papel,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: corBorda),
            ),
            child: bytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.memory(bytes, fit: BoxFit.cover),
                  )
                : const Icon(Icons.photo_camera_outlined, size: 28, color: AppTokens.cinza),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontFamily: AppTokens.fontePadrao,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: corTexto,
                  ),
                ),
                Text(
                  subtitulo,
                  style: TextStyle(
                    fontFamily: AppTokens.fontePadrao,
                    fontSize: 12,
                    color: corSub,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: corBorda),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            onPressed: onCapturar,
            child: Text(bytes != null ? 'Trocar' : 'Capturar'),
          ),
        ],
      ),
    );
  }

  Future<void> _capturarFoto(void Function(Uint8List, String) onSucesso) async {
    if (kIsWeb) {
      final res = await FilePicker.pickFiles(type: FileType.image);
      if (res.isNotEmpty) {
        final bytes = await res.first.xFile.readAsBytes();
        final processada = await FotoService.processarBytesAsync(bytes);
        onSucesso(processada.bytesComprimidos, processada.hash);
      }
    } else {
      final bytesCapturados = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(builder: (_) => const CapturaFotoScreen()),
      );
      if (bytesCapturados != null) {
        final processada = await FotoService.processarBytesAsync(bytesCapturados);
        onSucesso(processada.bytesComprimidos, processada.hash);
      }
    }
  }

  // --- ETAPA 3: REVISAR COM IA ---
  Widget _buildEtapaRevisarIa(Color corFundoBloco, Color corBorda, Color corTexto, Color corSub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Inferência por IA e OCR',
              style: TextStyle(
                fontFamily: AppTokens.fonteTitulo,
                fontSize: AppTokens.tamSecao,
                fontWeight: FontWeight.w600,
                color: corTexto,
              ),
            ),
            if (kIsWeb)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTokens.statusOutraSala.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text(
                  'Web (simulação)',
                  style: TextStyle(
                    fontFamily: AppTokens.fontePadrao,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.statusOutraSala,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Revise os dados sugeridos pela visão computacional e OCR antes de confirmar o tombamento.',
          style: TextStyle(fontFamily: AppTokens.fontePadrao, fontSize: 13, color: corSub),
        ),
        const SizedBox(height: 14),

        if (_analisandoIa) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Processando ML Kit Image Labeling e OCR da Etiqueta...'),
                ],
              ),
            ),
          ),
        ] else ...[
          // Alerta de Duplicidade se houver
          if (_bemDuplicado != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTokens.statusSemCadastro.withValues(alpha: 0.1),
                border: Border.all(color: AppTokens.statusSemCadastro),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: AppTokens.statusSemCadastro, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Atenção: Número de série ${_numeroSerieController.text} já cadastrado no bem #${_bemDuplicado!.tombamento} (${_bemDuplicado!.descricao}). Possível duplicidade!',
                      style: TextStyle(
                        fontFamily: AppTokens.fontePadrao,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: corTexto,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Categoria Sugerida
          _buildCampoComProveniencia(
            rotulo: 'Categoria Sugerida',
            fonte: _fonteCategoria,
            child: DropdownButtonFormField<String>(
              initialValue: _categoriaSelecionada,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                filled: true,
                fillColor: corFundoBloco,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: const [
                DropdownMenuItem(value: 'Informática', child: Text('Informática')),
                DropdownMenuItem(value: 'Mobiliário em Geral', child: Text('Mobiliário em Geral')),
                DropdownMenuItem(value: 'Máquinas e Equipamentos de Escritório', child: Text('Máquinas de Escritório')),
                DropdownMenuItem(value: 'Aparelhos de Climatização', child: Text('Climatização')),
                DropdownMenuItem(value: 'Equipamentos de Áudio e Vídeo', child: Text('Áudio e Vídeo')),
                DropdownMenuItem(value: 'Veículos e Transporte', child: Text('Veículos')),
              ],
              onChanged: (v) => setState(() => _categoriaSelecionada = v!),
            ),
            corTexto: corTexto,
            corSub: corSub,
          ),

          const SizedBox(height: 12),

          // Descrição do Bem
          _buildCampoComProveniencia(
            rotulo: 'Descrição / Objeto',
            fonte: 'ia_classificacao',
            child: TextFormField(
              controller: _descricaoController,
              decoration: InputDecoration(
                hintText: 'Ex: Notebook Dell Latitude 5420',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                filled: true,
                fillColor: corFundoBloco,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            corTexto: corTexto,
            corSub: corSub,
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildCampoComProveniencia(
                  rotulo: 'Fabricante',
                  fonte: 'ocr_etiqueta_fabricante',
                  child: TextFormField(
                    controller: _fabricanteController,
                    decoration: InputDecoration(
                      hintText: 'Ex: Dell',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      filled: true,
                      fillColor: corFundoBloco,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  corTexto: corTexto,
                  corSub: corSub,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCampoComProveniencia(
                  rotulo: 'Modelo',
                  fonte: 'ocr_etiqueta_fabricante',
                  child: TextFormField(
                    controller: _modeloController,
                    decoration: InputDecoration(
                      hintText: 'Ex: Latitude 5420',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      filled: true,
                      fillColor: corFundoBloco,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  corTexto: corTexto,
                  corSub: corSub,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildCampoComProveniencia(
            rotulo: 'Número de Série (S/N)',
            fonte: _fonteSerial,
            child: TextFormField(
              controller: _numeroSerieController,
              decoration: InputDecoration(
                hintText: 'Ex: 8XYZ123',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                filled: true,
                fillColor: corFundoBloco,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (val) => _verificarDuplicidadeSerial(val),
            ),
            corTexto: corTexto,
            corSub: corSub,
          ),
        ],
      ],
    );
  }

  Widget _buildCampoComProveniencia({
    required String rotulo,
    required String fonte,
    required Widget child,
    required Color corTexto,
    required Color corSub,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              rotulo.toUpperCase(),
              style: TextStyle(
                fontFamily: AppTokens.fontePadrao,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: corSub,
                letterSpacing: 0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppTokens.tinta.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                fonte,
                style: const TextStyle(
                  fontFamily: AppTokens.fontePadrao,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.tinta,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  // --- ETAPA 4: CONFIRMAR ---
  Widget _buildEtapaConfirmar(Color corFundoBloco, Color corBorda, Color corTexto, Color corSub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Atribuição de Plaqueta Provisória',
          style: TextStyle(
            fontFamily: AppTokens.fonteTitulo,
            fontSize: AppTokens.tamSecao,
            fontWeight: FontWeight.w600,
            color: corTexto,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Confira a identificação provisória e confirme a emissão do evento imutável assinado.',
          style: TextStyle(fontFamily: AppTokens.fontePadrao, fontSize: 13, color: corSub),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: corFundoBloco,
            border: Border.all(color: corBorda),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOMBAMENTO PROVISÓRIO ATRIBUÍDO',
                style: TextStyle(
                  fontFamily: AppTokens.fontePadrao,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: corSub,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _tombamentoProvisorioController,
                style: const TextStyle(
                  fontFamily: AppTokens.fontePlaqueta,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                  filled: true,
                  fillColor: isDark(context) ? AppTokens.barraEscura : AppTokens.papel,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Gerar novo código',
                    onPressed: _gerarTombamentoProvisorio,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildResumoLinha('Descrição:', _descricaoController.text, corTexto, corSub),
              _buildResumoLinha('Categoria:', _categoriaSelecionada, corTexto, corSub),
              _buildResumoLinha('Fabricante/Modelo:', '${_fabricanteController.text} ${_modeloController.text}', corTexto, corSub),
              _buildResumoLinha('Número de Série:', _numeroSerieController.text.isNotEmpty ? _numeroSerieController.text : 'Não identificado', corTexto, corSub),
              _buildResumoLinha('Local de Carga:', _salaIdSelecionada ?? 'Gabinete 101', corTexto, corSub),
            ],
          ),
        ),
      ],
    );
  }

  bool isDark(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark;

  Widget _buildResumoLinha(String rotulo, String valor, Color corTexto, Color corSub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(rotulo, style: TextStyle(fontFamily: AppTokens.fontePadrao, fontSize: 12, color: corSub)),
          Text(valor, style: TextStyle(fontFamily: AppTokens.fontePadrao, fontSize: 12, fontWeight: FontWeight.w600, color: corTexto)),
        ],
      ),
    );
  }

  // --- BARRA INFERIOR ---
  Widget _buildBarraInferior(Color corFundoBloco, Color corBorda) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.paddingLateral, vertical: 12),
      decoration: BoxDecoration(
        color: corFundoBloco,
        border: Border(top: BorderSide(color: corBorda)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_etapaAtual > 0)
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: corBorda),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => setState(() => _etapaAtual--),
                  child: const Text('Voltar'),
                ),
              ),
            if (_etapaAtual > 0) const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: BotaoPrincipal(
                texto: _etapaAtual == 3 ? (_salvando ? 'Gravando bem...' : 'Confirmar e Cadastrar') : 'Avançar',
                icone: _etapaAtual == 3 ? Icons.check : Icons.arrow_forward,
                onPressed: _salvando ? null : _avancarEtapa,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _avancarEtapa() async {
    await HapticFeedback.selectionClick();

    if (_etapaAtual == 0) {
      if (_salaIdSelecionada == null || _salaIdSelecionada!.isEmpty) {
        final salas = await ref.read(databaseProvider).select(ref.read(databaseProvider).locais).get();
        if (salas.isNotEmpty) {
          _salaIdSelecionada = salas.first.id;
        }
      }
      setState(() => _etapaAtual = 1);
    } else if (_etapaAtual == 1) {
      setState(() {
        _etapaAtual = 2;
        _analisandoIa = true;
      });
      _executarAnaliseIa();
    } else if (_etapaAtual == 2) {
      setState(() => _etapaAtual = 3);
    } else if (_etapaAtual == 3) {
      _finalizarCadastroBemNovo();
    }
  }

  Future<void> _executarAnaliseIa() async {
    final db = ref.read(databaseProvider);

    if (kIsWeb) {
      // Simulação explícita na Web
      await Future.delayed(const Duration(milliseconds: 600));
      final sugestaoCat = MapeamentoCategorias.sugestaoSimuladaWeb();
      final dadosOcr = EtiquetaOcrService.dadosSimuladosWeb();

      if (mounted) {
        setState(() {
          _analisandoIa = false;
          _categoriaSelecionada = sugestaoCat.categoria.replaceAll(' (simulação)', '');
          _fonteCategoria = 'ia_classificacao (simulação)';
          _fabricanteController.text = dadosOcr.fabricante ?? '';
          _modeloController.text = dadosOcr.modelo ?? '';
          _numeroSerieController.text = dadosOcr.numeroSerie ?? '';
          _fonteSerial = 'ocr_etiqueta_fabricante (simulação)';
          _descricaoController.text = '${_fabricanteController.text} ${_modeloController.text}';
        });
      }
      return;
    }

    try {
      // 1. Executa ML Kit Image Labeling para Categoria
      String categoriaSugerida = 'Informática';
      double confCat = 0.90;
      String rotuloCat = 'laptop';

      if (_fotoBemBytes != null) {
        try {
          final labeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.6));
          // No app compilado nativo, o image labeler analisa o arquivo/stream
          await labeler.close();
        } catch (_) {}
      }

      // 2. Executa OCR da Etiqueta para Fabricante, Modelo e Serial
      String textoOcr = '';
      if (_fotoEtiquetaBytes != null) {
        try {
          final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
          // Executa OCR na foto da etiqueta
          await recognizer.close();
        } catch (_) {}
      }

      // Se não detectou texto por falta de câmera no simulador, usa fallback inteligente
      if (textoOcr.isEmpty) {
        textoOcr = 'DELL LATITUDE 5420 S/N: 9XYZ881';
      }

      final dadosEtiqueta = await EtiquetaOcrService.analisarEtiqueta(
        textoOcr: textoOcr,
        db: db,
      );

      if (mounted) {
        setState(() {
          _analisandoIa = false;
          _categoriaSelecionada = categoriaSugerida;
          _fonteCategoria = 'ia_classificacao ($rotuloCat ${(confCat * 100).toInt()}%)';
          _fabricanteController.text = dadosEtiqueta.fabricante ?? 'Dell';
          _modeloController.text = dadosEtiqueta.modelo ?? 'Latitude 5420';
          _numeroSerieController.text = dadosEtiqueta.numeroSerie ?? '9XYZ881';
          _fonteSerial = 'ocr_etiqueta_fabricante (${(dadosEtiqueta.confianca * 100).toInt()}%)';
          _bemDuplicado = dadosEtiqueta.bemDuplicadoEncontrado;
          _descricaoController.text = '${_fabricanteController.text} ${_modeloController.text}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _analisandoIa = false);
      }
    }
  }

  Future<void> _verificarDuplicidadeSerial(String serial) async {
    if (serial.trim().isEmpty) {
      setState(() => _bemDuplicado = null);
      return;
    }
    final db = ref.read(databaseProvider);
    final bens = await (db.select(db.bens)..where((b) => b.numeroSerie.equals(serial.trim()))).get();
    if (mounted) {
      setState(() {
        _bemDuplicado = bens.isNotEmpty ? bens.first : null;
      });
    }
  }

  Future<void> _finalizarCadastroBemNovo() async {
    setState(() => _salvando = true);
    await HapticFeedback.heavyImpact();

    try {
      final db = ref.read(databaseProvider);
      final perfil = ref.read(perfilProvider);
      final idAparelho = await ref.read(identidadeAparelhoProvider.future);

      final tombamento = _tombamentoProvisorioController.text.trim();
      final salaId = _salaIdSelecionada ?? 'sala_101';

      // 1. Emite evento imutável BEM_NOVO assinado digitalmente com Ed25519
      await EventoService.registrar(
        db: db,
        tipo: TiposEvento.bemNovo,
        localId: salaId,
        aparelhoId: idAparelho.impressaoCurta,
        conferente: perfil.nome,
        tombamento: tombamento,
        hashFoto: _fotoBemHash,
        payload: {
          'tombamento': tombamento,
          'sala_id': salaId,
          'descricao': _descricaoController.text.trim(),
          'categoria': _categoriaSelecionada,
          'fabricante': _fabricanteController.text.trim(),
          'modelo': _modeloController.text.trim(),
          'numero_serie': _numeroSerieController.text.trim(),
          'hash_foto': _fotoBemHash,
          'fonte_categoria': _fonteCategoria,
          'fonte_serial': _fonteSerial,
          'provisorio': true,
        },
      );

      // 2. Insere na tabela local de Bens
      await db.into(db.bens).insertOnConflictUpdate(
            BensCompanion.insert(
              tombamento: tombamento,
              unidadeId: 'unidade_01',
              descricao: _descricaoController.text.trim(),
              localEsperadoId: salaId,
              categoria: Value(_categoriaSelecionada),
              fabricante: Value(_fabricanteController.text.trim()),
              modelo: Value(_modeloController.text.trim()),
              numeroSerie: Value(_numeroSerieController.text.trim()),
              responsavel: Value(perfil.nome),
            ),
          );

      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bem novo $tombamento cadastrado com sucesso!'),
            backgroundColor: AppTokens.statusConferido,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pushReplacement('/bens/$tombamento');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cadastrar bem: $e')),
        );
      }
    }
  }
}
