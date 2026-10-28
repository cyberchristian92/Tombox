import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/barra_busca.dart';
import '../../../core/widgets/estado_vazio.dart';
import '../../../core/widgets/linha_sala.dart';
import '../../../data/local/queries_provider.dart';

class LocaisScreen extends ConsumerStatefulWidget {
  const LocaisScreen({super.key});

  @override
  ConsumerState<LocaisScreen> createState() => _LocaisScreenState();
}

class _LocaisScreenState extends ConsumerState<LocaisScreen> {
  final TextEditingController _buscaController = TextEditingController();
  String _filtroTexto = '';

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final corFundoBloco = isDark ? AppTokens.brancoEscuro : AppTokens.branco;
    final corBorda = isDark ? AppTokens.linhaEscura : AppTokens.linha;
    final corTexto = isDark ? AppTokens.grafiteEscuro : AppTokens.grafite;

    final salasAsync = ref.watch(salasStreamProvider);

    return Scaffold(
      body: SafeArea(
        child: salasAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(AppTokens.paddingLateral),
            children: const [
              Esqueleto(altura: 44),
              SizedBox(height: 16),
              Esqueleto(altura: 80),
              SizedBox(height: 12),
              Esqueleto(altura: 80),
              SizedBox(height: 12),
              Esqueleto(altura: 80),
            ],
          ),
          error: (e, _) => Center(child: Text('Erro ao carregar locais: $e')),
          data: (todasSalas) {
            if (todasSalas.isEmpty) {
              return EstadoVazio(
                icone: Icons.meeting_room_outlined,
                titulo: 'Nenhuma sala encontrada',
                subtitulo: 'Importe uma unidade para visualizar a árvore de locais.',
                textoBotaoPrincipal: 'Importar unidade',
                onBotaoPrincipal: () => context.push('/importacao'),
              );
            }

            final filtradas = todasSalas.where((s) {
              if (_filtroTexto.isEmpty) return true;
              final q = _filtroTexto.toLowerCase();
              return s.nome.toLowerCase().contains(q) ||
                  s.caminhoCompleto.toLowerCase().contains(q);
            }).toList();

            // Agrupa por prédio e andar
            final grupos = <String, List<SalaComProgresso>>{};
            for (final sala in filtradas) {
              grupos.putIfAbsent(sala.predioEAndar, () => []).add(sala);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barra de Busca retangular
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.paddingLateral,
                    AppTokens.s12,
                    AppTokens.paddingLateral,
                    AppTokens.s8,
                  ),
                  child: BarraBusca(
                    controller: _buscaController,
                    hintText: 'Buscar sala por nome ou número...',
                    onChanged: (val) => setState(() => _filtroTexto = val),
                    onClear: () => setState(() => _filtroTexto = ''),
                  ),
                ),

                // Lista de árvore em linhas com recuo por nível
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: AppTokens.s24),
                    itemCount: grupos.keys.length,
                    itemBuilder: (context, idx) {
                      final predioEAndar = grupos.keys.elementAt(idx);
                      final salasDoGrupo = grupos[predioEAndar]!;

                      final totalBensGrupo =
                          salasDoGrupo.fold<int>(0, (sum, s) => sum + s.totalBens);
                      final lidosGrupo =
                          salasDoGrupo.fold<int>(0, (sum, s) => sum + s.bensLidos);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Linha de agrupamento (Prédio / Andar)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTokens.paddingLateral,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? AppTokens.papelEscuro : AppTokens.papel,
                              border: Border(
                                bottom: BorderSide(color: corBorda, width: 1),
                                top: BorderSide(color: corBorda, width: 1),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.account_tree_outlined,
                                  size: 18,
                                  color: AppTokens.cinza,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    predioEAndar,
                                    style: TextStyle(
                                      fontFamily: AppTokens.fonteTitulo,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: corTexto,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$lidosGrupo/$totalBensGrupo',
                                  style: TextStyle(
                                    fontFamily: AppTokens.fontePlaqueta,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: corTexto,
                                    fontFeatures: AppTokens.algarismosTabulares,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Salas filhas com recuo
                          Container(
                            decoration: BoxDecoration(
                              color: corFundoBloco,
                              border: Border(
                                bottom: BorderSide(color: corBorda, width: 1),
                              ),
                            ),
                            child: Column(
                              children: salasDoGrupo.map((sala) {
                                return LinhaSala(
                                  nome: sala.nome,
                                  andar: sala.caminhoCompleto,
                                  bensLidos: sala.bensLidos,
                                  totalBens: sala.totalBens,
                                  onTap: () => context.push('/locais/${sala.id}'),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
