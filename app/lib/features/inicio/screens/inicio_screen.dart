import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatador.dart';
import '../../../core/widgets/barra_situacao.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../core/widgets/estado_vazio.dart';
import '../../../core/widgets/linha_sala.dart';
import '../../../data/importacao/importacao_service.dart';
import '../../../data/local/queries_provider.dart';

class InicioScreen extends ConsumerWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unidadeAtiva = ref.watch(unidadeAtivaProvider);
    final estatisticasAsync = ref.watch(estatisticasUnidadeProvider);
    final salasAsync = ref.watch(salasStreamProvider);

    // Estado vazio se não houver unidade
    if (unidadeAtiva == null) {
      return Scaffold(
        body: SafeArea(
          child: EstadoVazio(
            icone: Icons.inventory_2_outlined,
            titulo: 'Nenhuma unidade carregada',
            subtitulo:
                'Importe uma planilha CSV de patrimônio ou use os dados de demonstração para testar o Tombox.',
            textoBotaoPrincipal: 'Importar planilha CSV',
            onBotaoPrincipal: () => context.push('/importacao'),
            textoBotaoSecundario: 'Usar dados de demonstração (Breves)',
            onBotaoSecundario: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Carregando dados de demonstração...')),
              );
              final notifier = ref.read(importacaoProvider.notifier);
              await notifier.importarDadosDemonstracao();
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Dados da Comarca de Breves carregados com sucesso!'),
                  backgroundColor: AppTokens.statusConferido,
                ),
              );
            },
          ),
        ),
      );
    }

    // Carregamento com Esqueleto (nunca mostrar zeros!)
    if (estatisticasAsync.isLoading || salasAsync.isLoading) {
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.paddingLateral,
              vertical: AppTokens.s20,
            ),
            children: const [
              Esqueleto(altura: 32, largura: 220),
              SizedBox(height: 8),
              Esqueleto(altura: 16, largura: 280),
              SizedBox(height: 24),
              Esqueleto(altura: 10),
              SizedBox(height: 16),
              Esqueleto(altura: 120),
              SizedBox(height: 24),
              Esqueleto(altura: 140),
            ],
          ),
        ),
      );
    }

    final estatisticas = estatisticasAsync.value ??
        const EstatisticasUnidade(
          totalBens: 0,
          totalConferidos: 0,
          percentualConferido: 0,
          divergenciasAbertas: 0,
          salasPendentes: 0,
          salasTotal: 0,
        );

    final salas = salasAsync.value ?? [];

    // Sala em andamento (status 'em_andamento')
    final salaEmAndamento = salas.cast<SalaComProgresso?>().firstWhere(
      (s) => s?.status == 'em_andamento',
      orElse: () => null,
    );

    // Se nenhuma sala em andamento, pega a primeira pendente para "Começar conferência"
    final salaAlvo = salaEmAndamento ??
        salas.cast<SalaComProgresso?>().firstWhere(
          (s) => s?.status != 'fechada' && (s?.bensLidos ?? 0) < (s?.totalBens ?? 1),
          orElse: () => salas.isNotEmpty ? salas.first : null,
        );

    final ehContinuar = salaEmAndamento != null;

    // Conferencia iniciada ou data de importacao
    final dataImportacao = unidadeAtiva.dataImportacao;
    final dataTexto = '${dataImportacao.day} de ${_nomeMes(dataImportacao.month)}';

    final totalSalas = salas.length;
    final totalBens = estatisticas.totalBens;
    final conferidos = estatisticas.totalConferidos;
    final divergencias = estatisticas.divergenciasAbertas;
    final pendentes = (totalBens - conferidos - divergencias).clamp(0, totalBens);

    final corFundoBloco = isDark ? AppTokens.brancoEscuro : AppTokens.branco;
    final corBorda = isDark ? AppTokens.linhaEscura : AppTokens.linha;
    final corTexto = isDark ? AppTokens.grafiteEscuro : AppTokens.grafite;
    final corTextoSec = isDark ? AppTokens.cinzaEscuro : AppTokens.cinza;

    return Scaffold(
      backgroundColor: isDark ? AppTokens.papelEscuro : AppTokens.papel,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(estatisticasUnidadeProvider);
            ref.invalidate(salasStreamProvider);
            ref.invalidate(bensComStatusStreamProvider);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.paddingLateral,
              vertical: AppTokens.s20,
            ),
            children: [
              // Título com o nome do prédio ou unidade
              Text(
                unidadeAtiva.nome,
                style: TextStyle(
                  fontFamily: AppTokens.fonteTitulo,
                  fontSize: AppTokens.tamTituloTela,
                  fontWeight: FontWeight.w600,
                  color: corTexto,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                conferidos > 0
                    ? '$totalSalas salas e ${Formatador.numero(totalBens)} bens. Conferência iniciada em $dataTexto.'
                    : '$totalSalas salas e ${Formatador.numero(totalBens)} bens. Nenhuma sala conferida ainda.',
                style: TextStyle(
                  fontFamily: AppTokens.fontePadrao,
                  fontSize: 15,
                  color: corTextoSec,
                ),
              ),

              const SizedBox(height: 20),

              // Barra segmentada de situação
              BarraSituacao(
                conferidos: conferidos,
                outraSala: divergencias,
                semCadastro: 0,
                pendentes: pendentes,
              ),

              const SizedBox(height: 14),

              // Legenda de situação
              LegendaSituacao(
                conferidos: conferidos,
                outraSala: divergencias,
                semCadastro: 0,
                pendentes: pendentes,
              ),

              const SizedBox(height: 18),

              // Bloco Em andamento / Começar conferência
              if (salaAlvo != null)
                Container(
                  padding: const EdgeInsets.all(AppTokens.s16),
                  decoration: BoxDecoration(
                    color: corFundoBloco,
                    borderRadius: BorderRadius.circular(AppTokens.raioBloco),
                    border: Border.all(color: corBorda, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ehContinuar ? 'Em andamento' : 'Próxima sala',
                        style: TextStyle(
                          fontFamily: AppTokens.fontePadrao,
                          fontSize: 13,
                          color: corTextoSec,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        salaAlvo.nome,
                        style: TextStyle(
                          fontFamily: AppTokens.fontePadrao,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: corTexto,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${salaAlvo.predioEAndar}. ${salaAlvo.bensLidos} de ${salaAlvo.totalBens} bens conferidos.',
                        style: TextStyle(
                          fontFamily: AppTokens.fontePadrao,
                          fontSize: 14,
                          color: corTextoSec,
                        ),
                      ),
                      const SizedBox(height: 12),
                      BotaoPrincipal(
                        texto: ehContinuar ? 'Continuar conferência' : 'Começar conferência',
                        icone: Icons.qr_code_scanner_outlined,
                        onPressed: () => context.push('/conferencia/${salaAlvo.id}'),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 26),

              // Cabeçalho da seção Salas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Salas',
                    style: TextStyle(
                      fontFamily: AppTokens.fonteTitulo,
                      fontSize: AppTokens.tamSecao,
                      fontWeight: FontWeight.w600,
                      color: corTexto,
                    ),
                  ),
                  InkWell(
                    onTap: () => context.go('/locais'),
                    child: Text(
                      'Ver todas',
                      style: TextStyle(
                        fontFamily: AppTokens.fontePadrao,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTokens.tintaEscuro : AppTokens.tinta,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Lista de salas em linhas sobre fundo branco
              Container(
                decoration: BoxDecoration(
                  color: corFundoBloco,
                  border: Border(
                    top: BorderSide(color: corBorda, width: 1),
                    bottom: BorderSide(color: corBorda, width: 1),
                  ),
                ),
                child: Column(
                  children: salas.take(5).map((sala) {
                    return LinhaSala(
                      nome: sala.nome,
                      andar: sala.predioEAndar,
                      bensLidos: sala.bensLidos,
                      totalBens: sala.totalBens,
                      onTap: () => context.push('/locais/${sala.id}'),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static String _nomeMes(int mes) {
    const meses = [
      '',
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro'
    ];
    return (mes >= 1 && mes <= 12) ? meses[mes] : '';
  }
}
