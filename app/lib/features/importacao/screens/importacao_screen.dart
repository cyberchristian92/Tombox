import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../core/widgets/lista_dados.dart';
import '../../../data/importacao/importacao_service.dart';

class ImportacaoScreen extends ConsumerWidget {
  const ImportacaoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final importState = ref.watch(importacaoProvider);
    final relatorio = importState.relatorioAtivo;

    final corFundoBloco = isDark ? AppTokens.brancoEscuro : AppTokens.branco;
    final corBorda = isDark ? AppTokens.linhaEscura : AppTokens.linha;
    final corTexto = isDark ? AppTokens.grafiteEscuro : AppTokens.grafite;
    final corTextoSec = isDark ? AppTokens.cinzaEscuro : AppTokens.cinza;

    final dadosResumo = <(String, String)>[
      ('Unidade', relatorio?.unidadeNome ?? 'Demonstração TJPA'),
      ('Linhas lidas', relatorio != null ? '${relatorio.totalLinhasLidas}' : '302'),
      ('Bens válidos', relatorio != null ? '${relatorio.bensValidos}' : '300'),
      ('Salas', relatorio != null ? '${relatorio.totalSalas}' : '15'),
      ('Duplicados', relatorio != null ? '${relatorio.duplicadosAtualizados}' : '2 atualizados'),
      ('Normalizações', relatorio != null ? '${relatorio.avisos.length} linhas ajustadas' : '4 linhas ajustadas'),
      ('Erros críticos', relatorio != null ? '${relatorio.erros.length} linhas' : '0 linhas descartadas'),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppTokens.papelEscuro : AppTokens.papel,
      appBar: AppBar(
        title: const Text('Relatório de Importação'),
        backgroundColor: isDark ? AppTokens.barraEscura : AppTokens.tinta,
        foregroundColor: AppTokens.branco,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.paddingLateral,
            vertical: AppTokens.s20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho da Unidade e Qualidade
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    relatorio != null && relatorio.temErros
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline,
                    color: relatorio != null && relatorio.temErros
                        ? AppTokens.statusPendente
                        : AppTokens.statusConferido,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Importação Concluída',
                    style: TextStyle(
                      fontFamily: AppTokens.fonteTitulo,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: corTexto,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'A planilha foi processada e os bens foram distribuídos nas salas da unidade. A normalização de tombamentos substituiu caracteres especiais e unificou o formato oficial.',
                style: TextStyle(
                  fontFamily: AppTokens.fontePadrao,
                  fontSize: 14,
                  color: corTextoSec,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 16),

              // Bloco de Dados com ListaDados v2
              Container(
                decoration: BoxDecoration(
                  color: corFundoBloco,
                  borderRadius: BorderRadius.circular(AppTokens.raioBloco),
                  border: Border.all(color: corBorda, width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListaDados(dados: dadosResumo),
              ),

              const SizedBox(height: 16),

              // Texto corrido de formato detectado
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: corFundoBloco,
                  borderRadius: BorderRadius.circular(AppTokens.raioBloco),
                  border: Border.all(color: corBorda, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Formato do arquivo',
                      style: TextStyle(
                        fontFamily: AppTokens.fontePadrao,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: corTexto,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Separador ${relatorio?.separadorDetectado == '\t' ? 'por tabulação' : 'ponto e vírgula (;)'}, codificação ${relatorio?.codificacaoDetectada ?? 'UTF-8'}. Hierarquia de locais estruturada em Comarca, Prédio, Andar e Sala.',
                      style: TextStyle(
                        fontFamily: AppTokens.fontePadrao,
                        fontSize: 13,
                        color: corTextoSec,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botões v2 sem setas
              BotaoPrincipal(
                texto: 'Ver salas',
                icone: Icons.meeting_room_outlined,
                onPressed: () => context.go('/locais'),
              ),
              const SizedBox(height: 10),
              BotaoPrincipal(
                texto: 'Voltar para Início',
                secundario: true,
                onPressed: () => context.go('/'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
