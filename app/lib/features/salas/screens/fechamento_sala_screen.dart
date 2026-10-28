import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:signature/signature.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatador.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../data/local/database_provider.dart';
import '../../../data/local/perfil_provider.dart';
import '../../../domain/fechamento/fechamento_models.dart';
import '../../../domain/fechamento/fechamento_service.dart';
import '../../../domain/identidade/identidade_provider.dart';

class FechamentoSalaScreen extends ConsumerStatefulWidget {
  final String salaId;

  const FechamentoSalaScreen({
    super.key,
    required this.salaId,
  });

  @override
  ConsumerState<FechamentoSalaScreen> createState() => _FechamentoSalaScreenState();
}

class _FechamentoSalaScreenState extends ConsumerState<FechamentoSalaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController(text: 'Dra. Maria Helena Silva');
  final _matriculaController = TextEditingController(text: 'TJPA-8841');
  final _cargoController = TextEditingController(text: 'Diretora de Secretaria');

  late final SignatureController _sigController;
  bool _processando = false;
  ResumoFechamentoSala? _resumo;
  ResultadoFechamento? _resultado;

  @override
  void initState() {
    super.initState();
    _sigController = SignatureController(
      penStrokeWidth: 2.5,
      penColor: AppTokens.tinta,
      exportBackgroundColor: Colors.transparent,
    );
    _carregarResumo();
  }

  Future<void> _carregarResumo() async {
    final db = ref.read(databaseProvider);
    final r = await FechamentoService.obterResumoFechamento(db, widget.salaId);
    if (mounted) {
      setState(() => _resumo = r);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _matriculaController.dispose();
    _cargoController.dispose();
    _sigController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final corFundoBloco = isDark ? AppTokens.brancoEscuro : AppTokens.branco;
    final corBorda = isDark ? AppTokens.linhaEscura : AppTokens.linha;
    final corTexto = isDark ? AppTokens.grafiteEscuro : AppTokens.grafite;
    final corSub = isDark ? AppTokens.cinzaEscuro : AppTokens.cinza;

    if (_resultado != null) {
      return _buildTelaSucesso(isDark, corFundoBloco, corBorda, corTexto, corSub);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fechamento de Sala e Termo'),
        elevation: 0,
      ),
      body: _resumo == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppTokens.paddingLateral),
                children: [
                  // 1. Resumo da Sala
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: corFundoBloco,
                      border: Border.all(color: corBorda),
                      borderRadius: BorderRadius.circular(AppTokens.raioBloco),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _resumo!.salaNome,
                              style: TextStyle(
                                fontFamily: AppTokens.fonteTitulo,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: corTexto,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTokens.tinta.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                '${_resumo!.taxaConferencia.toStringAsFixed(0)}% conferido',
                                style: const TextStyle(
                                  fontFamily: AppTokens.fontePadrao,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTokens.tinta,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildMiniStat('Esperados', '${_resumo!.totalEsperados}', corTexto, corSub),
                            _buildMiniStat('Conferidos', '${_resumo!.totalConferidos}', AppTokens.statusConferido, corSub),
                            _buildMiniStat('Pendentes', '${_resumo!.totalNaoEncontrados}', AppTokens.statusSemCadastro, corSub),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Dados do Responsável
                  Text(
                    'Responsável pelo Local',
                    style: TextStyle(
                      fontFamily: AppTokens.fonteTitulo,
                      fontSize: AppTokens.tamSecao,
                      fontWeight: FontWeight.w600,
                      color: corTexto,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _nomeController,
                    decoration: InputDecoration(
                      labelText: 'Nome completo do responsável',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                      filled: true,
                      fillColor: corFundoBloco,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _matriculaController,
                          decoration: InputDecoration(
                            labelText: 'Matrícula TJPA',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                            filled: true,
                            fillColor: corFundoBloco,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe a matrícula' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _cargoController,
                          decoration: InputDecoration(
                            labelText: 'Cargo / Função',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                            filled: true,
                            fillColor: corFundoBloco,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 3. Canvas de Assinatura
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Assinatura no Aparelho',
                        style: TextStyle(
                          fontFamily: AppTokens.fonteTitulo,
                          fontSize: AppTokens.tamSecao,
                          fontWeight: FontWeight.w600,
                          color: corTexto,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Limpar'),
                        onPressed: () => _sigController.clear(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: isDark ? AppTokens.barraEscura : AppTokens.branco,
                      border: Border.all(color: corBorda, width: 1.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          Signature(
                            controller: _sigController,
                            backgroundColor: Colors.transparent,
                          ),
                          Positioned(
                            bottom: 8,
                            left: 12,
                            child: Text(
                              'Assine aqui com o dedo ou caneta stylus',
                              style: TextStyle(
                                fontFamily: AppTokens.fontePadrao,
                                fontSize: 11,
                                color: corSub.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. Botão de Finalização
                  BotaoPrincipal(
                    texto: _processando ? 'Gerando termo e assinando...' : 'Emitir Termo e Fechar Sala',
                    icone: Icons.assignment_turned_in_outlined,
                    onPressed: _processando ? null : _emitirTermo,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMiniStat(String rotulo, String valor, Color corValor, Color corSub) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 2),
          Text(
            valor,
            style: TextStyle(
              fontFamily: AppTokens.fontePlaqueta,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: corValor,
              fontFeatures: AppTokens.algarismosTabulares,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _emitirTermo() async {
    if (!_formKey.currentState!.validate()) return;

    if (_sigController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, colete a assinatura do responsável antes de fechar a sala.'),
          backgroundColor: AppTokens.statusSemCadastro,
        ),
      );
      return;
    }

    setState(() => _processando = true);
    await HapticFeedback.mediumImpact();

    try {
      final db = ref.read(databaseProvider);
      final perfil = ref.read(perfilProvider);
      final idAparelho = await ref.read(identidadeAparelhoProvider.future);

      final pngBytes = await _sigController.toPngBytes();

      final dados = DadosTermoResponsabilidade(
        resumo: _resumo!,
        responsavelNome: _nomeController.text.trim(),
        responsavelMatricula: _matriculaController.text.trim(),
        responsavelCargo: _cargoController.text.trim(),
        conferenteNome: perfil.nome,
        conferenteMatricula: perfil.matricula,
        chaveConferente: idAparelho.impressaoCurta,
        dataHora: DateTime.now(),
        assinaturaBytes: pngBytes ?? Uint8List(0),
      );

      final resultado = await FechamentoService.fecharSalaComTermo(
        db: db,
        dados: dados,
        autorPublicKey: idAparelho.publicKeyHex,
        aparelhoId: idAparelho.impressaoCurta,
      );

      if (mounted) {
        setState(() {
          _processando = false;
          _resultado = resultado;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao emitir termo: $e'),
            backgroundColor: AppTokens.statusSemCadastro,
          ),
        );
      }
    }
  }

  Widget _buildTelaSucesso(
    bool isDark,
    Color corFundoBloco,
    Color corBorda,
    Color corTexto,
    Color corSub,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sala Fechada com Sucesso'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.paddingLateral),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTokens.statusConferido.withValues(alpha: 0.1),
              border: Border.all(color: AppTokens.statusConferido),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified, color: AppTokens.statusConferido, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Termo de Responsabilidade Emitido',
                      style: TextStyle(
                        fontFamily: AppTokens.fonteTitulo,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTokens.statusConferido,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'A sala foi fechada e o Termo de Responsabilidade em PDF foi registrado na cadeia de eventos imutáveis com assinatura Ed25519.',
                  style: TextStyle(
                    fontFamily: AppTokens.fontePadrao,
                    fontSize: 13,
                    color: corTexto,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Hash SHA-256 do Documento PDF:',
                  style: TextStyle(
                    fontFamily: AppTokens.fontePadrao,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: corSub,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  _resultado!.pdfHash,
                  style: const TextStyle(
                    fontFamily: AppTokens.fontePlaqueta,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Data de Registro: ${Formatador.dataHora(_resultado!.dataHora)}',
                  style: TextStyle(
                    fontFamily: AppTokens.fontePadrao,
                    fontSize: 12,
                    color: corSub,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          BotaoPrincipal(
            texto: 'Voltar para Locais',
            icone: Icons.check,
            onPressed: () => context.go('/locais'),
          ),
        ],
      ),
    );
  }
}
