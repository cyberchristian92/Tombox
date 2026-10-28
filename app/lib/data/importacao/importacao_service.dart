import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/importacao/csv_importer.dart';
import '../../domain/importacao/relatorio_importacao.dart';
import '../local/database_provider.dart';
import '../local/perfil_provider.dart';
import '../local/queries_provider.dart';

class ImportacaoState {
  final bool processando;
  final RelatorioImportacao? relatorioAtivo;
  final String? erroCritico;

  const ImportacaoState({
    this.processando = false,
    this.relatorioAtivo,
    this.erroCritico,
  });

  ImportacaoState copyWith({
    bool? processando,
    RelatorioImportacao? relatorioAtivo,
    String? erroCritico,
  }) {
    return ImportacaoState(
      processando: processando ?? this.processando,
      relatorioAtivo: relatorioAtivo ?? this.relatorioAtivo,
      erroCritico: erroCritico,
    );
  }
}

class ImportacaoService extends Notifier<ImportacaoState> {
  @override
  ImportacaoState build() {
    return const ImportacaoState();
  }

  /// Importa a unidade sintética de demonstração embutida nos assets
  Future<RelatorioImportacao> importarDadosDemonstracao() async {
    state = state.copyWith(processando: true, erroCritico: null);
    try {
      final byteData = await rootBundle.load('assets/demo/unidade_demo.csv');
      final bytes = byteData.buffer.asUint8List();
      final dados = CsvImporter.processarCsv(
        bytes: bytes,
        nomeArquivo: 'unidade_demo.csv',
      );

      final db = ref.read(databaseProvider);
      await db.salvarUnidadeCompleta(
        unidade: dados.unidade,
        listaLocais: dados.locais,
        listaBens: dados.bens,
        salasConferencia: dados.salas,
      );

      // Define a unidade ativa e perfil de demonstração
      ref.read(unidadeAtivaIdProvider.notifier).state = dados.unidade.id.value;
      ref.read(perfilProvider.notifier).carregarPerfilDemonstracao();

      state = state.copyWith(
        processando: false,
        relatorioAtivo: dados.relatorio,
      );
      return dados.relatorio;
    } catch (e) {
      final erroMsg = 'Erro ao carregar dados de demonstração: $e';
      state = state.copyWith(processando: false, erroCritico: erroMsg);
      rethrow;
    }
  }

  /// Importa a partir de bytes fornecidos (ex: via file_picker)
  Future<RelatorioImportacao> importarBytes({
    required List<int> bytes,
    required String nomeArquivo,
  }) async {
    state = state.copyWith(processando: true, erroCritico: null);
    try {
      final dados = CsvImporter.processarCsv(
        bytes: bytes,
        nomeArquivo: nomeArquivo,
      );

      final db = ref.read(databaseProvider);
      await db.salvarUnidadeCompleta(
        unidade: dados.unidade,
        listaLocais: dados.locais,
        listaBens: dados.bens,
        salasConferencia: dados.salas,
      );

      // Define a unidade ativa
      ref.read(unidadeAtivaIdProvider.notifier).state = dados.unidade.id.value;

      state = state.copyWith(
        processando: false,
        relatorioAtivo: dados.relatorio,
      );
      return dados.relatorio;
    } catch (e) {
      final erroMsg = 'Erro ao importar arquivo CSV: $e';
      state = state.copyWith(processando: false, erroCritico: erroMsg);
      rethrow;
    }
  }
}

final importacaoProvider =
    NotifierProvider<ImportacaoService, ImportacaoState>(ImportacaoService.new);
