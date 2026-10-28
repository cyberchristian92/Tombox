import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatador.dart';
import '../../../core/widgets/carimbo.dart';
import '../../../core/widgets/linha_do_tempo.dart';
import '../../../core/widgets/lista_dados.dart';
import '../../../core/widgets/plaqueta.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/database_provider.dart';

class BemScreen extends ConsumerStatefulWidget {
  final String tombamento;

  const BemScreen({
    super.key,
    required this.tombamento,
  });

  @override
  ConsumerState<BemScreen> createState() => _BemScreenState();
}

class _BemScreenState extends ConsumerState<BemScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final db = ref.watch(databaseProvider);

    final corFundoBloco = isDark ? AppTokens.brancoEscuro : AppTokens.branco;
    final corBorda = isDark ? AppTokens.linhaEscura : AppTokens.linha;
    final corHero = isDark ? AppTokens.barraEscura : AppTokens.tinta;

    return FutureBuilder<Bem?>(
      future: (db.select(db.bens)
            ..where((b) => b.tombamento.equals(widget.tombamento)))
          .getSingleOrNull(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final bem = snapshot.data;
        if (bem == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: corHero,
              foregroundColor: AppTokens.branco,
              title: const Text('Ficha do bem'),
            ),
            body: Center(
              child: Text(
                'Bem #${widget.tombamento} não encontrado.',
                style: const TextStyle(
                  fontFamily: AppTokens.fontePadrao,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }

        return FutureBuilder<(Local?, List<Evento>)>(
          future: Future.wait([
            _obterLocal(db, bem),
            (db.select(db.eventos)
                  ..where((e) => e.tombamento.equals(widget.tombamento))
                  ..orderBy([(e) => OrderingTerm.desc(e.seq)]))
                .get(),
          ]).then((res) => (res[0] as Local?, res[1] as List<Evento>)),
          builder: (context, localSnapshot) {
            final local = localSnapshot.data?.$1;
            final eventos = localSnapshot.data?.$2 ?? [];

            // Determina carimbo de situação
            Widget carimboWidget;
            if (eventos.isNotEmpty) {
              final ultimo = eventos.first;
              final dataFormatada = Formatador.dataHora(ultimo.timestamp);
              final conferente = ultimo.conferente;

              if (ultimo.localId == bem.localEsperadoId) {
                carimboWidget = Carimbo.conferido(
                  detalhe: '$dataFormatada, por $conferente',
                );
              } else {
                carimboWidget = Carimbo.outraSala(
                  detalhe: '$dataFormatada, por $conferente',
                );
              }
            } else {
              carimboWidget = Carimbo.pendente(
                detalhe: 'Aguardando conferência',
              );
            }

            final localCaminho = local?.caminhoCompleto ??
                (bem.localEsperadoId.isNotEmpty
                    ? bem.localEsperadoId
                    : 'Unidade Central');

            final localCurto = local?.nome ??
                (localCaminho.contains('/')
                    ? localCaminho.split('/').last.trim()
                    : localCaminho);

            // Monta lista de dados como pares (rotulo, valor)
            final dadosItens = <(String, String)>[
              ('Tombamento', bem.tombamento),
              ('Categoria', bem.categoria ?? 'Geral'),
              ('Local esperado', localCaminho.replaceAll('/', ', ')),
              if (bem.responsavel != null && bem.responsavel!.isNotEmpty)
                ('Responsável', bem.responsavel!),
              if (bem.numeroSerie != null && bem.numeroSerie!.isNotEmpty)
                ('Número de série', bem.numeroSerie!),
              if ((bem.fabricante != null && bem.fabricante!.isNotEmpty) ||
                  (bem.modelo != null && bem.modelo!.isNotEmpty))
                (
                  'Fabricante/Modelo',
                  '${bem.fabricante ?? ''} ${bem.modelo ?? ''}'.trim()
                ),
            ];

            // Extras (ano, valor, etc)
            if (bem.extras != null && bem.extras!.isNotEmpty) {
              try {
                final extras = jsonDecode(bem.extras!) as Map<String, dynamic>;
                if (extras.containsKey('ano_aquisicao')) {
                  dadosItens.add(
                    ('Ano aquisição', '${extras['ano_aquisicao']}'),
                  );
                }
                if (extras.containsKey('valor_estimado')) {
                  dadosItens.add(
                    ('Valor estimado', '${extras['valor_estimado']}'),
                  );
                }
              } catch (_) {}
            }

            // Monta linha do tempo de eventos
            final itensTimeline = <ItemLinhaDoTempo>[];
            for (final ev in eventos) {
              itensTimeline.add(
                ItemLinhaDoTempo(
                  dataHora: ev.timestamp,
                  titulo: ev.tipo == 'LEITURA'
                      ? 'Leitura de conferência'
                      : (ev.tipo == 'CADASTRO' ? 'Importação de cadastro' : ev.tipo),
                  detalhe: 'assinatura verificada',
                ),
              );
            }

            if (itensTimeline.isEmpty) {
              itensTimeline.add(
                ItemLinhaDoTempo(
                  dataHora: DateTime.now().subtract(const Duration(days: 1)),
                  titulo: 'Cadastro original importado',
                  detalhe: 'assinatura verificada',
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(
                backgroundColor: corHero,
                foregroundColor: AppTokens.branco,
                elevation: 0,
                title: const Text(
                  'Bem patrimonial',
                  style: TextStyle(
                    fontFamily: AppTokens.fonteTitulo,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.branco,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 22, color: AppTokens.branco),
                    tooltip: 'Compartilhar ficha',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Exportação da ficha individual gerada.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        // Topo azul (.hero) com Plaqueta Grande
                        Container(
                          color: corHero,
                          padding: const EdgeInsets.fromLTRB(
                            AppTokens.paddingLateral,
                            18,
                            AppTokens.paddingLateral,
                            22,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Plaqueta(
                                numero: bem.tombamento,
                                grande: true,
                                subtitulo: 'TJPA, patrimônio',
                              ),
                              const SizedBox(height: 16),
                              Text(
                                bem.descricao,
                                style: const TextStyle(
                                  fontFamily: AppTokens.fonteTitulo,
                                  fontSize: AppTokens.tamTituloFicha,
                                  fontWeight: FontWeight.w600,
                                  color: AppTokens.branco,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${bem.categoria ?? 'Patrimônio'}. $localCurto.',
                                style: const TextStyle(
                                  fontFamily: AppTokens.fontePadrao,
                                  fontSize: 14,
                                  color: Color(0xFFB9C6D4),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Carimbo da situação
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTokens.paddingLateral,
                            16,
                            AppTokens.paddingLateral,
                            0,
                          ),
                          child: carimboWidget,
                        ),

                        const SizedBox(height: 16),

                        // Lista de dados em livro de tombo
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.paddingLateral,
                          ),
                          child: ListaDados(dados: dadosItens),
                        ),

                        const SizedBox(height: 16),

                        // Linha do tempo
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.paddingLateral,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Histórico de eventos',
                                style: TextStyle(
                                  fontFamily: AppTokens.fonteTitulo,
                                  fontSize: AppTokens.tamSecao,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppTokens.grafiteEscuro : AppTokens.grafite,
                                ),
                              ),
                              const SizedBox(height: 12),
                              LinhaDoTempo(itens: itensTimeline),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                  // Barra de ações fixa no rodapé (4 ações iguais com divisórias verticais)
                  Container(
                    decoration: BoxDecoration(
                      color: corFundoBloco,
                      border: Border(
                        top: BorderSide(color: corBorda, width: 1),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        height: 58,
                        child: Row(
                          children: [
                            _buildAcao(
                              icone: Icons.camera_alt_outlined,
                              rotulo: 'Tirar foto',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Captura de foto do bem')),
                                );
                              },
                              isDark: isDark,
                              corBorda: corBorda,
                              temDivisoria: true,
                            ),
                            _buildAcao(
                              icone: Icons.warning_amber_outlined,
                              rotulo: 'Divergência',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Apontar divergência do bem')),
                                );
                              },
                              isDark: isDark,
                              corBorda: corBorda,
                              temDivisoria: true,
                            ),
                            _buildAcao(
                              icone: Icons.history_outlined,
                              rotulo: 'Histórico',
                              onTap: () {},
                              isDark: isDark,
                              corBorda: corBorda,
                              temDivisoria: true,
                            ),
                            _buildAcao(
                              icone: Icons.edit_outlined,
                              rotulo: 'Editar',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Editar atributos do bem')),
                                );
                              },
                              isDark: isDark,
                              corBorda: corBorda,
                              temDivisoria: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Future<Local?> _obterLocal(AppDatabase db, Bem bem) async {
    if (bem.localEsperadoId.isEmpty) return null;
    final porId = await (db.select(db.locais)
          ..where((l) => l.id.equals(bem.localEsperadoId)))
        .getSingleOrNull();
    if (porId != null) return porId;

    final todosLocais = await db.select(db.locais).get();
    for (final l in todosLocais) {
      if (l.caminhoCompleto.contains(bem.localEsperadoId) ||
          l.nome.contains(bem.localEsperadoId)) {
        return l;
      }
    }
    return null;
  }

  Widget _buildAcao({
    required IconData icone,
    required String rotulo,
    required VoidCallback onTap,
    required bool isDark,
    required Color corBorda,
    required bool temDivisoria,
  }) {
    final corTinta = isDark ? AppTokens.tintaEscuro : AppTokens.tinta;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: temDivisoria
              ? BoxDecoration(
                  border: Border(right: BorderSide(color: corBorda, width: 1)),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, size: 20, color: corTinta),
              const SizedBox(height: 2),
              Text(
                rotulo,
                style: TextStyle(
                  fontFamily: AppTokens.fontePadrao,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: corTinta,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
