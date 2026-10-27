/// Funções puras de normalização de tombamento e nomes de sala
class Normalizacao {
  /// Remove acentos de uma string
  static String removerAcentos(String texto) {
    const comAcento = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÿÑñ';
    const semAcento = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuyNn';
    String resultado = texto;
    for (int i = 0; i < comAcento.length; i++) {
      resultado = resultado.replaceAll(comAcento[i], semAcento[i]);
    }
    return resultado;
  }

  /// Normaliza o número de tombamento:
  /// - remove espaços, pontos e hífens
  /// - troca letra 'O' por '0' quando o restante da string for numérico
  /// - preserva zeros à esquerda
  static String normalizarTombamento(String entrada) {
    if (entrada.isEmpty) return '';

    // Remove espaços, pontos, barras e hífens
    String limpo = entrada
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[\s\.\-\/\\]'), '');

    if (limpo.isEmpty) return '';

    // Se possui a letra O, verifica se substituindo O por 0 vira puramente numérico
    if (limpo.contains('O')) {
      final candidato = limpo.replaceAll('O', '0');
      if (RegExp(r'^\d+$').hasMatch(candidato)) {
        return candidato;
      }
    }

    return limpo;
  }

  /// Normaliza nome de sala para chave de comparação:
  /// "Sala 3", "SL 03", "sala03" -> "sala 3"
  static String normalizarNomeSala(String nomeSala) {
    String limpo = removerAcentos(nomeSala).trim().toLowerCase();

    // Substitui SL, SL., SALA por "sala "
    limpo = limpo.replaceAll(RegExp(r'^(sl\.?|sala)\s*'), 'sala ');

    // Normaliza números com zero à esquerda na sala: "sala 03" -> "sala 3"
    limpo = limpo.replaceAllMapped(RegExp(r'sala\s+0*(\d+)'), (match) {
      return 'sala ${match.group(1)}';
    });

    // Remove espaços extras
    limpo = limpo.replaceAll(RegExp(r'\s+'), ' ').trim();
    return limpo;
  }

  /// Divide o caminho do local e extrai os níveis:
  /// "Comarca de Breves / Fórum Juiz Vicente / Térreo / Sala 101 - Protocolo"
  static List<String> extrairNiveisLocal(String caminhoCompleto) {
    return caminhoCompleto
        .split('/')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }
}
