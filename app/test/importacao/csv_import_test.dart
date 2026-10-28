import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tombox/domain/importacao/csv_importer.dart';
import 'package:tombox/domain/importacao/normalizacao.dart';

void main() {
  group('Normalização de Tombamento e Salas', () {
    test('Normaliza tombamentos com letra O no lugar de zero', () {
      expect(Normalizacao.normalizarTombamento('O10006'), '010006');
      expect(Normalizacao.normalizarTombamento('10O45'), '10045');
      expect(Normalizacao.normalizarTombamento('OOO123'), '000123');
    });

    test('Preserva zeros à esquerda e remove pontuações e hífens', () {
      expect(Normalizacao.normalizarTombamento(' 000123 '), '000123');
      expect(Normalizacao.normalizarTombamento('10-234.5'), '102345');
      expect(Normalizacao.normalizarTombamento('01.002-3/4'), '0100234');
    });

    test('Normaliza códigos provisórios alfanuméricos', () {
      expect(Normalizacao.normalizarTombamento('PROV-000-123'), 'PROV000123');
    });

    test('Normaliza variações de nomes de salas para chave canônica', () {
      expect(Normalizacao.normalizarNomeSala('Sala 3'), 'sala 3');
      expect(Normalizacao.normalizarNomeSala('SL 03'), 'sala 3');
      expect(Normalizacao.normalizarNomeSala('sala03'), 'sala 3');
      expect(Normalizacao.normalizarNomeSala('Sala 101 - Gabinete'), 'sala 101 - gabinete');
      expect(Normalizacao.normalizarNomeSala('SL. 101'), 'sala 101');
    });

    test('Extrai níveis hierárquicos do caminho do local', () {
      final niveis = Normalizacao.extrairNiveisLocal(
        'Comarca de Breves / Fórum Juiz Vicente / 1º Andar / Sala 201',
      );
      expect(niveis, [
        'Comarca de Breves',
        'Fórum Juiz Vicente',
        '1º Andar',
        'Sala 201',
      ]);
    });

    test('Prompt 07: Resolve variações de salas sob o mesmo local pai', () {
      final salasTerreo = [
        'Sala 101 - Protocolo',
        'SL 101',
        'Sala 102 - Secretaria',
        'sala 102',
        'Sala 103 - Atendimento ao Cidadão',
        'Sala103',
      ];

      final resolucao = Normalizacao.resolverSalasPorPai(salasTerreo);

      expect(resolucao['Sala 101 - Protocolo'], 'Sala 101 - Protocolo');
      expect(resolucao['SL 101'], 'Sala 101 - Protocolo');
      expect(resolucao['Sala 102 - Secretaria'], 'Sala 102 - Secretaria');
      expect(resolucao['sala 102'], 'Sala 102 - Secretaria');
      expect(resolucao['Sala 103 - Atendimento ao Cidadão'], 'Sala 103 - Atendimento ao Cidadão');
      expect(resolucao['Sala103'], 'Sala 103 - Atendimento ao Cidadão');

      // Conjunto único de salas canônicas geradas deve ser exatamente 3
      final unicas = resolucao.values.toSet();
      expect(unicas.length, 3);
    });
  });

  group('CsvImporter - Detecção e Parsing', () {
    test('Detecta delimitadores (ponto e vírgula, vírgula, tabulação)', () {
      expect(CsvImporter.detectarSeparador('a;b;c\n1;2;3'), ';');
      expect(CsvImporter.detectarSeparador('a,b,c\n1,2,3'), ',');
      expect(CsvImporter.detectarSeparador('a\tb\tc\n1\t2\t3'), '\t');
    });

    test('Decodifica UTF-8 padrão, UTF-8 com BOM e Windows-1252', () {
      // 1. UTF-8
      final bytesUtf8 = utf8.encode('tombamento;descrição;local');
      final (texto1, cod1) = CsvImporter.decodificarBytes(bytesUtf8);
      expect(cod1, 'UTF-8');
      expect(texto1, contains('descrição'));

      // 2. UTF-8 com BOM
      final bytesBom = [0xEF, 0xBB, 0xBF, ...bytesUtf8];
      final (texto2, cod2) = CsvImporter.decodificarBytes(bytesBom);
      expect(cod2, 'UTF-8 (com BOM)');
      expect(texto2, contains('descrição'));

      // 3. Latin-1 / Windows-1252
      final bytesLatin1 = latin1.encode('tombamento;descriçao;local');
      final (texto3, cod3) = CsvImporter.decodificarBytes(bytesLatin1);
      expect(texto3, contains('descriçao'));
    });

    test('Mapeia sinônimos de cabeçalhos e colunas extras', () {
      const csvContent = '''
patrimonio;objeto;lotacao;marca;modelo;ano_compra;valor
010001;Monitor 24;Comarca / Prédio / 1º Andar / Sala 1;Dell;P2419H;2022;R\$ 1200
''';
      final dados = CsvImporter.processarCsv(
        bytes: utf8.encode(csvContent),
        nomeArquivo: 'teste_sinonimos.csv',
      );

      expect(dados.relatorio.bensValidos, 1);
      final bem = dados.bens.first;
      expect(bem.tombamento.value, '010001');
      expect(bem.descricao.value, 'Monitor 24');
      expect(bem.fabricante.value, 'Dell');
      expect(bem.modelo.value, 'P2419H');
      expect(bem.extras.value, contains('ano_compra'));
      expect(bem.extras.value, contains('2022'));
    });

    test('Gerencia duplicados atualizando pelo tombamento e gerando aviso', () {
      const csvComDuplicado = '''
tombamento;descricao;local
010001;Monitor Original;Comarca / Prédio / Sala 1
010002;Teclado;Comarca / Prédio / Sala 1
010001;Monitor Atualizado;Comarca / Prédio / Sala 2
''';
      final dados = CsvImporter.processarCsv(
        bytes: utf8.encode(csvComDuplicado),
        nomeArquivo: 'teste_duplicado.csv',
      );

      // Deve manter 2 bens únicos (atualizando o 010001)
      expect(dados.relatorio.bensValidos, 2);
      expect(dados.relatorio.duplicadosAtualizados, 1);
      expect(dados.relatorio.avisos.any((a) => a.mensagem.contains('duplicado')), isTrue);

      final bemAtualizado = dados.bens.firstWhere((b) => b.tombamento.value == '010001');
      expect(bemAtualizado.descricao.value, 'Monitor Atualizado');
    });

    test('Identifica linhas com número divergente de colunas e dados ausentes', () {
      const csvComProblemas = '''
tombamento;descricao;local
010001;Mesa;Comarca / Prédio / Sala 1
;Cadeira sem tombamento;Comarca / Prédio / Sala 1
010003;Notebook sem local;
010004;Projetor;Comarca / Prédio / Sala 1;ColunaExtra1;ColunaExtra2
''';
      final dados = CsvImporter.processarCsv(
        bytes: utf8.encode(csvComProblemas),
        nomeArquivo: 'problemas.csv',
      );

      // 2 bens válidos (010001 e 010004)
      expect(dados.relatorio.bensValidos, 2);
      // Erro na linha 3 (sem tombamento) e linha 4 (sem local)
      expect(dados.relatorio.erros.length, 2);
      // Aviso na linha 5 (número diferente de colunas)
      expect(dados.relatorio.avisos.any((a) => a.linha == 5), isTrue);
    });

    test('Prompt 07 (Parte A): Importação do CSV de demonstração gera exatamente 15 salas, 300 bens únicos e nenhuma sala com 0 bens', () {
      final arquivoDemo = File('assets/demo/unidade_demo.csv');
      expect(arquivoDemo.existsSync(), isTrue, reason: 'Arquivo assets/demo/unidade_demo.csv deve existir');

      final bytes = arquivoDemo.readAsBytesSync();
      final dados = CsvImporter.processarCsv(
        bytes: bytes,
        nomeArquivo: 'unidade_demo.csv',
      );

      // 1. Total de bens válidos únicos: 300 (a partir de 302 linhas com 2 duplicadas)
      expect(dados.relatorio.bensValidos, 300);
      expect(dados.relatorio.totalLinhasLidas, 302);
      expect(dados.relatorio.duplicadosAtualizados, 2);
      expect(dados.bens.length, 300);

      // 2. Exatamente 15 salas geradas (não 18)
      expect(dados.relatorio.totalSalas, 15);
      expect(dados.salas.length, 15);

      // 3. Nenhuma sala com 0 bens
      final salas = dados.locais.where((l) => l.tipo.value == 'sala').toList();
      expect(salas.length, 15);

      for (final sala in salas) {
        final bensDaSala = dados.bens.where((b) => b.localEsperadoId.value == sala.id.value).toList();
        expect(
          bensDaSala.isNotEmpty,
          isTrue,
          reason: 'A sala "${sala.nome.value}" (${sala.caminhoCompleto.value}) não pode ter 0 bens.',
        );
      }

      // 4. Nenhum local em duplicidade por caminho
      final caminhos = dados.locais.map((l) => l.caminhoCompleto.value).toList();
      expect(caminhos.length, caminhos.toSet().length, reason: 'Nenhum caminho de local pode ser duplicado.');
    });
  });
}
