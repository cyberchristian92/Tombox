import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../data/local/queries_provider.dart';

class SalasScreen extends ConsumerWidget {
  const SalasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final salasAsync = ref.watch(salasStreamProvider);

    return AppScaffold(
      title: 'Salas da Unidade',
      body: salasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro ao carregar salas: $e')),
        data: (salas) {
          if (salas.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.meeting_room_outlined,
                      size: 64,
                      color: theme.colorScheme.primary.withAlpha(120),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhuma sala encontrada',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Carregue a planilha na tela inicial para visualizar as salas.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      child: const Text('Voltar ao Início'),
                      onPressed: () => context.go('/'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Agrupa as salas por prédio e andar
          final grupos = <String, List<SalaComProgresso>>{};
          for (final sala in salas) {
            grupos.putIfAbsent(sala.predioEAndar, () => []).add(sala);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: grupos.keys.length,
            itemBuilder: (context, grupoIndex) {
              final predioEAndar = grupos.keys.elementAt(grupoIndex);
              final salasDoGrupo = grupos[predioEAndar]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_city,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          predioEAndar,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...salasDoGrupo.map((sala) {
                    final lidos = sala.bensLidos;
                    final total = sala.totalBens;
                    final status = sala.status;
                    final progresso = sala.progresso;

                    Color statusColor = Colors.grey;
                    String statusLabel = 'não iniciada';
                    if (status == 'fechada') {
                      statusColor = Colors.green;
                      statusLabel = 'fechada';
                    } else if (status == 'em_andamento') {
                      statusColor = Colors.orange;
                      statusLabel = 'em andamento';
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.push('/conferencia/${sala.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      sala.nome,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withAlpha(40),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: statusColor.withAlpha(100),
                                      ),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progresso,
                                        minHeight: 8,
                                        backgroundColor: theme
                                            .colorScheme.surfaceContainerHighest,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '$lidos de $total lidos',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.share_outlined),
        label: const Text('Exportar Resultados'),
        onPressed: () => context.push('/exportacao'),
      ),
    );
  }
}
