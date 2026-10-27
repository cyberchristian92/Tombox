class ItemRelatorio {
  final int linha;
  final String tipo; // AVISO ou ERRO
  final String mensagem;
  final String? tombamento;

  const ItemRelatorio({
    required this.linha,
    required this.tipo,
    required this.mensagem,
    this.tombamento,
  });
}

class RelatorioImportacao {
  final String unidadeId;
  final String unidadeNome;
  final String arquivoOrigem;
  final int totalLinhasLidas;
  final int bensValidos;
  final int totalSalas;
  final int duplicadosAtualizados;
  final String separadorDetectado;
  final String codificacaoDetectada;
  final List<ItemRelatorio> itens;

  const RelatorioImportacao({
    required this.unidadeId,
    required this.unidadeNome,
    required this.arquivoOrigem,
    required this.totalLinhasLidas,
    required this.bensValidos,
    required this.totalSalas,
    required this.duplicadosAtualizados,
    required this.separadorDetectado,
    required this.codificacaoDetectada,
    required this.itens,
  });

  List<ItemRelatorio> get avisos =>
      itens.where((i) => i.tipo == 'AVISO').toList();

  List<ItemRelatorio> get erros =>
      itens.where((i) => i.tipo == 'ERRO').toList();

  bool get temErros => erros.isNotEmpty;
  bool get temAvisos => avisos.isNotEmpty;
}
