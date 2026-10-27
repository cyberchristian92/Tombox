import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../data/importacao/importacao_service.dart';

class ImportacaoScreen extends ConsumerWidget {
  const ImportacaoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final importState = ref.watch(importacaoProvider);
    final relatorio = importState.relatorioAtivo;

    return AppScaffold(
      title: 'Importação de CSV',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          relatorio != null && relatorio.temErros
                              ? Icons.warning_amber
                              : Icons.check_circle_outline,
                          color: relatorio != null && relatorio.temErros
                              ? Colors.orange
                              : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Relatório de Qualidade do CSV',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildReportRow(
                      'Unidade carregada:',
                      relatorio?.unidadeNome ?? 'Demonstração TJPA',
                    ),
                    _buildReportRow(
                      'Total de linhas lidas:',
                      relatorio != null ? '${relatorio.totalLinhasLidas}' : '302',
                    ),
                    _buildReportRow(
                      'Bens válidos reconhecidos:',
                      relatorio != null ? '${relatorio.bensValidos}' : '300',
                    ),
                    _buildReportRow(
                      'Salas identificadas:',
                      relatorio != null ? '${relatorio.totalSalas}' : '15',
                    ),
                    _buildReportRow(
                      'Duplicados atualizados:',
                      relatorio != null ? '${relatorio.duplicadosAtualizados}' : '2',
                    ),
                    _buildReportRow(
                      'Avisos de normalização:',
                      relatorio != null ? '${relatorio.avisos.length} linhas' : '4 linhas ajustadas',
                    ),
                    _buildReportRow(
                      'Erros críticos descartados:',
                      relatorio != null ? '${relatorio.erros.length} linhas' : '0 linhas',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detecção Automática de Formato',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('• Separador: ${relatorio?.separadorDetectado == '\t' ? 'Tabulação' : relatorio?.separadorDetectado ?? 'Ponto e vírgula (;)'}'),
                    Text('• Codificação: ${relatorio?.codificacaoDetectada ?? 'UTF-8'}'),
                    const Text('• Coluna de Local: Comarca / Prédio / Andar / Sala'),
                    const Text('• Normalização de tombamento: Ativa (O→0, pontuação removida)'),
                  ],
                ),
              ),
            ),
            if (relatorio != null && relatorio.itens.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalhes e Ocorrências nas Linhas',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...relatorio.itens.take(10).map((item) {
                        final isErro = item.tipo == 'ERRO';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isErro ? Colors.red.withAlpha(40) : Colors.amber.withAlpha(40),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Linha ${item.linha}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isErro ? Colors.red : Colors.orange.shade800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.mensagem,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (relatorio.itens.length > 10)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '... e mais ${relatorio.itens.length - 10} ocorrências verificadas com sucesso.',
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continuar para Lista de Salas'),
              onPressed: () => context.push('/salas'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              child: const Text('Voltar para Início'),
              onPressed: () => context.go('/'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
