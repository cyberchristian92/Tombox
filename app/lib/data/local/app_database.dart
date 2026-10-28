import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Unidades extends Table {
  TextColumn get id => text()();
  TextColumn get nome => text()();
  DateTimeColumn get dataImportacao => dateTime()();
  TextColumn get arquivoOrigem => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Local')
class Locais extends Table {
  TextColumn get id => text()();
  TextColumn get unidadeId => text()();
  TextColumn get nome => text()();
  TextColumn get tipo => text()(); // comarca, predio, andar, sala
  TextColumn get paiId => text().nullable()();
  TextColumn get caminhoCompleto => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Bem')
class Bens extends Table {
  TextColumn get tombamento => text()(); // Chave primária normalizada
  TextColumn get unidadeId => text()();
  TextColumn get descricao => text()();
  TextColumn get categoria => text().nullable()();
  TextColumn get localEsperadoId => text()();
  TextColumn get responsavel => text().nullable()();
  TextColumn get numeroSerie => text().nullable()();
  TextColumn get fabricante => text().nullable()();
  TextColumn get modelo => text().nullable()();
  TextColumn get extras => text().nullable()(); // JSON com colunas adicionais

  @override
  Set<Column> get primaryKey => {tombamento};
}

class ConferenciaSalas extends Table {
  TextColumn get localId => text()();
  TextColumn get status => text().withDefault(const Constant('nao_iniciada'))();
  DateTimeColumn get inicio => dateTime().nullable()();
  DateTimeColumn get fim => dateTime().nullable()();
  TextColumn get conferente => text().nullable()();

  @override
  Set<Column> get primaryKey => {localId};
}

class Eventos extends Table {
  TextColumn get id => text()();
  IntColumn get seq => integer()();
  TextColumn get tipo => text()(); // LEITURA, CONFIRMACAO, ESTADO, etc.
  TextColumn get tombamento => text().nullable()();
  TextColumn get localId => text()();
  TextColumn get aparelhoId => text()();
  TextColumn get conferente => text()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get payload => text().withDefault(const Constant('{}'))();
  TextColumn get hashFoto => text().nullable()();
  TextColumn get hashAnterior => text()();
  TextColumn get hash => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Unidades, Locais, Bens, ConferenciaSalas, Eventos])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e])
      : super(
          e ??
              driftDatabase(
                name: 'tombox_db',
                web: DriftWebOptions(
                  sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                  driftWorker: Uri.parse('drift_worker.js'),
                ),
              ),
        );

  @override
  int get schemaVersion => 1;

  /// Inserção imutável de evento (nunca permite update ou delete de eventos)
  Future<int> registrarEvento(EventosCompanion evento) {
    return into(eventos).insert(evento);
  }

  /// Busca o último evento para calcular o hash encadeado
  Future<Evento?> obterUltimoEvento(String aparelhoId) {
    return (select(eventos)
          ..where((tbl) => tbl.aparelhoId.equals(aparelhoId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.seq)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Upsert de bens na reimportação: atualiza pelo tombamento sem duplicar
  Future<void> upsertBens(List<BensCompanion> listaBens) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(bens, listaBens);
    });
  }

  /// Limpa e recarrega os locais e bens de uma unidade
  Future<void> salvarUnidadeCompleta({
    required UnidadesCompanion unidade,
    required List<LocaisCompanion> listaLocais,
    required List<BensCompanion> listaBens,
    required List<ConferenciaSalasCompanion> salasConferencia,
  }) async {
    await transaction(() async {
      await into(unidades).insertOnConflictUpdate(unidade);
      await batch((b) {
        b.insertAllOnConflictUpdate(locais, listaLocais);
        b.insertAllOnConflictUpdate(bens, listaBens);
        b.insertAllOnConflictUpdate(conferenciaSalas, salasConferencia);
      });
    });
  }

  Future<void> fecharSala(String salaId) async {
    await (update(conferenciaSalas)..where((c) => c.localId.equals(salaId)))
        .write(const ConferenciaSalasCompanion(status: Value('fechada')));
  }
}

