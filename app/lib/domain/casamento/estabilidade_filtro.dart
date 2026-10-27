import 'casamento_models.dart';

class CaixaVisivel {
  final String tombamento;
  RectDeteccao caixa;
  final ClassificacaoPlaqueta classificacao;
  final bool isProvavel;
  DateTime ultimoVisto;

  CaixaVisivel({
    required this.tombamento,
    required this.caixa,
    required this.classificacao,
    required this.isProvavel,
    required this.ultimoVisto,
  });

  void atualizarCaixa(RectDeteccao novaCaixa, DateTime agora) {
    caixa = caixa.lerp(novaCaixa, 0.6);
    ultimoVisto = agora;
  }
}

class EstabilidadeFiltro {
  final Map<String, List<DateTime>> _historicoQuadros = {};
  final Map<String, RectDeteccao> _caixaAnterior = {};
  final Map<String, CaixaVisivel> _caixasAtivas = {};
  final Set<String> _confirmadosNaSessao = {};

  /// Registra tombamento já confirmado na sessão para não reprocessar
  void marcarConfirmado(String tombamento) {
    _confirmadosNaSessao.add(tombamento);
  }

  bool isJaConfirmado(String tombamento) {
    return _confirmadosNaSessao.contains(tombamento);
  }

  /// Processa uma detecção e retorna se atingiu estabilidade (>= 2 quadros em 1s)
  bool registrarDeteccao({
    required String tombamento,
    required RectDeteccao? caixa,
    required ClassificacaoPlaqueta classificacao,
    required bool isProvavel,
    DateTime? timestamp,
  }) {
    final agora = timestamp ?? DateTime.now();

    // Suaviza posição em relação ao quadro anterior
    RectDeteccao? caixaSuave = caixa;
    if (caixa != null) {
      if (_caixaAnterior.containsKey(tombamento)) {
        caixaSuave = _caixaAnterior[tombamento]!.lerp(caixa, 0.6);
      }
      _caixaAnterior[tombamento] = caixaSuave!;
    }

    // Limpa histórico com mais de 1 segundo
    final lista = _historicoQuadros.putIfAbsent(tombamento, () => []);
    lista.add(agora);
    lista.removeWhere((t) => agora.difference(t).inMilliseconds > 1000);

    final atingiuEstabilidade = lista.length >= 2;

    if (atingiuEstabilidade && caixaSuave != null) {
      if (_caixasAtivas.containsKey(tombamento)) {
        _caixasAtivas[tombamento]!.caixa = caixaSuave;
        _caixasAtivas[tombamento]!.ultimoVisto = agora;
      } else {
        _caixasAtivas[tombamento] = CaixaVisivel(
          tombamento: tombamento,
          caixa: caixaSuave,
          classificacao: classificacao,
          isProvavel: isProvavel,
          ultimoVisto: agora,
        );
      }
    }

    return atingiuEstabilidade;
  }

  /// Retorna as caixas visíveis ativas, removendo as que sumiram há mais de 1.5s
  List<CaixaVisivel> obterCaixasAtivas({DateTime? timestamp}) {
    final agora = timestamp ?? DateTime.now();
    _caixasAtivas.removeWhere((_, c) =>
        agora.difference(c.ultimoVisto).inMilliseconds > 1500);
    return _caixasAtivas.values.toList();
  }

  void limparSessao() {
    _historicoQuadros.clear();
    _caixaAnterior.clear();
    _caixasAtivas.clear();
    _confirmadosNaSessao.clear();
  }
}
