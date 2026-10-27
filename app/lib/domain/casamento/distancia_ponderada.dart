/// Cálculo de distância de Levenshtein ponderada com pares confundíveis (OCR)
class DistanciaPonderada {
  static const Set<String> _pares = {
    '0O', 'O0',
    '1I', 'I1',
    '1L', 'L1',
    'IL', 'LI',
    '8B', 'B8',
    '5S', 'S5',
    '2Z', 'Z2',
    '6G', 'G6',
  };

  /// Verifica se dois caracteres formam um par confundível bidirecional
  static bool saoConfundiveis(String c1, String c2) {
    if (c1 == c2) return false;
    final u1 = c1.toUpperCase();
    final u2 = c2.toUpperCase();
    return _pares.contains('$u1$u2');
  }

  /// Calcula a distância de Levenshtein ponderada:
  /// - Caracteres iguais: custo 0.0
  /// - Par confundível: custo 0.3
  /// - Outra substituição: custo 1.0
  /// - Inserção / Deleção: custo 1.0
  static double calcular(String s1, String s2) {
    final m = s1.length;
    final n = s2.length;
    if (m == 0) return n * 1.0;
    if (n == 0) return m * 1.0;

    final dp = List.generate(m + 1, (_) => List<double>.filled(n + 1, 0.0));

    for (int i = 0; i <= m; i++) {
      dp[i][0] = i * 1.0;
    }
    for (int j = 0; j <= n; j++) {
      dp[0][j] = j * 1.0;
    }

    for (int i = 1; i <= m; i++) {
      final c1 = s1[i - 1];
      for (int j = 1; j <= n; j++) {
        final c2 = s2[j - 1];
        double custoSubstituicao;
        if (c1 == c2) {
          custoSubstituicao = 0.0;
        } else if (saoConfundiveis(c1, c2)) {
          custoSubstituicao = 0.3;
        } else {
          custoSubstituicao = 1.0;
        }

        final delecao = dp[i - 1][j] + 1.0;
        final insercao = dp[i][j - 1] + 1.0;
        final substituicao = dp[i - 1][j - 1] + custoSubstituicao;

        double menor = delecao;
        if (insercao < menor) menor = insercao;
        if (substituicao < menor) menor = substituicao;

        dp[i][j] = menor;
      }
    }

    // Arredonda para 2 casas decimais para evitar imprecisões de ponto flutuante
    return (dp[m][n] * 100).round() / 100.0;
  }
}
