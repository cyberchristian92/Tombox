import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_scaffold.dart';

class SalasScreen extends StatelessWidget {
  const SalasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final salasMock = [
      {'id': 'sala-01', 'nome': 'Sala 101 - Gabinete', 'predio': 'Fórum Central / 1º Andar', 'lidos': 12, 'total': 18, 'status': 'em andamento'},
      {'id': 'sala-02', 'nome': 'Sala 102 - Secretaria', 'predio': 'Fórum Central / 1º Andar', 'lidos': 0, 'total': 24, 'status': 'não iniciada'},
      {'id': 'sala-03', 'nome': 'Sala 201 - Audiências', 'predio': 'Fórum Central / 2º Andar', 'lidos': 15, 'total': 15, 'status': 'fechada'},
      {'id': 'sala-04', 'nome': 'Sala 202 - Assessoria', 'predio': 'Fórum Central / 2º Andar', 'lidos': 0, 'total': 10, 'status': 'não iniciada'},
    ];

    return AppScaffold(
      title: 'Salas da Unidade',
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: salasMock.length,
        itemBuilder: (context, index) {
          final sala = salasMock[index];
          final lidos = sala['lidos'] as int;
          final total = sala['total'] as int;
          final status = sala['status'] as String;
          final progresso = total > 0 ? lidos / total : 0.0;

          Color statusColor = Colors.grey;
          if (status == 'fechada') statusColor = Colors.green;
          if (status == 'em andamento') statusColor = Colors.orange;

          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push('/conferencia/${sala['id']}'),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            sala['nome'] as String,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(40),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor.withAlpha(100)),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sala['predio'] as String,
                      style: theme.textTheme.bodySmall,
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
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
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
