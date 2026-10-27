import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_scaffold.dart';

class UnidadesScreen extends StatelessWidget {
  const UnidadesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      body: Padding(
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
                    Text(
                      'Inventário Patrimonial Offline',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Carregue a planilha da sua unidade para iniciar a conferência das salas sem necessidade de conexão com a internet.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_open_outlined,
                      size: 64,
                      color: theme.colorScheme.primary.withAlpha(120),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhuma unidade carregada',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Importe um arquivo CSV ou use os dados de demonstração.',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('Importar CSV'),
              onPressed: () => context.push('/importacao'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.science_outlined),
              label: const Text('Carregar Dados de Demonstração'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dados de demonstração serão integrados na Etapa 1.'),
                  ),
                );
                context.push('/salas');
              },
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.meeting_room_outlined),
              label: const Text('Acessar Salas'),
              onPressed: () => context.push('/salas'),
            ),
          ],
        ),
      ),
    );
  }
}
