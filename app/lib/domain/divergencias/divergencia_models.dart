enum TipoDivergencia {
  naoLocalizado,
  salaIncorreta,
  semCadastro,
  conflitoConferentes,
  estadoDivergente;

  String get rotulo {
    switch (this) {
      case TipoDivergencia.naoLocalizado:
        return 'Não localizado';
      case TipoDivergencia.salaIncorreta:
        return 'Sala divergente';
      case TipoDivergencia.semCadastro:
        return 'Sem cadastro prévio';
      case TipoDivergencia.conflitoConferentes:
        return 'Conflito de conferência';
      case TipoDivergencia.estadoDivergente:
        return 'Estado divergente';
    }
  }
}

/// Evidências e dados concorrentes entre dois conferentes independentes
class ConflitoLadoALado {
  final String conferenteA;
  final DateTime dataA;
  final String salaA;
  final String? estadoA;
  final String? hashFotoA;

  final String conferenteB;
  final DateTime dataB;
  final String salaB;
  final String? estadoB;
  final String? hashFotoB;

  const ConflitoLadoALado({
    required this.conferenteA,
    required this.dataA,
    required this.salaA,
    this.estadoA,
    this.hashFotoA,
    required this.conferenteB,
    required this.dataB,
    required this.salaB,
    this.estadoB,
    this.hashFotoB,
  });
}

/// Representa um item na fila de divergências com diagnóstico e recomendação
class DivergenciaItem {
  final String id;
  final String tombamento;
  final String descricao;
  final TipoDivergencia tipo;
  final String localEsperadoId;
  final String localEsperadoNome;
  final String? localEncontradoId;
  final String? localEncontradoNome;
  final String causaProvavel;
  final String proximoPasso;
  final ConflitoLadoALado? conflito;
  final bool resolvida;
  final String? resolucao;
  final DateTime dataCriacao;

  const DivergenciaItem({
    required this.id,
    required this.tombamento,
    required this.descricao,
    required this.tipo,
    required this.localEsperadoId,
    required this.localEsperadoNome,
    this.localEncontradoId,
    this.localEncontradoNome,
    required this.causaProvavel,
    required this.proximoPasso,
    this.conflito,
    this.resolvida = false,
    this.resolucao,
    required this.dataCriacao,
  });

  DivergenciaItem copyWith({
    bool? resolvida,
    String? resolucao,
  }) {
    return DivergenciaItem(
      id: id,
      tombamento: tombamento,
      descricao: descricao,
      tipo: tipo,
      localEsperadoId: localEsperadoId,
      localEsperadoNome: localEsperadoNome,
      localEncontradoId: localEncontradoId,
      localEncontradoNome: localEncontradoNome,
      causaProvavel: causaProvavel,
      proximoPasso: proximoPasso,
      conflito: conflito,
      resolvida: resolvida ?? this.resolvida,
      resolucao: resolucao ?? this.resolucao,
      dataCriacao: dataCriacao,
    );
  }
}
