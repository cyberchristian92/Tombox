import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_scaffold.dart';

class ImportacaoScreen extends StatelessWidget {
  const ImportacaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                        const Icon(Icons.check_circle_outline, color: Colors.green),
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
                    _buildReportRow('Total de linhas lidas:', '312'),
                    _buildReportRow('Bens válidos reconhecidos:', '308'),
                    _buildReportRow('Salas identificadas:', '15'),
                    _buildReportRow('Avisos de normalização:', '4 linhas ajustadas'),
                    _buildReportRow('Erros críticos descartados:', '0 linhas'),
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
                    const Text('• Separador: Ponto e vírgula (;)'),
                    const Text('• Codificação: UTF-8'),
                    const Text('• Coluna de Local: Comarca / Prédio / Andar / Sala'),
                    const Text('• Normalização de tombamento: Ativa (O→0, I→1)'),
                  ],
                ),
              ),
            ),
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
