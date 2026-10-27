import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/app_database.dart';
import 'normalizacao.dart';
import 'relatorio_importacao.dart';

class DadosParseados {
  final UnidadesCompanion unidade;
  final List<LocaisCompanion> locais;
  final List<BensCompanion> bens;
  final List<ConferenciaSalasCompanion> salas;
  final RelatorioImportacao relatorio;

  const DadosParseados({
    required this.unidade,
    required this.locais,
    required this.bens,
    required this.salas,
    required this.relatorio,
  });
}

class CsvImporter {
  static const _uuid = Uuid();

  /// Detecta a codificação e decodifica os bytes para String
  static (String, String) decodificarBytes(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      try {
        final texto = utf8.decode(bytes.sublist(3));
        return (texto, 'UTF-8 (com BOM)');
      } catch (_) {}
    }

    try {
      final texto = utf8.decode(bytes);
      return (texto, 'UTF-8');
    } catch (_) {
      final texto = latin1.decode(bytes);
      return (texto, 'Windows-1252 / Latin-1');
    }
  }

  /// Detecta o separador com base nas primeiras linhas
  static String detectarSeparador(String conteudo) {
    final primeiraLinha = conteudo.split(RegExp(r'\r?\n')).firstWhere(
          (linha) => linha.trim().isNotEmpty,
          orElse: () => '',
        );

    final contPontoVirgula = ';'.allMatches(primeiraLinha).length;
    final contVirgula = ','.allMatches(primeiraLinha).length;
    final contTab = '\t'.allMatches(primeiraLinha).length;

    if (contTab > contPontoVirgula && contTab > contVirgula) {
      return '\t';
    }
    if (contPontoVirgula >= contVirgula) {
      return ';';
    }
    return ',';
  }

  /// Mapeia o nome do cabeçalho para o campo canônico
  static String? mapearCabecalho(String cabecalhoOriginal) {
    final limpo = Normalizacao.removerAcentos(cabecalhoOriginal)
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    if (limpo.contains('tombamento') ||
        limpo == 'patrimonio' ||
        limpo == 'plaqueta' ||
        limpo == 'ativo' ||
        limpo == 'ntombamento') {
      return 'tombamento';
    }
    if (limpo.contains('descricao') ||
        limpo == 'especificacao' ||
        limpo == 'objeto' ||
        limpo == 'bem' ||
        limpo == 'item') {
      return 'descricao';
    }
    if (limpo.contains('local') ||
        limpo.contains('localizacao') ||
        limpo == 'sala' ||
        limpo == 'lotacao') {
      return 'local';
    }
    if (limpo.contains('categoria') || limpo == 'classe' || limpo == 'grupo') {
      return 'categoria';
    }
    if (limpo.contains('responsavel') ||
        limpo.contains('matricula') ||
        limpo == 'servidor') {
      return 'responsavel_matricula';
    }
    if (limpo.contains('serie') ||
        limpo.contains('serial') ||
        limpo == 'numeroserie') {
      return 'numero_serie';
    }
    if (limpo.contains('fabricante') || limpo == 'marca') {
      return 'fabricante';
    }
    if (limpo.contains('modelo') || limpo == 'tipo') {
      return 'modelo';
    }
    return null;
  }

  /// Realiza o parsing completo do CSV e gera os dados estruturados e o relatório
  static DadosParseados processarCsv({
    required List<int> bytes,
    required String nomeArquivo,
    String? unidadeIdForcado,
  }) {
    final (conteudoTexto, codificacao) = decodificarBytes(bytes);
    final separador = detectarSeparar(conteudoTexto);

    // Normaliza quebras de linha
    final conteudoNormalizado = conteudoTexto.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final csvCodec = Csv(
      fieldDelimiter: separador,
      autoDetect: false,
      skipEmptyLines: false,
      dynamicTyping: false,
    );
    final List<List<dynamic>> matriz = csvCodec.decode(conteudoNormalizado);
    final itensRelatorio = <ItemRelatorio>[];

    if (matriz.isEmpty) {
      itensRelatorio.add(
        const ItemRelatorio(
          linha: 1,
          tipo: 'ERRO',
          mensagem: 'O arquivo CSV está vazio.',
        ),
      );
      final relatorioVazio = RelatorioImportacao(
        unidadeId: unidadeIdForcado ?? _uuid.v4(),
        unidadeNome: nomeArquivo,
        arquivoOrigem: nomeArquivo,
        totalLinhasLidas: 0,
        bensValidos: 0,
        totalSalas: 0,
        duplicadosAtualizados: 0,
        separadorDetectado: separador,
        codificacaoDetectada: codificacao,
        itens: itensRelatorio,
      );
      return DadosParseados(
        unidade: UnidadesCompanion(
          id: Value(relatorioVazio.unidadeId),
          nome: Value(nomeArquivo),
          dataImportacao: Value(DateTime.now()),
          arquivoOrigem: Value(nomeArquivo),
        ),
        locais: const [],
        bens: const [],
        salas: const [],
        relatorio: relatorioVazio,
      );
    }

    final cabecalhosOriginais = matriz[0].map((e) => e.toString().trim()).toList();
    final mapaIndices = <String, int>{};
    final indicesExtras = <int, String>{};

    for (int i = 0; i < cabecalhosOriginais.length; i++) {
      final canonico = mapearCabecalho(cabecalhosOriginais[i]);
      if (canonico != null && !mapaIndices.containsKey(canonico)) {
        mapaIndices[canonico] = i;
      } else {
        indicesExtras[i] = cabecalhosOriginais[i];
      }
    }

    // Valida colunas obrigatórias
    if (!mapaIndices.containsKey('tombamento') ||
        !mapaIndices.containsKey('descricao') ||
        !mapaIndices.containsKey('local')) {
      itensRelatorio.add(
        ItemRelatorio(
          linha: 1,
          tipo: 'ERRO',
          mensagem:
              'Cabeçalhos obrigatórios ausentes. Necessário identificar tombamento, descricao e local. Cabeçalhos lidos: $cabecalhosOriginais',
        ),
      );
    }

    final unidadeId = unidadeIdForcado ?? _uuid.v4();
    String unidadeNome = nomeArquivo.replaceAll(RegExp(r'\.[^.]+$'), '');

    final mapaLocaisPorCaminho = <String, LocaisCompanion>{};
    final mapaLocaisSalas = <String, LocaisCompanion>{};
    final mapaSalasConferencia = <String, ConferenciaSalasCompanion>{};
    final mapaBensPorTombamento = <String, BensCompanion>{};
    final tombamentosVistos = <String, int>{};

    int duplicadosCount = 0;

    for (int linhaIdx = 1; linhaIdx < matriz.length; linhaIdx++) {
      final numLinha = linhaIdx + 1;
      final linha = matriz[linhaIdx];

      if (linha.isEmpty || (linha.length == 1 && linha[0].toString().trim().isEmpty)) {
        continue;
      }

      if (linha.length != cabecalhosOriginais.length) {
        itensRelatorio.add(
          ItemRelatorio(
            linha: numLinha,
            tipo: 'AVISO',
            mensagem:
                'Número de colunas diferente do cabeçalho (${linha.length} lidas, esperadas ${cabecalhosOriginais.length}).',
          ),
        );
      }

      final tombamentoRaw = (mapaIndices.containsKey('tombamento') &&
              mapaIndices['tombamento']! < linha.length)
          ? linha[mapaIndices['tombamento']!].toString()
          : '';

      final descricaoRaw = (mapaIndices.containsKey('descricao') &&
              mapaIndices['descricao']! < linha.length)
          ? linha[mapaIndices['descricao']!].toString().trim()
          : '';

      final localRaw = (mapaIndices.containsKey('local') &&
              mapaIndices['local']! < linha.length)
          ? linha[mapaIndices['local']!].toString().trim()
          : '';

      if (tombamentoRaw.trim().isEmpty) {
        itensRelatorio.add(
          ItemRelatorio(
            linha: numLinha,
            tipo: 'ERRO',
            mensagem: 'Linha sem número de tombamento.',
          ),
        );
        continue;
      }

      if (descricaoRaw.isEmpty) {
        itensRelatorio.add(
          ItemRelatorio(
            linha: numLinha,
            tipo: 'ERRO',
            mensagem: 'Linha sem descrição do bem.',
            tombamento: tombamentoRaw,
          ),
        );
        continue;
      }

      if (localRaw.isEmpty) {
        itensRelatorio.add(
          ItemRelatorio(
            linha: numLinha,
            tipo: 'ERRO',
            mensagem: 'Linha sem indicação de local.',
            tombamento: tombamentoRaw,
          ),
        );
        continue;
      }

      final tombamentoNorm = Normalizacao.normalizarTombamento(tombamentoRaw);

      if (tombamentoNorm != tombamentoRaw.trim()) {
        itensRelatorio.add(
          ItemRelatorio(
            linha: numLinha,
            tipo: 'AVISO',
            mensagem:
                'Tombamento normalizado de "$tombamentoRaw" para "$tombamentoNorm".',
            tombamento: tombamentoNorm,
          ),
        );
      }

      if (tombamentosVistos.containsKey(tombamentoNorm)) {
        duplicadosCount++;
        itensRelatorio.add(
          ItemRelatorio(
            linha: numLinha,
            tipo: 'AVISO',
            mensagem:
                'Tombamento duplicado encontrado. Atualizado com dados da linha $numLinha (primeira ocorrência na linha ${tombamentosVistos[tombamentoNorm]}).',
            tombamento: tombamentoNorm,
          ),
        );
      } else {
        tombamentosVistos[tombamentoNorm] = numLinha;
      }

      // Constrói árvore hierárquica de locais
      final niveis = Normalizacao.extrairNiveisLocal(localRaw);
      String? paiId;
      String caminhoAcumulado = '';
      LocaisCompanion? localFinalSala;

      for (int nivelIdx = 0; nivelIdx < niveis.length; nivelIdx++) {
        final nomeNivel = niveis[nivelIdx];
        if (caminhoAcumulado.isEmpty) {
          caminhoAcumulado = nomeNivel;
        } else {
          caminhoAcumulado = '$caminhoAcumulado / $nomeNivel';
        }

        String tipoNivel;
        if (nivelIdx == 0) {
          tipoNivel = 'comarca';
          if (unidadeNome == nomeArquivo.replaceAll(RegExp(r'\.[^.]+$'), '')) {
            unidadeNome = nomeNivel;
          }
        } else if (nivelIdx == 1) {
          tipoNivel = 'predio';
        } else if (nivelIdx == 2) {
          tipoNivel = 'andar';
        } else {
          tipoNivel = 'sala';
        }

        if (!mapaLocaisPorCaminho.containsKey(caminhoAcumulado)) {
          final localId = _uuid.v4();
          final localCompanion = LocaisCompanion(
            id: Value(localId),
            unidadeId: Value(unidadeId),
            nome: Value(nomeNivel),
            tipo: Value(tipoNivel),
            paiId: Value(paiId),
            caminhoCompleto: Value(caminhoAcumulado),
          );
          mapaLocaisPorCaminho[caminhoAcumulado] = localCompanion;
          paiId = localId;

          if (tipoNivel == 'sala' || nivelIdx == niveis.length - 1) {
            localFinalSala = localCompanion;
            mapaLocaisSalas[localId] = localCompanion;
            mapaSalasConferencia[localId] = ConferenciaSalasCompanion(
              localId: Value(localId),
              status: const Value('nao_iniciada'),
            );
          }
        } else {
          final existente = mapaLocaisPorCaminho[caminhoAcumulado]!;
          paiId = existente.id.value;
          if (tipoNivel == 'sala' || nivelIdx == niveis.length - 1) {
            localFinalSala = existente;
            mapaLocaisSalas[existente.id.value] = existente;
          }
        }
      }

      final localIdFinal = localFinalSala?.id.value ?? paiId ?? unidadeId;

      // Extrai campos adicionais
      String? categoria;
      if (mapaIndices.containsKey('categoria') &&
          mapaIndices['categoria']! < linha.length) {
        final val = linha[mapaIndices['categoria']!].toString().trim();
        if (val.isNotEmpty) categoria = val;
      }

      String? responsavel;
      if (mapaIndices.containsKey('responsavel_matricula') &&
          mapaIndices['responsavel_matricula']! < linha.length) {
        final val = linha[mapaIndices['responsavel_matricula']!].toString().trim();
        if (val.isNotEmpty) responsavel = val;
      }

      String? numSerie;
      if (mapaIndices.containsKey('numero_serie') &&
          mapaIndices['numero_serie']! < linha.length) {
        final val = linha[mapaIndices['numero_serie']!].toString().trim();
        if (val.isNotEmpty) numSerie = val;
      }

      String? fabricante;
      if (mapaIndices.containsKey('fabricante') &&
          mapaIndices['fabricante']! < linha.length) {
        final val = linha[mapaIndices['fabricante']!].toString().trim();
        if (val.isNotEmpty) fabricante = val;
      }

      String? modelo;
      if (mapaIndices.containsKey('modelo') &&
          mapaIndices['modelo']! < linha.length) {
        final val = linha[mapaIndices['modelo']!].toString().trim();
        if (val.isNotEmpty) modelo = val;
      }

      // Colunas extras
      final extrasMap = <String, dynamic>{};
      indicesExtras.forEach((idx, nomeCol) {
        if (idx < linha.length) {
          final val = linha[idx].toString().trim();
          if (val.isNotEmpty) extrasMap[nomeCol] = val;
        }
      });
      final extrasJson = extrasMap.isNotEmpty ? jsonEncode(extrasMap) : null;

      final bemCompanion = BensCompanion(
        tombamento: Value(tombamentoNorm),
        unidadeId: Value(unidadeId),
        descricao: Value(descricaoRaw),
        categoria: Value(categoria),
        localEsperadoId: Value(localIdFinal),
        responsavel: Value(responsavel),
        numeroSerie: Value(numSerie),
        fabricante: Value(fabricante),
        modelo: Value(modelo),
        extras: Value(extrasJson),
      );

      mapaBensPorTombamento[tombamentoNorm] = bemCompanion;
    }

    final relatorio = RelatorioImportacao(
      unidadeId: unidadeId,
      unidadeNome: unidadeNome,
      arquivoOrigem: nomeArquivo,
      totalLinhasLidas: matriz.length > 1 ? matriz.length - 1 : 0,
      bensValidos: mapaBensPorTombamento.length,
      totalSalas: mapaLocaisSalas.length,
      duplicadosAtualizados: duplicadosCount,
      separadorDetectado: separador,
      codificacaoDetectada: codificacao,
      itens: itensRelatorio,
    );

    final unidadeCompanion = UnidadesCompanion(
      id: Value(unidadeId),
      nome: Value(unidadeNome),
      dataImportacao: Value(DateTime.now()),
      arquivoOrigem: Value(nomeArquivo),
    );

    return DadosParseados(
      unidade: unidadeCompanion,
      locais: mapaLocaisPorCaminho.values.toList(),
      bens: mapaBensPorTombamento.values.toList(),
      salas: mapaSalasConferencia.values.toList(),
      relatorio: relatorio,
    );
  }

  static String detectarSeparar(String conteudo) => detectarSeparador(conteudo);
}
