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

  /// Extrai o número da sala se existir (ex: "Sala 102 - Secretaria" -> "102", "SL 03" -> "3", "Sala103" -> "103")
  static String? extrairNumeroSala(String nomeSala) {
    final limpo = normalizarNomeSala(nomeSala);
    final match = RegExp(r'sala\s+(\d+)').firstMatch(limpo);
    return match?.group(1);
  }

  /// Verifica se o nome da sala é apenas uma variação de número (ex: "sala 102", "SL 102", "Sala103", "102") sem descrição adicional
  static bool ehApenasNumero(String nomeSala) {
    final limpo = normalizarNomeSala(nomeSala);
    return RegExp(r'^sala\s+\d+$').hasMatch(limpo) || RegExp(r'^\d+$').hasMatch(limpo);
  }

  /// Resolve variações de nomes de salas sob o mesmo local pai (prédio + andar):
  /// - Une variações do mesmo nome (ex: "Sala 102 - Secretaria" e "sala 102 - secretaria")
  /// - Une variações puramente numéricas ("sala 102", "SL 102", "Sala102") à sala daquele número no mesmo prédio e andar, se existir apenas uma
  /// - Retorna um mapa de: nomeRaw -> nomeCanonico
  static Map<String, String> resolverSalasPorPai(Iterable<String> nomesRaw) {
    final resultado = <String, String>{};
    if (nomesRaw.isEmpty) return resultado;

    // 1. Agrupa por chave normalizada completa
    final gruposPorChave = <String, List<String>>{};
    for (final raw in nomesRaw) {
      final chave = normalizarNomeSala(raw);
      gruposPorChave.putIfAbsent(chave, () => []).add(raw);
    }

    // 2. Determina o melhor nome de exibição para cada grupo normalizado
    final melhorNomePorChave = <String, String>{};
    for (final entry in gruposPorChave.entries) {
      final lista = entry.value;
      // Escolhe o nome mais bem formatado (preferindo com hífen/descrição, maiúsculas)
      lista.sort((a, b) {
        final aTemHifen = a.contains('-') ? 1 : 0;
        final bTemHifen = b.contains('-') ? 1 : 0;
        if (aTemHifen != bTemHifen) return bTemHifen.compareTo(aTemHifen);
        return b.length.compareTo(a.length);
      });
      melhorNomePorChave[entry.key] = lista.first;
    }

    // 3. Identifica salas com descrição e salas que são apenas número
    final salasComDescricaoPorNumero = <String, List<String>>{}; // numero -> [chaveNormalizada]
    final chavesApenasNumero = <String>{};

    for (final chave in gruposPorChave.keys) {
      final num = extrairNumeroSala(chave);
      if (num != null) {
        if (ehApenasNumero(chave)) {
          chavesApenasNumero.add(chave);
        } else {
          salasComDescricaoPorNumero.putIfAbsent(num, () => []).add(chave);
        }
      }
    }

    // 4. Mapeia cada chave normalizada para sua chave canônica final
    final chaveParaCanonico = <String, String>{};
    for (final chave in gruposPorChave.keys) {
      if (chavesApenasNumero.contains(chave)) {
        final num = extrairNumeroSala(chave);
        final candidatas = num != null ? salasComDescricaoPorNumero[num] : null;
        if (candidatas != null && candidatas.length == 1) {
          // Existe exatamente uma sala descritiva com esse número no andar: une a ela!
          chaveParaCanonico[chave] = melhorNomePorChave[candidatas.first]!;
        } else {
          // Mantém a representação padronizada
          chaveParaCanonico[chave] = melhorNomePorChave[chave]!;
        }
      } else {
        chaveParaCanonico[chave] = melhorNomePorChave[chave]!;
      }
    }

    // 5. Preenche o mapa final de raw -> canonico
    for (final raw in nomesRaw) {
      final chave = normalizarNomeSala(raw);
      resultado[raw] = chaveParaCanonico[chave] ?? melhorNomePorChave[chave] ?? raw;
    }

    return resultado;
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

