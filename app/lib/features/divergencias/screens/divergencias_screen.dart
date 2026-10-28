import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/plaqueta.dart';
import '../../../data/local/database_provider.dart';
import '../../../domain/divergencias/divergencia_models.dart';
import '../../../domain/divergencias/divergencia_service.dart';
import '../../../domain/identidade/identidade_service.dart';
import '../../../domain/membros/membro_models.dart';
import '../../../domain/membros/perfil_provider.dart';

final divergenciasProvider = FutureProvider.autoDispose<List<DivergenciaItem>>((ref) async {
  final db = ref.watch(databaseProvider);
  return DivergenciaService.obterFilaDivergencias(db);
});

class DivergenciasScreen extends ConsumerStatefulWidget {
  const DivergenciasScreen({super.key});

  @override
  ConsumerState<DivergenciasScreen> createState() => _DivergenciasScreenState();
}

class _DivergenciasScreenState extends ConsumerState<DivergenciasScreen> {
  String _filtro = 'todas';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final corFundoBloco = isDark ? AppTokens.brancoEscuro : AppTokens.branco;
    final corBorda = isDark ? AppTokens.linhaEscura : AppTokens.linha;
    final corTexto = isDark ? AppTokens.grafiteEscuro : AppTokens.grafite;
    final corTextoSec = isDark ? AppTokens.cinzaEscuro : AppTokens.cinza;

    final divergenciasAsync = ref.watch(divergenciasProvider);
    final papelAtual = ref.watch(perfilUsuarioProvider);
    final isGestor = papelAtual == PapelUsuario.gestor;

    return Scaffold(
      backgroundColor: isDark ? AppTokens.papelEscuro : AppTokens.papel,
      appBar: AppBar(
        title: Text(
          'Fila de divergências',
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
      body: divergenciasAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTokens.tinta),
        ),
        error: (err, stack) => Center(
          child: Text('Erro ao carregar divergências: $err'),
        ),
        data: (todas) {
          final pendentes = todas.where((d) => !d.resolvida).toList();
          final resolvidas = todas.where((d) => d.resolvida).toList();

          List<DivergenciaItem> filtradas;
          if (_filtro == 'sala') {
            filtradas = pendentes.where((d) => d.tipo == TipoDivergencia.salaIncorreta).toList();
          } else if (_filtro == 'nao_localizado') {
            filtradas = pendentes.where((d) => d.tipo == TipoDivergencia.naoLocalizado).toList();
          } else if (_filtro == 'conflito') {
            filtradas = pendentes.where((d) => d.tipo == TipoDivergencia.conflitoConferentes).toList();
          } else if (_filtro == 'resolvidas') {
            filtradas = resolvidas;
          } else {
            filtradas = pendentes;
          }

          return Column(
            children: [
              // Banner de papel
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
                      isGestor ? Icons.verified_user_outlined : Icons.remove_red_eye_outlined,
                      size: 20,
                      color: isGestor ? AppTokens.douradoMarca : AppTokens.tinta,
                    ),
                    const SizedBox(width: AppTokens.s12),
                    Expanded(
                      child: Text(
                        isGestor
                            ? 'Perfil Gestor: você tem autorização para homologar e resolver divergências em lote.'
                            : 'Perfil Conferente: modo de visualização. Solicite a um gestor para homologar decisões.',
                        style: TextStyle(
                          fontFamily: AppTokens.fontePadrao,
                          fontSize: AppTokens.tamSecundario,
                          color: corTextoSec,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Barra de filtros
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _buildChipFiltro('todas', 'Pendentes (${pendentes.length})', corFundoBloco, corBorda, corTexto),
                    const SizedBox(width: 8),
                    _buildChipFiltro(
                      'sala',
                      'Sala incorreta (${pendentes.where((d) => d.tipo == TipoDivergencia.salaIncorreta).length})',
                      corFundoBloco,
                      corBorda,
                      corTexto,
                    ),
                    const SizedBox(width: 8),
                    _buildChipFiltro(
                      'nao_localizado',
                      'Não localizados (${pendentes.where((d) => d.tipo == TipoDivergencia.naoLocalizado).length})',
                      corFundoBloco,
                      corBorda,
                      corTexto,
                    ),
                    const SizedBox(width: 8),
                    _buildChipFiltro(
                      'conflito',
                      'Conflitos (${pendentes.where((d) => d.tipo == TipoDivergencia.conflitoConferentes).length})',
                      corFundoBloco,
                      corBorda,
                      corTexto,
                    ),
                    const SizedBox(width: 8),
                    _buildChipFiltro('resolvidas', 'Resolvidas (${resolvidas.length})', corFundoBloco, corBorda, corTexto),
                  ],
                ),
              ),

              // Lista de itens
              Expanded(
                child: filtradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 48, color: AppTokens.statusConferido),
                            const SizedBox(height: 12),
                            Text(
                              'Nenhuma divergência nesta categoria',
                              style: TextStyle(fontFamily: AppTokens.fontePadrao, color: corTextoSec),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filtradas.length,
                        itemBuilder: (context, index) {
                          return _buildCardDivergencia(filtradas[index], isGestor, corFundoBloco, corBorda, corTexto, corTextoSec);
                        },
                      ),
              ),

              // Ação em lote no rodapé (para Gestor)
              if (isGestor && pendentes.isNotEmpty && _filtro != 'resolvidas')
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: corFundoBloco,
                    border: Border(top: BorderSide(color: corBorda)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: AppTokens.alturaBotaoPrincipal,
                    child: OutlinedButton.icon(
                      onPressed: () => _resolverTodasSalasDivergentes(pendentes),
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('APROVAR TRANSFERÊNCIAS EM LOTE'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTokens.tinta,
                        side: const BorderSide(color: AppTokens.tinta),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.raioBotao),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: AppTokens.fonteTitulo,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
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

  Widget _buildChipFiltro(String chave, String label, Color corFundo, Color corBorda, Color corTexto) {
    final selecionado = _filtro == chave;
    return InkWell(
      onTap: () => setState(() => _filtro = chave),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selecionado ? AppTokens.tinta : corFundo,
          borderRadius: BorderRadius.circular(AppTokens.raioCarimbo),
          border: Border.all(
            color: selecionado ? AppTokens.tinta : corBorda,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTokens.fontePadrao,
            fontSize: 12,
            color: selecionado ? Colors.white : corTexto,
            fontWeight: selecionado ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildCardDivergencia(
    DivergenciaItem item,
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
        border: Border.all(color: corBorda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de status da divergência
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: corFundoBloco,
              border: Border(bottom: BorderSide(color: corBorda)),
            ),
            child: Row(
              children: [
                _buildBadgeTipo(item),
                const Spacer(),
                if (item.resolvida)
                  const Text(
                    'RESOLVIDA',
                    style: TextStyle(
                      fontFamily: AppTokens.fontePadrao,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.statusConferido,
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Plaqueta(numero: item.tombamento),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.descricao,
                            style: TextStyle(
                              fontFamily: AppTokens.fonteTitulo,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: corTexto,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Esperado: ${item.localEsperadoNome}',
                            style: TextStyle(
                              fontFamily: AppTokens.fontePadrao,
                              fontSize: 13,
                              color: corTextoSec,
                            ),
                          ),
                          if (item.localEncontradoNome != null)
                            Text(
                              'Encontrado: ${item.localEncontradoNome}',
                              style: const TextStyle(
                                fontFamily: AppTokens.fontePadrao,
                                fontSize: 13,
                                color: AppTokens.tinta,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(height: 1, color: corBorda),
                const SizedBox(height: 12),

                // Conflito lado a lado se houver
                if (item.conflito != null) ...[
                  _buildConflitoLadoALado(item.conflito!, corFundoBloco, corBorda, corTexto, corTextoSec),
                  const SizedBox(height: 12),
                ],

                // Causa Provável
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTokens.papelEscuro
                        : AppTokens.papel,
                    borderRadius: BorderRadius.circular(AppTokens.raioBloco),
                    border: Border.all(color: corBorda),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.psychology_outlined, size: 16, color: AppTokens.statusOutraSala),
                          const SizedBox(width: 6),
                          Text(
                            'CAUSA PROVÁVEL',
                            style: TextStyle(
                              fontFamily: AppTokens.fonteTitulo,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: corTextoSec,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.causaProvavel,
                        style: TextStyle(
                          fontFamily: AppTokens.fontePadrao,
                          fontSize: 13,
                          color: corTexto,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          Icon(Icons.arrow_forward, size: 14, color: AppTokens.tinta),
                          SizedBox(width: 6),
                          Text(
                            'PRÓXIMO PASSO RECOMENDADO',
                            style: TextStyle(
                              fontFamily: AppTokens.fonteTitulo,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTokens.tinta,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.proximoPasso,
                        style: TextStyle(
                          fontFamily: AppTokens.fontePadrao,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: corTexto,
                        ),
                      ),
                    ],
                  ),
                ),

                if (item.resolvida && item.resolucao != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: AppTokens.statusConferido.withAlpha(20),
                    child: Text(
                      'Decisão do Gestor: ${item.resolucao}',
                      style: const TextStyle(
                        fontFamily: AppTokens.fontePadrao,
                        fontSize: 12,
                        color: AppTokens.statusConferido,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                // Botão de resolução para o Gestor
                if (isGestor && !item.resolvida) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: AppTokens.alturaBotaoPrincipal,
                    child: ElevatedButton(
                      onPressed: () => _abrirModalResolucao(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTokens.tinta,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.raioBotao),
                        ),
                      ),
                      child: const Text(
                        'RESOLVER DIVERGÊNCIA',
                        style: TextStyle(
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
        ],
      ),
    );
  }

  Widget _buildBadgeTipo(DivergenciaItem item) {
    Color cor;
    IconData icone;
    switch (item.tipo) {
      case TipoDivergencia.naoLocalizado:
        cor = AppTokens.statusSemCadastro;
        icone = AppTokens.iconeSemCadastro;
        break;
      case TipoDivergencia.salaIncorreta:
        cor = AppTokens.statusOutraSala;
        icone = AppTokens.iconeOutraSala;
        break;
      case TipoDivergencia.semCadastro:
        cor = AppTokens.douradoMarca;
        icone = Icons.help_outline;
        break;
      case TipoDivergencia.conflitoConferentes:
        cor = Colors.deepOrange;
        icone = Icons.compare_arrows_outlined;
        break;
      case TipoDivergencia.estadoDivergente:
        cor = AppTokens.tinta;
        icone = Icons.tune_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withAlpha(25),
        borderRadius: BorderRadius.circular(AppTokens.raioCarimbo),
        border: Border.all(color: cor.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 14, color: cor),
          const SizedBox(width: 4),
          Text(
            item.tipo.rotulo.toUpperCase(),
            style: TextStyle(
              fontFamily: AppTokens.fontePadrao,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflitoLadoALado(
    ConflitoLadoALado conflito,
    Color corFundoBloco,
    Color corBorda,
    Color corTexto,
    Color corTextoSec,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(15),
        border: Border.all(color: Colors.orange.withAlpha(80)),
        borderRadius: BorderRadius.circular(AppTokens.raioBloco),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.compare_arrows, size: 18, color: Colors.deepOrange),
              SizedBox(width: 6),
              Text(
                'CONFLITO ENTRE CONFERENTES DE CAMPO',
                style: TextStyle(
                  fontFamily: AppTokens.fonteTitulo,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: corFundoBloco,
                    border: Border.all(color: corBorda),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Versão A: ${conflito.conferenteA}',
                        style: TextStyle(
                          fontFamily: AppTokens.fonteTitulo,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: corTexto,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('Local: ${conflito.salaA}', style: TextStyle(fontFamily: AppTokens.fontePadrao, fontSize: 12, color: corTextoSec)),
                      if (conflito.hashFotoA != null)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text('📷 Foto anexada', style: TextStyle(fontSize: 11, color: AppTokens.statusConferido)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: corFundoBloco,
                    border: Border.all(color: corBorda),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Versão B: ${conflito.conferenteB}',
                        style: TextStyle(
                          fontFamily: AppTokens.fonteTitulo,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: corTexto,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('Local: ${conflito.salaB}', style: TextStyle(fontFamily: AppTokens.fontePadrao, fontSize: 12, color: corTextoSec)),
                      if (conflito.hashFotoB != null)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text('📷 Foto anexada', style: TextStyle(fontSize: 11, color: AppTokens.statusConferido)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _abrirModalResolucao(DivergenciaItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final corFundo = isDark ? AppTokens.brancoEscuro : AppTokens.branco;
    final corTexto = isDark ? AppTokens.grafiteEscuro : AppTokens.grafite;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: corFundo,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.raioFolha)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('RESOLVER DIVERGÊNCIA', style: AppTokens.tituloSecao.copyWith(color: corTexto)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Plaqueta(numero: item.tombamento),
              const SizedBox(height: 12),
              Text(
                item.descricao,
                style: TextStyle(fontFamily: AppTokens.fonteTitulo, fontSize: 16, color: corTexto),
              ),
              const SizedBox(height: 16),
              Text(
                'Selecione a decisão fundamentada:',
                style: TextStyle(fontFamily: AppTokens.fontePadrao, fontSize: 13, color: AppTokens.cinza),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle, color: AppTokens.statusConferido),
                title: const Text('Confirmar localização encontrada', style: TextStyle(fontFamily: AppTokens.fontePadrao)),
                subtitle: Text('Atualiza carga para ${item.localEncontradoNome ?? "local lido"}'),
                onTap: () {
                  Navigator.pop(ctx);
                  _executarResolucao(
                    item,
                    decisao: 'Transferência homologada para ${item.localEncontradoNome}',
                    justificativa: 'Verificado fisicamente no local de destino.',
                    novoLocalId: item.localEncontradoId,
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.search, color: AppTokens.tinta),
                title: const Text('Reabrir diligência / Nova busca', style: TextStyle(fontFamily: AppTokens.fontePadrao)),
                subtitle: const Text('Mantém pendente aguardando conferência adicional'),
                onTap: () {
                  Navigator.pop(ctx);
                  _executarResolucao(
                    item,
                    decisao: 'Diligência reaberta para busca suplementar',
                    justificativa: 'Solicitada varredura nas salas contíguas.',
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.warning, color: AppTokens.statusSemCadastro),
                title: const Text('Confirmar bem como não localizado', style: TextStyle(fontFamily: AppTokens.fontePadrao)),
                subtitle: const Text('Encaminha para procedimento de extravio/baixa'),
                onTap: () {
                  Navigator.pop(ctx);
                  _executarResolucao(
                    item,
                    decisao: 'Extravio registrado',
                    justificativa: 'Bem ausente da unidade após conferência minuciosa.',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _executarResolucao(
    DivergenciaItem item, {
    required String decisao,
    required String justificativa,
    String? novoLocalId,
  }) async {
    final db = ref.read(databaseProvider);
    try {
      final idAparelho = await IdentidadeService.obterOuCriarIdentidade();
      final keyPair = idAparelho.keyPair;
      if (keyPair == null) {
        throw Exception('Chave privada do gestor não encontrada.');
      }

      await DivergenciaService.resolverDivergencia(
        db: db,
        unidadeId: 'unidade_demo',
        tombamento: item.tombamento,
        decisao: decisao,
        justificativa: justificativa,
        novoLocalId: novoLocalId,
        keyPairGestor: keyPair,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Divergência de ${item.tombamento} resolvida com sucesso!'),
            backgroundColor: AppTokens.statusConferido,
          ),
        );
        ref.invalidate(divergenciasProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao resolver divergência: $e'),
            backgroundColor: AppTokens.statusSemCadastro,
          ),
        );
      }
    }
  }

  Future<void> _resolverTodasSalasDivergentes(List<DivergenciaItem> pendentes) async {
    final salasIncorretas = pendentes
        .where((d) => d.tipo == TipoDivergencia.salaIncorreta)
        .toList();

    if (salasIncorretas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma divergência de sala incorreta pendente.')),
      );
      return;
    }

    final db = ref.read(databaseProvider);
    try {
      final idAparelho = await IdentidadeService.obterOuCriarIdentidade();
      final keyPair = idAparelho.keyPair;
      if (keyPair == null) throw Exception('Chave privada indisponível.');

      await DivergenciaService.resolverEmLote(
        db: db,
        unidadeId: 'unidade_demo',
        itens: salasIncorretas,
        decisao: 'Transferência para nova sala homologada em lote',
        justificativa: 'Aprovação expressa do Gestor Patrimonial.',
        keyPairGestor: keyPair,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${salasIncorretas.length} transferências homologadas em lote!'),
            backgroundColor: AppTokens.statusConferido,
          ),
        );
        ref.invalidate(divergenciasProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao resolver em lote: $e'),
            backgroundColor: AppTokens.statusSemCadastro,
          ),
        );
      }
    }
  }
}
