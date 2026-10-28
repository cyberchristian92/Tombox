import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/local/database_provider.dart';
import '../../../domain/homologacao/homologacao_models.dart';
import '../../../domain/homologacao/homologacao_service.dart';
import '../../../domain/identidade/identidade_service.dart';
import '../../../domain/membros/membro_models.dart';
import '../../../domain/membros/perfil_provider.dart';

final homologacaoSalasProvider =
    FutureProvider.autoDispose<List<StatusHomologacaoSala>>((ref) async {
  final db = ref.watch(databaseProvider);
  return HomologacaoService.obterStatusSalas(db);
});

class HomologacaoScreen extends ConsumerStatefulWidget {
  const HomologacaoScreen({super.key});

  @override
  ConsumerState<HomologacaoScreen> createState() => _HomologacaoScreenState();
}

class _HomologacaoScreenState extends ConsumerState<HomologacaoScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final corFundoBloco = isDark ? AppTokens.brancoEscuro : AppTokens.branco;
    final corBorda = isDark ? AppTokens.linhaEscura : AppTokens.linha;
    final corTexto = isDark ? AppTokens.grafiteEscuro : AppTokens.grafite;
    final corTextoSec = isDark ? AppTokens.cinzaEscuro : AppTokens.cinza;

    final statusSalasAsync = ref.watch(homologacaoSalasProvider);
    final papelAtual = ref.watch(perfilUsuarioProvider);
    final isGestor = papelAtual == PapelUsuario.gestor;

    return Scaffold(
      backgroundColor: isDark ? AppTokens.papelEscuro : AppTokens.papel,
      appBar: AppBar(
        title: Text(
          'Homologação patrimonial',
          style: AppTokens.tituloSecao.copyWith(color: corTexto),
        ),
        backgroundColor: corFundoBloco,
        elevation: 0,
        iconTheme: IconThemeData(color: corTexto),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: corBorda, height: 1),
        ),
      ),
      body: statusSalasAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTokens.tinta),
        ),
        error: (err, stack) => Center(
          child: Text('Erro ao carregar salas: $err'),
        ),
        data: (salas) {
          final homologadas = salas.where((s) => s.homologada).toList();
          final prontasParaHomologar = salas.where((s) => s.podeHomologar).toList();
          final pendentes = salas.where((s) => !s.homologada && !s.podeHomologar).toList();

          return Column(
            children: [
              // Banner informativo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTokens.s16),
                decoration: BoxDecoration(
                  color: corFundoBloco,
                  border: Border(bottom: BorderSide(color: corBorda)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isGestor ? Icons.verified_outlined : Icons.info_outline,
                      size: 20,
                      color: isGestor ? AppTokens.douradoMarca : AppTokens.tinta,
                    ),
                    const SizedBox(width: AppTokens.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isGestor
                                ? 'HOMOLOGAÇÃO OFICIAL DO GESTOR'
                                : 'VISUALIZAÇÃO DE CONFERENTE',
                            style: TextStyle(
                              fontFamily: AppTokens.fonteTitulo,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isGestor ? AppTokens.douradoMarca : AppTokens.tinta,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'No TJPA, a conferência de campo é revisada e o setor responsável homologa os resultados. Somente bens homologados entram no relatório oficial.',
                            style: TextStyle(
                              fontFamily: AppTokens.fontePadrao,
                              fontSize: AppTokens.tamSecundario,
                              color: corTextoSec,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Indicadores rápidos
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _buildKpiCard('HOMOLOGADAS', '${homologadas.length}', AppTokens.statusConferido, corFundoBloco, corBorda),
                    const SizedBox(width: 8),
                    _buildKpiCard('PRONTAS', '${prontasParaHomologar.length}', AppTokens.douradoMarca, corFundoBloco, corBorda),
                    const SizedBox(width: 8),
                    _buildKpiCard('EM ANDAMENTO', '${pendentes.length}', corTextoSec, corFundoBloco, corBorda),
                  ],
                ),
              ),

              // Lista de Salas
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: salas.length,
                  itemBuilder: (context, index) {
                    final sala = salas[index];
                    return _buildCardSala(sala, isGestor, corFundoBloco, corBorda, corTexto, corTextoSec);
                  },
                ),
              ),

              // Botão de homologação em lote no rodapé
              if (isGestor && prontasParaHomologar.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: corFundoBloco,
                    border: Border(top: BorderSide(color: corBorda)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: AppTokens.alturaBotaoPrincipal,
                    child: ElevatedButton.icon(
                      onPressed: () => _homologarTodasProntas(prontasParaHomologar),
                      icon: const Icon(Icons.verified),
                      label: Text('HOMOLOGAR ${prontasParaHomologar.length} SALAS PRONTAS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTokens.douradoMarca,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.raioBotao),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: AppTokens.fonteTitulo,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildKpiCard(String titulo, String valor, Color cor, Color corFundo, Color corBorda) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: corFundo,
          borderRadius: BorderRadius.circular(AppTokens.raioBloco),
          border: Border.all(color: corBorda),
        ),
        child: Column(
          children: [
            Text(
              valor,
              style: TextStyle(
                fontFamily: AppTokens.fontePlaqueta,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: cor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              titulo,
              style: const TextStyle(
                fontFamily: AppTokens.fontePadrao,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSala(
    StatusHomologacaoSala sala,
    bool isGestor,
    Color corFundoBloco,
    Color corBorda,
    Color corTexto,
    Color corTextoSec,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: corFundoBloco,
        borderRadius: BorderRadius.circular(AppTokens.raioBloco),
        border: Border.all(
          color: sala.homologada ? AppTokens.statusConferido.withAlpha(120) : corBorda,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sala.salaNome,
                        style: TextStyle(
                          fontFamily: AppTokens.fonteTitulo,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: corTexto,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sala.caminhoCompleto,
                        style: TextStyle(
                          fontFamily: AppTokens.fontePadrao,
                          fontSize: 13,
                          color: corTextoSec,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sala.homologada
                        ? AppTokens.statusConferido.withAlpha(30)
                        : (sala.podeHomologar
                            ? AppTokens.douradoMarca.withAlpha(30)
                            : AppTokens.statusPendente.withAlpha(30)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    sala.homologada
                        ? 'HOMOLOGADO'
                        : (sala.podeHomologar ? 'PRONTA' : 'PENDENTE'),
                    style: TextStyle(
                      fontFamily: AppTokens.fontePadrao,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: sala.homologada
                          ? AppTokens.statusConferido
                          : (sala.podeHomologar
                              ? AppTokens.douradoMarca
                              : AppTokens.statusPendente),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: corBorda),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bens conferidos: ${sala.bensConferidos} / ${sala.totalBens}',
                  style: TextStyle(
                    fontFamily: AppTokens.fontePadrao,
                    fontSize: 13,
                    color: corTexto,
                  ),
                ),
                if (sala.divergenciasPendentes > 0)
                  Text(
                    '${sala.divergenciasPendentes} divergência(s)',
                    style: const TextStyle(
                      fontFamily: AppTokens.fontePadrao,
                      fontSize: 13,
                      color: AppTokens.statusSemCadastro,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  const Text(
                    'Sem divergências',
                    style: TextStyle(
                      fontFamily: AppTokens.fontePadrao,
                      fontSize: 12,
                      color: AppTokens.statusConferido,
                    ),
                  ),
              ],
            ),

            if (sala.homologada && sala.homologadoPor != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                color: AppTokens.statusConferido.withAlpha(15),
                child: Row(
                  children: [
                    const Icon(Icons.security, size: 14, color: AppTokens.statusConferido),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Homologado por ${sala.homologadoPor} • Assinatura Ed25519 registrada',
                        style: const TextStyle(fontFamily: AppTokens.fontePadrao, fontSize: 11, color: AppTokens.statusConferido),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (!sala.homologada && isGestor) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: AppTokens.alturaBotaoPrincipal,
                child: ElevatedButton.icon(
                  onPressed: sala.divergenciasPendentes > 0
                      ? null
                      : () => _homologarSalaIndividual(sala),
                  icon: const Icon(Icons.verified, size: 16),
                  label: Text(
                    sala.divergenciasPendentes > 0
                        ? 'RESOLVA AS DIVERGÊNCIAS ANTES DE HOMOLOGAR'
                        : 'HOMOLOGAR CONFERÊNCIA DESTA SALA',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.tinta,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: corFundoBloco,
                    disabledForegroundColor: corTextoSec,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.raioBotao),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: AppTokens.fonteTitulo,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _homologarSalaIndividual(StatusHomologacaoSala sala) async {
    final db = ref.read(databaseProvider);
    try {
      final idAparelho = await IdentidadeService.obterOuCriarIdentidade();
      final keyPair = idAparelho.keyPair;
      if (keyPair == null) throw Exception('Chave privada indisponível.');

      await HomologacaoService.homologarSala(
        db: db,
        unidadeId: 'unidade_demo',
        salaId: sala.salaId,
        keyPairGestor: keyPair,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sala ${sala.salaNome} homologada com sucesso!'),
            backgroundColor: AppTokens.statusConferido,
          ),
        );
        ref.invalidate(homologacaoSalasProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao homologar sala: $e'),
            backgroundColor: AppTokens.statusSemCadastro,
          ),
        );
      }
    }
  }

  Future<void> _homologarTodasProntas(List<StatusHomologacaoSala> prontas) async {
    final db = ref.read(databaseProvider);
    try {
      final idAparelho = await IdentidadeService.obterOuCriarIdentidade();
      final keyPair = idAparelho.keyPair;
      if (keyPair == null) throw Exception('Chave privada indisponível.');

      await HomologacaoService.homologarEmLote(
        db: db,
        unidadeId: 'unidade_demo',
        salaIds: prontas.map((s) => s.salaId).toList(),
        keyPairGestor: keyPair,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${prontas.length} salas homologadas com sucesso!'),
            backgroundColor: AppTokens.statusConferido,
          ),
        );
        ref.invalidate(homologacaoSalasProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao homologar salas em lote: $e'),
            backgroundColor: AppTokens.statusSemCadastro,
          ),
        );
      }
    }
  }
}
