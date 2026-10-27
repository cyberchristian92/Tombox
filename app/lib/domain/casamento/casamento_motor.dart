import 'casamento_models.dart';
import 'distancia_ponderada.dart';

class CasamentoMotor {
  final Set<String> tombamentosSala;
  final Set<String> tombamentosUnidade;
  final int minTamanho;
  final int maxTamanho;

  CasamentoMotor({
    required Set<String> bensSala,
    required Set<String> todosBensUnidade,
  })  : tombamentosSala = bensSala,
        tombamentosUnidade = todosBensUnidade,
        minTamanho = _calcularMinTamanho(todosBensUnidade),
        maxTamanho = _calcularMaxTamanho(todosBensUnidade);

  static int _calcularMinTamanho(Set<String> bens) {
    if (bens.isEmpty) return 4;
    return bens.map((b) => b.length).reduce((a, b) => a < b ? a : b);
  }

  static int _calcularMaxTamanho(Set<String> bens) {
    if (bens.isEmpty) return 10;
    return bens.map((b) => b.length).reduce((a, b) => a > b ? a : b);
  }

  /// 1. Normaliza o texto lido pelo OCR com trocas confundíveis
  static String normalizarTextoOcr(String entrada) {
    if (entrada.isEmpty) return '';

    // Maiúsculas, remove espaços, pontos e hífens
    String texto = entrada
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[\s\.\-\/\\]'), '');

    if (texto.isEmpty) return '';

    // Contagem de dígitos e caracteres substituíveis (O, I, L, B, S, Z, G)
    int countNumericosOuSubstituiveis = 0;
    for (int i = 0; i < texto.length; i++) {
      final c = texto[i];
      if (RegExp(r'[0-9OILBSZG]').hasMatch(c)) {
        countNumericosOuSubstituiveis++;
      }
    }

    // Se a sequência for majoritariamente numérica (>= 50%)
    if (countNumericosOuSubstituiveis / texto.length >= 0.5) {
      final buffer = StringBuffer();
      for (int i = 0; i < texto.length; i++) {
        final c = texto[i];
        switch (c) {
          case 'O':
            buffer.write('0');
            break;
          case 'I':
          case 'L':
            buffer.write('1');
            break;
          case 'B':
            buffer.write('8');
            break;
          case 'S':
            buffer.write('5');
            break;
          case 'Z':
            buffer.write('2');
            break;
          case 'G':
            buffer.write('6');
            break;
          default:
            buffer.write(c);
        }
      }
      return buffer.toString();
    }

    return texto;
  }

  /// 2. Filtra candidatos pelo tamanho (com folga de 1) e proporção de dígitos (>= 60%)
  bool validarCandidato(String token) {
    if (token.isEmpty) return false;

    // Tamanho com folga de 1
    final folgaMin = minTamanho > 1 ? minTamanho - 1 : 1;
    final folgaMax = maxTamanho + 1;

    if (token.length < folgaMin || token.length > folgaMax) {
      return false;
    }

    // Pelo menos 60% de dígitos
    int digitos = 0;
    for (int i = 0; i < token.length; i++) {
      if (RegExp(r'[0-9]').hasMatch(token[i])) {
        digitos++;
      }
    }

    return (digitos / token.length) >= 0.60;
  }

  /// Processa a leitura de um Código de Barras ou QR Code
  ResultadoCasamento avaliarCodigoBarras(
    String codigoLido, {
    RectDeteccao? caixa,
  }) {
    final limpo = normalizarTextoOcr(codigoLido);

    if (tombamentosSala.contains(limpo)) {
      return ResultadoCasamento(
        textoLido: codigoLido,
        textoNormalizado: limpo,
        tombamentoIdentificado: limpo,
        decisao: DecisaoLeitura.confirmado,
        classificacao: ClassificacaoPlaqueta.verde,
        menorDistancia: 0.0,
        caixa: caixa,
        isCodigoBarras: true,
      );
    }

    if (tombamentosUnidade.contains(limpo)) {
      return ResultadoCasamento(
        textoLido: codigoLido,
        textoNormalizado: limpo,
        tombamentoIdentificado: limpo,
        decisao: DecisaoLeitura.confirmado,
        classificacao: ClassificacaoPlaqueta.amarelo,
        menorDistancia: 0.0,
        caixa: caixa,
        isCodigoBarras: true,
      );
    }

    // Correção: só classificar como vermelho quando o valor normalizado
    // tiver formato de tombamento (validarCandidato).
    // EAN-13, QR com URLs ou códigos de produto são descartados / ignorados.
    if (validarCandidato(limpo)) {
      return ResultadoCasamento(
        textoLido: codigoLido,
        textoNormalizado: limpo,
        tombamentoIdentificado: limpo,
        decisao: DecisaoLeitura.confirmado,
        classificacao: ClassificacaoPlaqueta.vermelho,
        menorDistancia: null,
        caixa: caixa,
        isCodigoBarras: true,
      );
    }

    return ResultadoCasamento(
      textoLido: codigoLido,
      textoNormalizado: limpo,
      decisao: DecisaoLeitura.descartado,
      caixa: caixa,
      isCodigoBarras: true,
    );
  }

  /// Extrai candidatos a número de plaqueta de uma linha de texto.
  /// Suporta plaquetas com texto junto (ex: "PATRIMÔNIO 010001", "TJPA Nº 010.001",
  /// "ESTADO DO PARÁ 0100O1", "Nº 010-001"), descartando linhas puramente de texto
  /// e separando múltiplos números distintos se presentes na mesma linha.
  List<String> extrairCandidatosDeTexto(String linha) {
    if (linha.trim().isEmpty) return const [];

    final encontrados = <String>{};

    // 1. Sequências numéricas ou com trocas confundíveis e separadores (. - / ou espaço)
    final regexSequencias = RegExp(
      r'[0-9OILBSZG][0-9OILBSZG.\- ]{1,}[0-9OILBSZG]',
      caseSensitive: false,
    );

    for (final match in regexSequencias.allMatches(linha)) {
      final seq = match.group(0)!;
      final norm = normalizarTextoOcr(seq);
      if (validarCandidato(norm)) {
        encontrados.add(norm);
      }
    }

    // 2. Palavras individuais da linha
    final palavras = linha.split(RegExp(r'\s+'));
    for (final p in palavras) {
      final limpa = p.replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '');
      if (limpa.isNotEmpty) {
        final norm = normalizarTextoOcr(limpa);
        if (validarCandidato(norm)) {
          encontrados.add(norm);
        }
      }
    }

    return encontrados.toList();
  }

  /// Avalia todos os candidatos encontrados em uma linha completa
  List<ResultadoCasamento> avaliarLinhaCompleta(
    String linhaTexto, {
    RectDeteccao? caixa,
  }) {
    final candidatos = extrairCandidatosDeTexto(linhaTexto);
    if (candidatos.isEmpty) return const [];

    final resultados = <ResultadoCasamento>[];
    for (final cand in candidatos) {
      final res = _avaliarTokenNormalizado(linhaTexto, cand, caixa: caixa);
      if (!res.isDescartado) {
        resultados.add(res);
      }
    }
    return resultados;
  }

  /// Processa a leitura de texto pelo OCR
  ResultadoCasamento avaliarTextoOcr(
    String textoLido, {
    RectDeteccao? caixa,
  }) {
    // Se o texto contiver espaços ou múltiplas palavras, extrai candidatos
    final candidatos = extrairCandidatosDeTexto(textoLido);
    if (candidatos.isNotEmpty) {
      ResultadoCasamento? melhor;
      for (final cand in candidatos) {
        final res = _avaliarTokenNormalizado(textoLido, cand, caixa: caixa);
        if (res.isConfirmado) return res;
        if (melhor == null || (res.isProvavel && !melhor.isProvavel)) {
          melhor = res;
        }
      }
      return melhor ??
          ResultadoCasamento(
            textoLido: textoLido,
            textoNormalizado: candidatos.first,
            decisao: DecisaoLeitura.descartado,
            caixa: caixa,
          );
    }

    // Se não encontrou candidatos via extração, avalia o token diretamente
    final normalizado = normalizarTextoOcr(textoLido);
    if (!validarCandidato(normalizado)) {
      return ResultadoCasamento(
        textoLido: textoLido,
        textoNormalizado: normalizado,
        decisao: DecisaoLeitura.descartado,
        caixa: caixa,
      );
    }

    return _avaliarTokenNormalizado(textoLido, normalizado, caixa: caixa);
  }

  /// Avalia um token já normalizado e validado
  ResultadoCasamento _avaliarTokenNormalizado(
    String textoLido,
    String normalizado, {
    RectDeteccao? caixa,
  }) {
    // 1. Busca exata (Distância 0.0)
    // 1.1 Primeiro na sala esperada
    if (tombamentosSala.contains(normalizado)) {
      return ResultadoCasamento(
        textoLido: textoLido,
        textoNormalizado: normalizado,
        tombamentoIdentificado: normalizado,
        decisao: DecisaoLeitura.confirmado,
        classificacao: ClassificacaoPlaqueta.verde,
        menorDistancia: 0.0,
        caixa: caixa,
      );
    }

    // 1.2 Depois no restante da unidade
    if (tombamentosUnidade.contains(normalizado)) {
      return ResultadoCasamento(
        textoLido: textoLido,
        textoNormalizado: normalizado,
        tombamentoIdentificado: normalizado,
        decisao: DecisaoLeitura.confirmado,
        classificacao: ClassificacaoPlaqueta.amarelo,
        menorDistancia: 0.0,
        caixa: caixa,
      );
    }

    // 2. Busca por Distância Ponderada
    final candidatos = <CandidatoMatch>[];

    // Avalia sala
    for (final tomb in tombamentosSala) {
      final dist = DistanciaPonderada.calcular(normalizado, tomb);
      if (dist <= 1.0) {
        candidatos.add(CandidatoMatch(tombamento: tomb, distancia: dist, daSala: true));
      }
    }

    // Avalia restante da unidade
    for (final tomb in tombamentosUnidade) {
      if (!tombamentosSala.contains(tomb)) {
        final dist = DistanciaPonderada.calcular(normalizado, tomb);
        if (dist <= 1.0) {
          candidatos.add(CandidatoMatch(tombamento: tomb, distancia: dist, daSala: false));
        }
      }
    }

    if (candidatos.isEmpty) {
      return ResultadoCasamento(
        textoLido: textoLido,
        textoNormalizado: normalizado,
        decisao: DecisaoLeitura.descartado,
        caixa: caixa,
      );
    }

    // Ordena por distância crescente, priorizando sala em empate
    candidatos.sort((a, b) {
      final comp = a.distancia.compareTo(b.distancia);
      if (comp != 0) return comp;
      if (a.daSala && !b.daSala) return -1;
      if (!a.daSala && b.daSala) return 1;
      return 0;
    });

    final melhor = candidatos.first;

    if (candidatos.length > 1) {
      final segundo = candidatos[1];
      final vantagem = (segundo.distancia - melhor.distancia);

      if (vantagem < 0.5) {
        return ResultadoCasamento(
          textoLido: textoLido,
          textoNormalizado: normalizado,
          decisao: DecisaoLeitura.descartado,
          menorDistancia: melhor.distancia,
          caixa: caixa,
        );
      }
    }

    final classificacao = melhor.daSala
        ? ClassificacaoPlaqueta.verde
        : ClassificacaoPlaqueta.amarelo;

    return ResultadoCasamento(
      textoLido: textoLido,
      textoNormalizado: normalizado,
      tombamentoIdentificado: melhor.tombamento,
      decisao: DecisaoLeitura.provavel,
      classificacao: classificacao,
      menorDistancia: melhor.distancia,
      caixa: caixa,
    );
  }
}

