import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../data/importacao/importacao_service.dart';
import '../../../data/local/queries_provider.dart';

class UnidadesScreen extends ConsumerWidget {
  const UnidadesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final importState = ref.watch(importacaoProvider);
    final unidadesAsync = ref.watch(unidadesStreamProvider);

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
                      'Carregue a planilha da sua unidade para conferência das salas sem necessidade de internet.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: unidadesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erro ao carregar unidades: $e')),
                data: (unidades) {
                  if (unidades.isEmpty) {
                    return Center(
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
                    );
                  }

                  return ListView.builder(
                    itemCount: unidades.length,
                    itemBuilder: (context, index) {
                      final u = unidades[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.account_balance),
                          ),
                          title: Text(u.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Arquivo: ${u.arquivoOrigem}'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => context.push('/salas'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            if (importState.processando) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Processando e normalizando CSV...'),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.file_upload_outlined),
                label: const Text('Importar CSV'),
                onPressed: () async {
                  final files = await FilePicker.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['csv', 'txt'],
                  );

                  if (files.isNotEmpty) {
                    final file = files.first;
                    final bytes = await file.xFile.readAsBytes();
                    if (context.mounted) {
                      await ref.read(importacaoProvider.notifier).importarBytes(
                            bytes: bytes,
                            nomeArquivo: file.name,
                          );
                      if (context.mounted) {
                        context.push('/importacao');
                      }
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.science_outlined),
                label: const Text('Carregar Dados de Demonstração'),
                onPressed: () async {
                  await ref
                      .read(importacaoProvider.notifier)
                      .importarDadosDemonstracao();
                  if (context.mounted) {
                    context.push('/importacao');
                  }
                },
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.meeting_room_outlined),
                label: const Text('Acessar Salas'),
                onPressed: () => context.push('/salas'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
