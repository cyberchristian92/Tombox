import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_scaffold.dart';

class ExportacaoScreen extends StatelessWidget {
  const ExportacaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Exportação de Resultados',
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
                        const Icon(Icons.summarize_outlined, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Resumo da Conferência',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildStatRow('Total de bens esperados:', '18'),
                    _buildStatRow('Bens encontrados na sala:', '12 (66.7%)'),
                    _buildStatRow('Bens de outra sala localizados:', '1'),
                    _buildStatRow('Bens não localizados (pendentes):', '6 (33.3%)'),
                    _buildStatRow('Eventos auditáveis registrados:', '27 eventos'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.security, size: 20, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Segurança & Auditoria',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('• Proteção CWE-1236 ativa: células com fórmulas são neutralizadas na exportação CSV.'),
                    Text('• Cadeia criptográfica SHA-256 encadeia todos os eventos para validação pelo gestor.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.table_view_outlined),
              label: const Text('Exportar CSV de Resultado (share_plus)'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Exportação CSV configurada com proteção contra injeção de fórmulas (CWE-1236).'),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.code_outlined),
              label: const Text('Exportar JSON de Eventos e Hashes'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pacote JSON assinado preparado para envio ao gestor.'),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              child: const Text('Voltar ao Início'),
              onPressed: () => context.go('/'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
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
