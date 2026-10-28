import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/abas.dart';
import '../../../core/widgets/barra_busca.dart';
import '../../../core/widgets/chip_status.dart';
import '../../../core/widgets/estado_vazio.dart';
import '../../../core/widgets/linha_bem.dart';
import '../../../data/local/queries_provider.dart';

class BensScreen extends ConsumerStatefulWidget {
  const BensScreen({super.key});

  @override
  ConsumerState<BensScreen> createState() => _BensScreenState();
}

class _BensScreenState extends ConsumerState<BensScreen> {
  final TextEditingController _buscaController = TextEditingController();
  String _filtroTexto = '';
  int _filtroAba = 0; // 0: Todos, 1: Conferidos, 2: Pendentes, 3: Outra sala

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

    final bensAsync = ref.watch(bensComStatusStreamProvider);

    return Scaffold(
      body: SafeArea(
        child: bensAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(AppTokens.paddingLateral),
            children: const [
              Esqueleto(altura: 44),
              SizedBox(height: 16),
              Esqueleto(altura: 44),
              SizedBox(height: 16),
              Esqueleto(altura: 60),
              SizedBox(height: 8),
              Esqueleto(altura: 60),
              SizedBox(height: 8),
              Esqueleto(altura: 60),
            ],
          ),
          error: (e, _) => Center(child: Text('Erro ao carregar bens: $e')),
          data: (todosBens) {
            // Contagens para as abas
            final totalTodos = todosBens.length;
            final totalConferidos = todosBens
                .where((b) => b.status == StatusBem.encontrado)
                .length;
            final totalPendentes = todosBens
                .where((b) => b.status == StatusBem.pendente)
                .length;
            final totalOutraSala = todosBens
                .where((b) => b.status == StatusBem.outraSala)
                .length;

            // Filtra pela busca e aba
            var filtrados = todosBens.where((item) {
              if (_filtroTexto.isNotEmpty) {
                final q = _filtroTexto.toLowerCase();
                final tombMatch = item.bem.tombamento.toLowerCase().contains(q);
                final descMatch = item.bem.descricao.toLowerCase().contains(q);
                final serieMatch =
                    (item.bem.numeroSerie ?? '').toLowerCase().contains(q);
                if (!tombMatch && !descMatch && !serieMatch) return false;
              }

              if (_filtroAba == 1 && item.status != StatusBem.encontrado) {
                return false;
              }
              if (_filtroAba == 2 && item.status != StatusBem.pendente) {
                return false;
              }
              if (_filtroAba == 3 && item.status != StatusBem.outraSala) {
                return false;
              }

              return true;
            }).toList();

            return Column(
              children: [
                // Campo retangular de busca
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.paddingLateral,
                    AppTokens.s12,
                    AppTokens.paddingLateral,
                    AppTokens.s8,
                  ),
                  child: BarraBusca(
                    controller: _buscaController,
                    hintText: 'Buscar por tombamento, descrição ou série...',
                    onChanged: (val) => setState(() => _filtroTexto = val),
                    onClear: () => setState(() => _filtroTexto = ''),
                  ),
                ),

                // Abas de filtro simples (não pílulas coloridas)
                Abas(
                  abas: [
                    AbaItem(rotulo: 'Todos', contagem: totalTodos),
                    AbaItem(rotulo: 'Conferidos', contagem: totalConferidos),
                    AbaItem(rotulo: 'Pendentes', contagem: totalPendentes),
                    AbaItem(rotulo: 'Outra sala', contagem: totalOutraSala),
                  ],
                  indiceAtivo: _filtroAba,
                  onMudou: (idx) => setState(() => _filtroAba = idx),
                ),

                // Lista de bens em linhas sobre fundo branco
                Expanded(
                  child: filtrados.isEmpty
                      ? EstadoVazio(
                          icone: Icons.inventory_2_outlined,
                          titulo: 'Nenhum bem encontrado',
                          subtitulo: _filtroTexto.isNotEmpty
                              ? 'Tente ajustar os termos da sua pesquisa.'
                              : 'Nenhum bem nesta categoria.',
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: corFundoBloco,
                            border: Border(
                              bottom: BorderSide(color: corBorda, width: 1),
                            ),
                          ),
                          child: ListView.builder(
                            itemCount: filtrados.length,
                            itemBuilder: (context, idx) {
                              final item = filtrados[idx];
                              SituacaoBem sit;
                              switch (item.status) {
                                case StatusBem.encontrado:
                                  sit = SituacaoBem.conferido;
                                  break;
                                case StatusBem.outraSala:
                                  sit = SituacaoBem.outraSala;
                                  break;
                                case StatusBem.naoCadastrado:
                                  sit = SituacaoBem.semCadastro;
                                  break;
                                case StatusBem.pendente:
                                  sit = SituacaoBem.pendente;
                                  break;
                              }

                              return LinhaBem(
                                tombamento: item.bem.tombamento,
                                descricao: item.bem.descricao,
                                categoria: item.bem.categoria,
                                situacao: sit,
                                onTap: () =>
                                    context.push('/bens/${item.bem.tombamento}'),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/bem-novo'),
        backgroundColor: isDark ? AppTokens.brancoEscuro : AppTokens.tinta,
        foregroundColor: isDark ? AppTokens.grafiteEscuro : AppTokens.branco,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.raioBloco),
          side: BorderSide(color: corBorda),
        ),
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Novo Bem',
          style: TextStyle(
            fontFamily: AppTokens.fontePadrao,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
