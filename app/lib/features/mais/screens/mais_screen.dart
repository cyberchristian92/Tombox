import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../brand/brand_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/importacao/importacao_service.dart';
import '../../../data/local/perfil_provider.dart';
import '../../../data/local/queries_provider.dart';
import '../../../domain/identidade/identidade_provider.dart';
import '../../configuracoes/providers/diagnostico_provider.dart';

class MaisScreen extends ConsumerWidget {
  const MaisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unidadeAtiva = ref.watch(unidadeAtivaProvider);
    final perfil = ref.watch(perfilProvider);
    final perfilNotifier = ref.read(perfilProvider.notifier);
    final modoDiagnostico = ref.watch(modoDiagnosticoProvider);
    final brandState = ref.watch(brandNotifierProvider);

    final corFundoBloco = isDark ? AppTokens.brancoEscuro : AppTokens.branco;
    final corBorda = isDark ? AppTokens.linhaEscura : AppTokens.linha;
    final corTexto = isDark ? AppTokens.grafiteEscuro : AppTokens.grafite;
    final corTextoSec = isDark ? AppTokens.cinzaEscuro : AppTokens.cinza;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppTokens.s16),
          children: [
            // 1. Cabeçalho do Perfil (linhas com divisórias)
            Container(
              decoration: BoxDecoration(
                color: corFundoBloco,
                border: Border(
                  top: BorderSide(color: corBorda, width: 1),
                  bottom: BorderSide(color: corBorda, width: 1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.paddingLateral),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? AppTokens.papelEscuro : AppTokens.papel,
                        borderRadius: BorderRadius.circular(AppTokens.raioBloco),
                        border: Border.all(color: corBorda),
                      ),
                      child: Center(
                        child: Text(
                          perfil.configurado
                              ? perfil.nome
                                  .split(' ')
                                  .take(2)
                                  .map((p) => p.isNotEmpty ? p[0] : '')
                                  .join()
                              : '?',
                          style: TextStyle(
                            fontFamily: AppTokens.fonteTitulo,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: isDark ? AppTokens.tintaEscuro : AppTokens.tinta,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.s16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                perfil.configurado ? perfil.nome : 'Configurar perfil',
                                style: TextStyle(
                                  fontFamily: AppTokens.fonteTitulo,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: corTexto,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: perfil.papel == 'gestor'
                                      ? AppTokens.statusOutraSala.withAlpha(30)
                                      : AppTokens.statusConferido.withAlpha(30),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  perfil.papel == 'gestor' ? 'Gestor' : 'Conferente',
                                  style: TextStyle(
                                    fontFamily: AppTokens.fontePadrao,
                                    color: perfil.papel == 'gestor'
                                        ? AppTokens.statusOutraSala
                                        : AppTokens.statusConferido,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            perfil.matricula.isNotEmpty
                                ? 'Matrícula: ${perfil.matricula}'
                                : 'Toque para configurar matrícula',
                            style: TextStyle(
                              fontFamily: AppTokens.fontePadrao,
                              fontSize: 13,
                              color: corTextoSec,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Builder(
                            builder: (context) {
                              final identidadeAsync = ref.watch(identidadeAparelhoProvider);
                              final impressao = identidadeAsync.when(
                                data: (id) => id.impressaoCurta,
                                loading: () => 'Carregando...',
                                error: (_, _) => 'ED25-LOCAL-0001',
                              );
                              return InkWell(
                                onTap: () {
                                  final pubKey = identidadeAsync.asData?.value.publicKeyHex;
                                  if (pubKey != null) {
                                    Clipboard.setData(ClipboardData(text: pubKey));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Chave pública copiada: ${pubKey.substring(0, 16)}...'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Chave Ed25519: $impressao',
                                      style: TextStyle(
                                        fontFamily: AppTokens.fontePlaqueta,
                                        fontSize: 12,
                                        color: corTextoSec,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.copy_outlined, size: 12, color: corTextoSec),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.swap_horiz_outlined, size: 22),
                      tooltip: 'Alternar papel (Gestor/Conferente)',
                      onPressed: () {
                        perfilNotifier.alternarPapel();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Papel alternado para: ${ref.read(perfilProvider).papel}',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Seção: Inventário e dados
            _buildTituloSecao('Inventário e dados', corTexto),
            Container(
              decoration: BoxDecoration(
                color: corFundoBloco,
                border: Border(
                  top: BorderSide(color: corBorda, width: 1),
                  bottom: BorderSide(color: corBorda, width: 1),
                ),
              ),
              child: Column(
                children: [
                  _buildLinhaItem(
                    icone: Icons.apartment_outlined,
                    titulo: 'Unidade ativa',
                    subtitulo: unidadeAtiva?.nome ?? 'Nenhuma unidade carregada',
                    corTexto: corTexto,
                    corTextoSec: corTextoSec,
                    corBorda: corBorda,
                    onTap: () => context.push('/importacao'),
                  ),
                  _buildLinhaItem(
                    icone: Icons.file_upload_outlined,
                    titulo: 'Importar planilha CSV',
                    subtitulo: 'Carregar inventário inicial',
                    corTexto: corTexto,
                    corTextoSec: corTextoSec,
                    corBorda: corBorda,
                    onTap: () => context.push('/importacao'),
                  ),
                  _buildLinhaItem(
                    icone: Icons.play_circle_outline,
                    titulo: 'Usar dados de demonstração',
                    subtitulo: 'Comarca de Breves (300 bens sintéticos)',
                    corTexto: corTexto,
                    corTextoSec: corTextoSec,
                    corBorda: corBorda,
                    onTap: () async {
                      final sm = ScaffoldMessenger.of(context);
                      sm.showSnackBar(
                        const SnackBar(content: Text('Carregando demonstração de Breves...')),
                      );
                      final notifier = ref.read(importacaoProvider.notifier);
                      await notifier.importarDadosDemonstracao();
                      sm.showSnackBar(
                        const SnackBar(
                          content: Text('Demonstração carregada com sucesso!'),
                          backgroundColor: AppTokens.statusConferido,
                        ),
                      );
                      if (context.mounted) {
                        context.go('/');
                      }
                    },
                  ),
                  _buildLinhaItem(
                    icone: Icons.file_download_outlined,
                    titulo: 'Exportar inventário',
                    subtitulo: 'Relatório oficial e termos de responsabilidade',
                    corTexto: corTexto,
                    corTextoSec: corTextoSec,
                    corBorda: corBorda,
                    temDivisoria: true,
                    onTap: () => context.push('/exportacao'),
                  ),
                  _buildLinhaItem(
                    icone: Icons.sync_outlined,
                    titulo: 'Sincronização P2P',
                    subtitulo: 'Troca em rede local e pacote .tombox offline',
                    corTexto: corTexto,
                    corTextoSec: corTextoSec,
                    corBorda: corBorda,
                    temDivisoria: false,
                    onTap: () => context.push('/sincronizacao'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Seção: Aparência e marca
            _buildTituloSecao('Aparência e marca', corTexto),
            Container(
              decoration: BoxDecoration(
                color: corFundoBloco,
                border: Border(
                  top: BorderSide(color: corBorda, width: 1),
                  bottom: BorderSide(color: corBorda, width: 1),
                ),
              ),
              child: Column(
                children: [
                  _buildLinhaItem(
                    icone: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    titulo: isDark ? 'Modo claro' : 'Modo escuro',
                    subtitulo: isDark ? 'Ativar tema claro' : 'Ativar tema escuro',
                    corTexto: corTexto,
                    corTextoSec: corTextoSec,
                    corBorda: corBorda,
                    onTap: () {
                      ref.read(themeModeProvider.notifier).toggle();
                    },
                  ),
                  _buildLinhaItem(
                    icone: Icons.palette_outlined,
                    titulo: 'Marca ativa',
                    subtitulo: brandState.currentPreset.label,
                    corTexto: corTexto,
                    corTextoSec: corTextoSec,
                    corBorda: corBorda,
                    temDivisoria: false,
                    onTap: () {
                      _mostrarSeletorMarca(context, ref);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Seção: Sistema e diagnósticos
            _buildTituloSecao('Sistema e diagnósticos', corTexto),
            Container(
              decoration: BoxDecoration(
                color: corFundoBloco,
                border: Border(
                  top: BorderSide(color: corBorda, width: 1),
                  bottom: BorderSide(color: corBorda, width: 1),
                ),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.paddingLateral,
                      vertical: 2,
                    ),
                    secondary: const Icon(Icons.bug_report_outlined, size: 22),
                    title: Text(
                      'Modo diagnóstico',
                      style: TextStyle(
                        fontFamily: AppTokens.fontePadrao,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: corTexto,
                      ),
                    ),
                    subtitle: Text(
                      'Exibe detalhes técnicos e logs do motor',
                      style: TextStyle(
                        fontFamily: AppTokens.fontePadrao,
                        fontSize: 13,
                        color: corTextoSec,
                      ),
                    ),
                    value: modoDiagnostico,
                    onChanged: (val) {
                      ref.read(modoDiagnosticoProvider.notifier).setEnabled(val);
                    },
                  ),
                  Divider(color: corBorda, height: 1),
                  _buildLinhaItem(
                    icone: Icons.info_outline,
                    titulo: 'Sobre o Tombox',
                    subtitulo: 'Versão 2.0 · Offline-first para inventário patrimonial',
                    corTexto: corTexto,
                    corTextoSec: corTextoSec,
                    corBorda: corBorda,
                    temDivisoria: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTituloSecao(String titulo, Color corTexto) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTokens.paddingLateral, 0, AppTokens.paddingLateral, 6),
      child: Text(
        titulo,
        style: TextStyle(
          fontFamily: AppTokens.fonteTitulo,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: corTexto,
        ),
      ),
    );
  }

  Widget _buildLinhaItem({
    required IconData icone,
    required String titulo,
    required String subtitulo,
    required Color corTexto,
    required Color corTextoSec,
    required Color corBorda,
    required VoidCallback onTap,
    bool temDivisoria = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.paddingLateral,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(icone, size: 22, color: corTextoSec),
                const SizedBox(width: AppTokens.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontFamily: AppTokens.fontePadrao,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: corTexto,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitulo,
                        style: TextStyle(
                          fontFamily: AppTokens.fontePadrao,
                          fontSize: 13,
                          color: corTextoSec,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: corTextoSec),
              ],
            ),
          ),
          if (temDivisoria) Divider(color: corBorda, height: 1),
        ],
      ),
    );
  }

  void _mostrarSeletorMarca(BuildContext context, WidgetRef ref) {
    final brandState = ref.read(brandNotifierProvider);
    final brandNotifier = ref.read(brandNotifierProvider.notifier);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.raioFolha)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(AppTokens.s16),
                child: Text(
                  'Selecionar identidade visual',
                  style: TextStyle(
                    fontFamily: AppTokens.fonteTitulo,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...BrandPreset.values.map((preset) {
                return ListTile(
                  title: Text(preset.label),
                  trailing: brandState.currentPreset == preset
                      ? const Icon(Icons.check, color: AppTokens.statusConferido)
                      : null,
                  onTap: () {
                    brandNotifier.loadPreset(preset);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
