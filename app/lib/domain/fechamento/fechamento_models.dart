import 'dart:typed_data';

/// Resumo dos dados e contagens de uma sala para emissão do termo de responsabilidade
class ResumoFechamentoSala {
  final String salaId;
  final String salaNome;
  final String unidadeId;
  final String unidadeNome;
  final int totalEsperados;
  final int totalConferidos;
  final int totalNaoEncontrados;
  final int totalOutraSala;
  final int totalSemCadastro;
  final int totalDivergencias;
  final List<ItemTermoBem> bens;
  final String hashUltimoEvento;

  const ResumoFechamentoSala({
    required this.salaId,
    required this.salaNome,
    required this.unidadeId,
    required this.unidadeNome,
    required this.totalEsperados,
    required this.totalConferidos,
    required this.totalNaoEncontrados,
    required this.totalOutraSala,
    required this.totalSemCadastro,
    required this.totalDivergencias,
    required this.bens,
    required this.hashUltimoEvento,
  });

  double get taxaConferencia =>
      totalEsperados > 0 ? (totalConferidos / totalEsperados) * 100 : 0.0;
}

/// Item patrimonial listado no termo de responsabilidade
class ItemTermoBem {
  final String tombamento;
  final String descricao;
  final String categoria;
  final String situacao; // conferido, pendente, outra_sala, sem_cadastro
  final String estadoConservacao;
  final String? fotoHash;

  const ItemTermoBem({
    required this.tombamento,
    required this.descricao,
    required this.categoria,
    required this.situacao,
    this.estadoConservacao = 'BOM',
    this.fotoHash,
  });
}

/// Dados completos para a emissão do termo assinado
class DadosTermoResponsabilidade {
  final ResumoFechamentoSala resumo;
  final String responsavelNome;
  final String responsavelMatricula;
  final String responsavelCargo;
  final String conferenteNome;
  final String conferenteMatricula;
  final String chaveConferente;
  final DateTime dataHora;
  final Uint8List assinaturaBytes; // PNG da assinatura capturada no canvas

  const DadosTermoResponsabilidade({
    required this.resumo,
    required this.responsavelNome,
    required this.responsavelMatricula,
    required this.responsavelCargo,
    required this.conferenteNome,
    required this.conferenteMatricula,
    required this.chaveConferente,
    required this.dataHora,
    required this.assinaturaBytes,
  });
}

/// Resultado da geração e fechamento com termo
class ResultadoFechamento {
  final Uint8List pdfBytes;
  final String pdfHash; // SHA-256 do arquivo PDF
  final String eventoFechamentoId;
  final String eventoTermoId;
  final DateTime dataHora;

  const ResultadoFechamento({
    required this.pdfBytes,
    required this.pdfHash,
    required this.eventoFechamentoId,
    required this.eventoTermoId,
    required this.dataHora,
  });
}
