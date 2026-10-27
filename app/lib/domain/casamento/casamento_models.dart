/// Modelos puros do módulo de casamento (sem dependência de Flutter)
library;

enum DecisaoLeitura {
  confirmado,
  provavel,
  descartado,
}

enum ClassificacaoPlaqueta {
  verde,    // Bem esperado nesta sala
  amarelo,  // Bem da unidade, mas esperado em outra sala
  vermelho, // Código lido com confiança que não existe na unidade
}

class RectDeteccao {
  final double left;
  final double top;
  final double width;
  final double height;

  const RectDeteccao({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  double get right => left + width;
  double get bottom => top + height;

  RectDeteccao lerp(RectDeteccao outro, double t) {
    return RectDeteccao(
      left: left + (outro.left - left) * t,
      top: top + (outro.top - top) * t,
      width: width + (outro.width - width) * t,
      height: height + (outro.height - height) * t,
    );
  }
}

class CandidatoMatch {
  final String tombamento;
  final double distancia;
  final bool daSala;

  const CandidatoMatch({
    required this.tombamento,
    required this.distancia,
    required this.daSala,
  });
}

class ResultadoCasamento {
  final String textoLido;
  final String textoNormalizado;
  final String? tombamentoIdentificado;
  final DecisaoLeitura decisao;
  final ClassificacaoPlaqueta? classificacao;
  final double? menorDistancia;
  final RectDeteccao? caixa;
  final bool isCodigoBarras;

  const ResultadoCasamento({
    required this.textoLido,
    required this.textoNormalizado,
    this.tombamentoIdentificado,
    required this.decisao,
    this.classificacao,
    this.menorDistancia,
    this.caixa,
    this.isCodigoBarras = false,
  });

  bool get isConfirmado => decisao == DecisaoLeitura.confirmado;
  bool get isProvavel => decisao == DecisaoLeitura.provavel;
  bool get isDescartado => decisao == DecisaoLeitura.descartado;
}
