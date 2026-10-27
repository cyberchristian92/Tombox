import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_scaffold.dart';

class ConferenciaScreen extends StatefulWidget {
  final String salaId;

  const ConferenciaScreen({
    super.key,
    required this.salaId,
  });

  @override
  State<ConferenciaScreen> createState() => _ConferenciaScreenState();
}

class _ConferenciaScreenState extends State<ConferenciaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _lanternaAtiva = false;
  bool _modoUmaPlaqueta = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Conferência - ${widget.salaId}',
      actions: [
        IconButton(
          icon: Icon(_lanternaAtiva ? Icons.flash_on : Icons.flash_off),
          tooltip: 'Lanterna',
          onPressed: () {
            setState(() {
              _lanternaAtiva = !_lanternaAtiva;
            });
          },
        ),
        IconButton(
          icon: Icon(_modoUmaPlaqueta ? Icons.filter_center_focus : Icons.center_focus_weak),
          tooltip: 'Modo Uma Plaqueta',
          onPressed: () {
            setState(() {
              _modoUmaPlaqueta = !_modoUmaPlaqueta;
            });
          },
        ),
      ],
      body: Column(
        children: [
          // Contador superior de progresso
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: theme.colorScheme.primaryContainer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '12 de 18 bens conferidos',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(48, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Fechar Sala'),
                  onPressed: () => _confirmarFechamento(context),
                ),
              ],
            ),
          ),

          // Simulador do visor da câmera com detecções da Etapa 0
          Expanded(
            flex: 5,
            child: Container(
              color: Colors.black87,
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 72,
                          color: Colors.white.withAlpha(120),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pipeline da Câmera (ML Kit)',
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Detecção OCR e Código de Barras ativada na Etapa 2',
                          style: TextStyle(
                            color: Colors.white.withAlpha(140),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chip de leitura provável (simulação da spec)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ActionChip(
                        avatar: const Icon(Icons.help_outline, size: 18, color: Colors.black),
                        backgroundColor: Colors.amberAccent,
                        label: const Text(
                          '10023? Toque para confirmar leitura provável',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Leitura 10023 confirmada com um toque!')),
                          );
                        },
                      ),
                    ),
                  ),

                  // Botão de busca manual
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: FloatingActionButton.small(
                      heroTag: 'manual_search',
                      tooltip: 'Busca Manual',
                      child: const Icon(Icons.search),
                      onPressed: () {
                        context.push('/bem/10023');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Painel inferior com abas (Lidos, Faltando, De outra sala)
          Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              indicatorColor: theme.colorScheme.primary,
              tabs: const [
                Tab(text: 'Lidos (12)'),
                Tab(text: 'Faltando (6)'),
                Tab(text: 'Outra Sala (1)'),
              ],
            ),
          ),

          // Lista de itens por aba
          Expanded(
            flex: 4,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildItemList(context, 'Lidos', Colors.green),
                _buildItemList(context, 'Faltando', Colors.red),
                _buildItemList(context, 'Outra Sala', Colors.amber),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(BuildContext context, String tipo, Color indicatorColor) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 3,
      itemBuilder: (context, index) {
        final tombamento = '100${20 + index}';
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: indicatorColor.withAlpha(40),
            child: Icon(Icons.inventory_2, color: indicatorColor, size: 20),
          ),
          title: Text('Tombamento #$tombamento'),
          subtitle: const Text('Computador Desktop Dell Optiplex'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/bem/$tombamento'),
        );
      },
    );
  }

  void _confirmarFechamento(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fechar Conferência da Sala?'),
        content: const Text(
          '12 de 18 bens foram conferidos. Existem 6 bens não localizados nesta sala. Deseja fechar e gerar o resumo?',
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('Confirmar Fechamento'),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push('/exportacao');
            },
          ),
        ],
      ),
    );
  }
}
