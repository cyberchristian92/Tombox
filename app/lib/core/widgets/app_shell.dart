import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/local/queries_provider.dart';
import '../theme/app_tokens.dart';
import 'barra_inferior.dart';
import 'indicador_sync.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  final int selectedIndex;

  const AppShell({
    super.key,
    required this.child,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unidadeAtiva = ref.watch(unidadeAtivaProvider);

    final corBarra = isDark ? AppTokens.barraEscura : AppTokens.tinta;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: corBarra,
        foregroundColor: AppTokens.branco,
        elevation: 0,
        titleSpacing: AppTokens.paddingLateral,
        title: InkWell(
          onTap: () => _mostrarSeletorUnidade(context, ref),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTokens.douradoMarca,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text(
                  'TJPA',
                  style: TextStyle(
                    fontFamily: AppTokens.fontePlaqueta,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF13365C),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  unidadeAtiva?.nome ?? 'Tombox',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTokens.fonteTitulo,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppTokens.branco,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 20, color: AppTokens.branco),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined, size: 22, color: AppTokens.branco),
            tooltip: 'Buscar Bens',
            onPressed: () => context.go('/bens'),
          ),
          const IndicadorSync(estado: EstadoSync.sincronizado),
          const SizedBox(width: 8),
        ],
      ),
      body: child,
      bottomNavigationBar: BarraInferior(
        selectedIndex: selectedIndex,
        onSelectTab: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/locais');
              break;
            case 3:
              context.go('/bens');
              break;
            case 4:
              context.go('/mais');
              break;
          }
        },
        onConferir: () => context.push('/conferencia/sem_sala'),
      ),
    );
  }

  void _mostrarSeletorUnidade(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTokens.brancoEscuro : AppTokens.branco,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.raioFolha)),
      ),
      builder: (ctx) {
        final unidadesAsync = ref.watch(unidadesStreamProvider);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTokens.s16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTokens.paddingLateral),
                  child: Text(
                    'Unidade ativa',
                    style: TextStyle(
                      fontFamily: AppTokens.fonteTitulo,
                      fontSize: AppTokens.tamSecao,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTokens.grafiteEscuro : AppTokens.grafite,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                unidadesAsync.when(
                  loading: () => const Center(child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Erro: $e'),
                  ),
                  data: (lista) {
                    if (lista.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Nenhuma unidade carregada.'),
                      );
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: lista.map((u) {
                        return ListTile(
                          leading: const Icon(Icons.apartment_outlined, size: 22),
                          title: Text(
                            u.nome,
                            style: const TextStyle(
                              fontFamily: AppTokens.fontePadrao,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            'Importado em ${u.dataImportacao.day.toString().padLeft(2, '0')}/${u.dataImportacao.month.toString().padLeft(2, '0')}/${u.dataImportacao.year}',
                            style: const TextStyle(
                              fontFamily: AppTokens.fontePadrao,
                              fontSize: 13,
                              color: AppTokens.cinza,
                            ),
                          ),
                          onTap: () {
                            ref.read(unidadeAtivaIdProvider.notifier).state = u.id;
                            Navigator.pop(ctx);
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                Divider(
                  color: isDark ? AppTokens.linhaEscura : AppTokens.linha,
                  height: 1,
                ),
                ListTile(
                  leading: const Icon(Icons.add_outlined, size: 22),
                  title: const Text(
                    'Importar nova unidade CSV',
                    style: TextStyle(
                      fontFamily: AppTokens.fontePadrao,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/importacao');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
