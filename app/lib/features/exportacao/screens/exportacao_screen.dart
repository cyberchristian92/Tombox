import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/database_provider.dart';
import '../../../data/local/queries_provider.dart';
import '../../../domain/exportacao/epcis_service.dart';
import '../../../domain/exportacao/exportacao_service.dart';
import '../../conferencia/widgets/leitor_externo_dialog.dart';

class ExportacaoScreen extends ConsumerStatefulWidget {
  const ExportacaoScreen({super.key});

  @override
  ConsumerState<ExportacaoScreen> createState() => _ExportacaoScreenState();
}

class _ExportacaoScreenState extends ConsumerState<ExportacaoScreen> {
  PerfilExportacao _perfilCsv = PerfilExportacao.themaGrp;
  bool _gerandoCsv = false;
  bool _gerandoPdf = false;
  bool _gerandoEpcis = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final db = ref.watch(databaseProvider);
    final estatisticasAsync = ref.watch(estatisticasUnidadeProvider);

    final corFundoBloco = isDark ? AppTokens.brancoEscuro : AppTokens.branco;
    final corBorda = isDark ? AppTokens.linhaEscura : AppTokens.linha;
    final corTexto = isDark ? AppTokens.grafiteEscuro : AppTokens.grafite;
    final corSub = isDark ? AppTokens.cinzaEscuro : AppTokens.cinza;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportação e Relatórios'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.paddingLateral),
        children: [
          // 1. Resumo da Unidade
          estatisticasAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Erro ao carregar totais: $e'),
            data: (stats) => Container(
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
                        'Conferência Patrimonial TJPA',
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
                          color: AppTokens.statusConferido.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          '${stats.percentualConferido.toStringAsFixed(1)}% cobertura',
                          style: const TextStyle(
                            fontFamily: AppTokens.fontePadrao,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTokens.statusConferido,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatItem('Total', '${stats.totalBens}', corTexto, corSub),
                      _buildStatItem('Conferidos', '${stats.totalConferidos}', AppTokens.statusConferido, corSub),
                      _buildStatItem('Salas Pend.', '${stats.salasPendentes}', AppTokens.statusSemCadastro, corSub),
                      _buildStatItem('Divergências', '${stats.divergenciasAbertas}', AppTokens.statusOutraSala, corSub),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 2. Seção de Exportação CSV
          Text(
            'Exportação em Planilha (CSV)',
            style: TextStyle(
              fontFamily: AppTokens.fonteTitulo,
              fontSize: AppTokens.tamSecao,
              fontWeight: FontWeight.w600,
              color: corTexto,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Arquivo tabular compatível com o Thema-GRP e sistemas de auditoria. Proteção contra injeção de fórmulas (CWE-1236) aplicada a todos os campos.',
            style: TextStyle(
              fontFamily: AppTokens.fontePadrao,
              fontSize: 13,
              color: corSub,
            ),
          ),
          const SizedBox(height: 12),

          Material(
            color: corFundoBloco,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: corBorda),
              borderRadius: BorderRadius.circular(AppTokens.raioBloco),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                  'Perfil de Colunas:',
                  style: TextStyle(
                    fontFamily: AppTokens.fontePadrao,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: corSub,
                  ),
                ),
                const SizedBox(height: 6),
                RadioGroup<PerfilExportacao>(
                  groupValue: _perfilCsv,
                  onChanged: (v) {
                    if (v != null) setState(() => _perfilCsv = v);
                  },
                  child: Column(
                    children: [
                      RadioListTile<PerfilExportacao>(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Thema-GRP Oficial (TJPA)',
                          style: TextStyle(fontFamily: AppTokens.fontePadrao, fontSize: 13, fontWeight: FontWeight.w500, color: corTexto),
                        ),
                        subtitle: Text(
                          'Colunas: Numero_Patrimonio, Descricao, Cod_Local, Nome_Local, Situacao_Inventario...',
                          style: TextStyle(fontFamily: AppTokens.fontePadrao, fontSize: 11, color: corSub),
                        ),
                        value: PerfilExportacao.themaGrp,
                      ),
                      RadioListTile<PerfilExportacao>(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Genérico / E-Auditoria Criptográfica',
                          style: TextStyle(fontFamily: AppTokens.fontePadrao, fontSize: 13, fontWeight: FontWeight.w500, color: corTexto),
                        ),
                        subtitle: Text(
                          'Inclui hash_evento, hash_foto, chave_conferente e assinaturas Ed25519',
                          style: TextStyle(fontFamily: AppTokens.fontePadrao, fontSize: 11, color: corSub),
                        ),
                        value: PerfilExportacao.genericoAuditoria,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                BotaoPrincipal(
                  texto: _gerandoCsv ? 'Gerando CSV...' : 'Exportar Arquivo CSV',
                  icone: Icons.table_view_outlined,
                  onPressed: _gerandoCsv ? null : () => _exportarCsv(db),
                ),
              ],
            ),
          ),
        ),

          const SizedBox(height: 20),

          // 3. Relatório Geral da Unidade em PDF
          Text(
            'Relatório Geral em PDF',
            style: TextStyle(
              fontFamily: AppTokens.fonteTitulo,
              fontSize: AppTokens.tamSecao,
              fontWeight: FontWeight.w600,
              color: corTexto,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Documento institucional A4 consolidado com resumo de salas, lista de termos homologados e verificação matemática de 100% das assinaturas da cadeia.',
            style: TextStyle(
              fontFamily: AppTokens.fontePadrao,
              fontSize: 13,
              color: corSub,
            ),
          ),
          const SizedBox(height: 10),

          OutlinedButton.icon(
            icon: _gerandoPdf
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: Text(_gerandoPdf ? 'Gerando Relatório...' : 'Gerar Relatório Consolidado em PDF'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: corBorda),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            onPressed: _gerandoPdf ? null : () => _gerarRelatorioPdf(db),
          ),

          const SizedBox(height: 20),

          // 4. GS1 EPCIS 2.0 JSON-LD
          Text(
            'Padrão Global GS1 EPCIS 2.0 (JSON-LD)',
            style: TextStyle(
              fontFamily: AppTokens.fonteTitulo,
              fontSize: AppTokens.tamSecao,
              fontWeight: FontWeight.w600,
              color: corTexto,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Eventos de rastreabilidade internacional em padrão W3C JSON-LD com URNs SGTIN e SGLN (seção 11.5).',
            style: TextStyle(
              fontFamily: AppTokens.fontePadrao,
              fontSize: 13,
              color: corSub,
            ),
          ),
          const SizedBox(height: 10),

          OutlinedButton.icon(
            icon: _gerandoEpcis
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.code_outlined, size: 18),
            label: Text(_gerandoEpcis ? 'Exportando EPCIS...' : 'Exportar GS1 EPCIS 2.0 JSON-LD'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: corBorda),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            onPressed: _gerandoEpcis ? null : () => _exportarEpcis(db),
          ),

          const SizedBox(height: 20),

          // 5. Entrada por Leitor Externo (seção 11.4)
          Text(
            'Dispositivos de Entrada Externos',
            style: TextStyle(
              fontFamily: AppTokens.fonteTitulo,
              fontSize: AppTokens.tamSecao,
              fontWeight: FontWeight.w600,
              color: corTexto,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Recepção contínua de leituras por leitor RFID ou código de barras físico (Bluetooth / USB HID).',
            style: TextStyle(
              fontFamily: AppTokens.fontePadrao,
              fontSize: 13,
              color: corSub,
            ),
          ),
          const SizedBox(height: 10),

          OutlinedButton.icon(
            icon: const Icon(Icons.barcode_reader, size: 18),
            label: const Text('Iniciar Modo Leitor Externo (HID)'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: corBorda),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            onPressed: () => _abrirLeitorExterno(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String rotulo, String valor, Color corValor, Color corSub) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo.toUpperCase(),
            style: TextStyle(
              fontFamily: AppTokens.fontePadrao,
              fontSize: 10,
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
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: corValor,
              fontFeatures: AppTokens.algarismosTabulares,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportarCsv(AppDatabase db) async {
    setState(() => _gerandoCsv = true);
    await HapticFeedback.mediumImpact();

    try {
      final csvString = await ExportacaoService.exportarCsv(
        db: db,
        perfil: _perfilCsv,
      );

      final nomePerfil = _perfilCsv == PerfilExportacao.themaGrp ? 'Thema-GRP' : 'E-Auditoria';

      if (mounted) {
        setState(() => _gerandoCsv = false);
        _mostrarModalResultado(
          titulo: 'CSV Exportado com Sucesso',
          subtitulo: 'Perfil $nomePerfil • Proteção CWE-1236 ativa',
          conteudo: csvString,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _gerandoCsv = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar CSV: $e')),
        );
      }
    }
  }

  Future<void> _gerarRelatorioPdf(AppDatabase db) async {
    setState(() => _gerandoPdf = true);
    await HapticFeedback.mediumImpact();

    try {
      final pdfBytes = await ExportacaoService.gerarRelatorioUnidadePdf(db: db);

      if (mounted) {
        setState(() => _gerandoPdf = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Relatório Geral PDF gerado (${(pdfBytes.length / 1024).toStringAsFixed(1)} KB) com assinaturas auditadas.',
            ),
            backgroundColor: AppTokens.statusConferido,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _gerandoPdf = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar PDF: $e')),
        );
      }
    }
  }

  Future<void> _exportarEpcis(AppDatabase db) async {
    setState(() => _gerandoEpcis = true);
    await HapticFeedback.mediumImpact();

    try {
      final jsonLd = await EpcisService.exportarEpcisJsonLd(db: db);

      if (mounted) {
        setState(() => _gerandoEpcis = false);
        _mostrarModalResultado(
          titulo: 'GS1 EPCIS 2.0 JSON-LD Gerado',
          subtitulo: 'Padrão global de rastreabilidade (seção 11.5)',
          conteudo: jsonLd,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _gerandoEpcis = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar EPCIS: $e')),
        );
      }
    }
  }

  void _abrirLeitorExterno(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const LeitorExternoDialog(salaId: 'sala_geral'),
    );
  }

  void _mostrarModalResultado({
    required String titulo,
    required String subtitulo,
    required String conteudo,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: const TextStyle(
                              fontFamily: AppTokens.fonteTitulo,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            subtitulo,
                            style: const TextStyle(
                              fontFamily: AppTokens.fontePadrao,
                              fontSize: 12,
                              color: AppTokens.cinza,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        tooltip: 'Copiar conteúdo',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: conteudo));
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Conteúdo copiado para a área de transferência!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTokens.brancoEscuro.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTokens.linha),
                        ),
                        child: SelectableText(
                          conteudo,
                          style: const TextStyle(
                            fontFamily: AppTokens.fontePlaqueta,
                            fontSize: 11,
                          ),
                        ),
                      ),
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
}
