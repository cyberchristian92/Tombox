/// Status formal de homologação de uma sala ou setor
class StatusHomologacaoSala {
  final String salaId;
  final String salaNome;
  final String caminhoCompleto;
  final bool homologada;
  final DateTime? dataHomologacao;
  final String? homologadoPor;
  final int totalBens;
  final int bensConferidos;
  final int divergenciasPendentes;
  final String? observacao;

  const StatusHomologacaoSala({
    required this.salaId,
    required this.salaNome,
    required this.caminhoCompleto,
    required this.homologada,
    this.dataHomologacao,
    this.homologadoPor,
    required this.totalBens,
    required this.bensConferidos,
    required this.divergenciasPendentes,
    this.observacao,
  });

  bool get podeHomologar => !homologada && divergenciasPendentes == 0 && bensConferidos > 0;
}
