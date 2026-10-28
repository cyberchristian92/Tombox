import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/abas.dart';
import '../../../core/widgets/barra_situacao.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../core/widgets/estado_vazio.dart';
import '../../../core/widgets/linha_bem.dart';
import '../../../core/widgets/migalhas.dart';
import '../../../data/local/queries_provider.dart';

class SalaDetalheScreen extends ConsumerStatefulWidget {
  final String salaId;

  const SalaDetalheScreen({
    super.key,
    required this.salaId,
  });

  @override
  ConsumerState<SalaDetalheScreen> createState() => _SalaDetalheScreenState();
}

class _SalaDetalheScreenState extends ConsumerState<SalaDetalheScreen> {
  int _abaAtiva = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final corFundoBloco = isDark ? AppTokens.brancoEscuro : AppTokens.branco;
    final corBorda = isDark ? AppTokens.linhaEscura : AppTokens.linha;
    final corTexto = isDark ? AppTokens.grafiteEscuro : AppTokens.grafite;

    final dadosAsync = ref.watch(dadosConferenciaSalaProvider(widget.salaId));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppTokens.barraEscura : AppTokens.tinta,
        foregroundColor: AppTokens.branco,
        elevation: 0,
        title: Text(
          'Sala',
          style: const TextStyle(
            fontFamily: AppTokens.fonteTitulo,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTokens.branco,
          ),
        ),
      ),
      body: dadosAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppTokens.paddingLateral),
          children: const [
            Esqueleto(altura: 20, largura: 180),
            SizedBox(height: 8),
            Esqueleto(altura: 28, largura: 240),
            SizedBox(height: 8),
            Esqueleto(altura: 16, largura: 200),
            SizedBox(height: 16),
            Esqueleto(altura: 10),
            SizedBox(height: 24),
            Esqueleto(altura: 200),
          ],
        ),
        error: (e, _) => Center(child: Text('Erro ao carregar sala: $e')),
        data: (dados) {
          final sala = dados.sala;
          final total = dados.bensEsperados.length;
          final lidos = dados.tombamentosLidos.length;

          final bensPendentes = dados.bensEsperados
              .where((b) => !dados.tombamentosLidos.contains(b.tombamento))
              .toList();

          final bensConferidos = dados.bensEsperados
              .where((b) => dados.tombamentosLidos.contains(b.tombamento))
              .toList();

          final bensOutraSala = dados.todosBensUnidade
              .where((b) => dados.tombamentosOutraSala.contains(b.tombamento))
              .toList();

          final responsavel = dados.bensEsperados
              .map((b) => b.responsavel)
              .firstWhere((r) => r != null && r.isNotEmpty, orElse: () => 'TJ-PA');

          // Seleciona bens da aba ativa
          final bensExibidos = _abaAtiva == 0
              ? bensPendentes
              : (_abaAtiva == 1 ? bensConferidos : bensOutraSala);

          final situacaoAba = _abaAtiva == 0
              ? SituacaoBem.pendente
              : (_abaAtiva == 1 ? SituacaoBem.conferido : SituacaoBem.outraSala);

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.paddingLateral,
                    AppTokens.s16,
                    AppTokens.paddingLateral,
                    0,
                  ),
                  children: [
                    // Migalhas em texto simples
                    Migalhas.fromCaminho(sala.caminhoCompleto),
                    const SizedBox(height: 4),

                    // Título da sala
                    Text(
                      sala.nome,
                      style: TextStyle(
                        fontFamily: AppTokens.fonteTitulo,
                        fontSize: AppTokens.tamTituloTela,
                        fontWeight: FontWeight.w600,
                        color: corTexto,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Responsável e progresso
                    Text(
                      'Responsável $responsavel. $lidos de $total conferidos.',
                      style: const TextStyle(
                        fontFamily: AppTokens.fontePadrao,
                        fontSize: 15,
                        color: AppTokens.cinza,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Barra de situação segmentada
                    BarraSituacao(
                      conferidos: lidos,
                      outraSala: bensOutraSala.length,
                      semCadastro: 0,
                      pendentes: bensPendentes.length,
                    ),
                    const SizedBox(height: 16),

                    // Abas
                    Abas(
                      abas: [
                        AbaItem(rotulo: 'Pendentes', contagem: bensPendentes.length),
                        AbaItem(rotulo: 'Conferidos', contagem: bensConferidos.length),
                        AbaItem(rotulo: 'Outra sala', contagem: bensOutraSala.length),
                      ],
                      indiceAtivo: _abaAtiva,
                      onMudou: (idx) => setState(() => _abaAtiva = idx),
                    ),

                    // Linhas de bens
                    Container(
                      decoration: BoxDecoration(
                        color: corFundoBloco,
                        border: Border(
                          bottom: BorderSide(color: corBorda, width: 1),
                        ),
                      ),
                      child: bensExibidos.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(AppTokens.s24),
                              child: Center(
                                child: Text(
                                  _abaAtiva == 0
                                      ? 'Nenhum bem pendente nesta sala.'
                                      : (_abaAtiva == 1
                                          ? 'Nenhum bem conferido ainda.'
                                          : 'Nenhum bem de outra sala localizado aqui.'),
                                  style: const TextStyle(
                                    fontFamily: AppTokens.fontePadrao,
                                    fontSize: 14,
                                    color: AppTokens.cinza,
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              children: bensExibidos.map((bem) {
                                return LinhaBem(
                                  tombamento: bem.tombamento,
                                  descricao: bem.descricao,
                                  categoria: bem.categoria,
                                  situacao: situacaoAba,
                                  onTap: () => context.push('/bens/${bem.tombamento}'),
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Botão fixo no rodapé "Conferir esta sala"
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.paddingLateral,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: corFundoBloco,
                  border: Border(
                    top: BorderSide(color: corBorda, width: 1),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.assignment_turned_in_outlined, size: 18),
                          label: const Text('Fechar sala'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: corBorda),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => context.push('/locais/${widget.salaId}/fechamento'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: BotaoPrincipal(
                          texto: 'Conferir sala',
                          icone: Icons.qr_code_scanner_outlined,
                          onPressed: () => context.push('/conferencia/${widget.salaId}'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
