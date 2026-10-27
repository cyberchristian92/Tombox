import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tombox/data/local/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase (Drift)', () {
    test('Salva unidade completa com locais e bens', () async {
      final unidade = UnidadesCompanion(
        id: const Value('u1'),
        nome: const Value('Comarca de Breves'),
        dataImportacao: Value(DateTime.now()),
        arquivoOrigem: const Value('unidade_demo.csv'),
      );

      final locais = [
        const LocaisCompanion(
          id: Value('loc1'),
          unidadeId: Value('u1'),
          nome: Value('Sala 101'),
          tipo: Value('sala'),
          caminhoCompleto: Value('Comarca de Breves / Sala 101'),
        ),
      ];

      final bens = [
        const BensCompanion(
          tombamento: Value('010001'),
          unidadeId: Value('u1'),
          descricao: Value('Computador Dell'),
          localEsperadoId: Value('loc1'),
        ),
      ];

      final salas = [
        const ConferenciaSalasCompanion(
          localId: Value('loc1'),
          status: Value('nao_iniciada'),
        ),
      ];

      await db.salvarUnidadeCompleta(
        unidade: unidade,
        listaLocais: locais,
        listaBens: bens,
        salasConferencia: salas,
      );

      final unidadesSalvas = await db.select(db.unidades).get();
      expect(unidadesSalvas.length, 1);
      expect(unidadesSalvas.first.nome, 'Comarca de Breves');

      final bensSalvos = await db.select(db.bens).get();
      expect(bensSalvos.length, 1);
      expect(bensSalvos.first.tombamento, '010001');
    });

    test('Reimportação atualiza pelo tombamento sem duplicar', () async {
      final bemOriginal = const BensCompanion(
        tombamento: Value('010001'),
        unidadeId: Value('u1'),
        descricao: Value('Descrição Original'),
        localEsperadoId: Value('loc1'),
      );

      await db.upsertBens([bemOriginal]);
      var bensNaBase = await db.select(db.bens).get();
      expect(bensNaBase.length, 1);
      expect(bensNaBase.first.descricao, 'Descrição Original');

      // Reimporta o mesmo tombamento com descrição atualizada
      final bemAtualizado = const BensCompanion(
        tombamento: Value('010001'),
        unidadeId: Value('u1'),
        descricao: Value('Descrição Nova Atualizada'),
        localEsperadoId: Value('loc2'),
      );

      await db.upsertBens([bemAtualizado]);
      bensNaBase = await db.select(db.bens).get();

      // Não pode duplicar a linha na tabela!
      expect(bensNaBase.length, 1);
      expect(bensNaBase.first.descricao, 'Descrição Nova Atualizada');
    });

    test('Eventos imutáveis com sequência e encadeamento de hash', () async {
      final evento1 = EventosCompanion(
        id: const Value('evt-1'),
        seq: const Value(1),
        tipo: const Value('LEITURA'),
        tombamento: const Value('010001'),
        localId: const Value('loc1'),
        aparelhoId: const Value('device-01'),
        conferente: const Value('Rosilene'),
        timestamp: Value(DateTime.now()),
        payload: const Value('{"origem": "camera"}'),
        hashAnterior: const Value('0000000000000000000000000000000000000000000000000000000000000000'),
        hash: const Value('hash_evento_1'),
      );

      await db.registrarEvento(evento1);

      final ultimo = await db.obterUltimoEvento('device-01');
      expect(ultimo, isNotNull);
      expect(ultimo?.seq, 1);
      expect(ultimo?.hash, 'hash_evento_1');

      final evento2 = EventosCompanion(
        id: const Value('evt-2'),
        seq: const Value(2),
        tipo: const Value('CONFIRMACAO'),
        tombamento: const Value('010001'),
        localId: const Value('loc1'),
        aparelhoId: const Value('device-01'),
        conferente: const Value('Rosilene'),
        timestamp: Value(DateTime.now()),
        payload: const Value('{}'),
        hashAnterior: const Value('hash_evento_1'),
        hash: const Value('hash_evento_2'),
      );

      await db.registrarEvento(evento2);

      final novoUltimo = await db.obterUltimoEvento('device-01');
      expect(novoUltimo?.seq, 2);
      expect(novoUltimo?.hashAnterior, 'hash_evento_1');
      expect(novoUltimo?.hash, 'hash_evento_2');
    });
  });
}
