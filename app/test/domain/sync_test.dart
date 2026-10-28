import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tombox/data/local/app_database.dart';
import 'package:tombox/domain/eventos/evento_service.dart';
import 'package:tombox/domain/eventos/evento_v2.dart';
import 'package:tombox/domain/fotos/foto_service.dart';
import 'package:tombox/domain/identidade/identidade_service.dart';
import 'package:tombox/domain/sync/sync_engine.dart';

void main() {
  setUp(() {
    IdentidadeService.resetarInstanciaParaTestes();
    FotoService.limparStorageParaTestes();
  });

  group('Motor de Sincronização P2P (Arquitetura v2)', () {
    test('Calcula resumo de sequências por autor corretamente', () async {
      final db = AppDatabase(NativeDatabase.memory());

      // Gera chaves para dois autores
      final parA = await IdentidadeService.algorithm.newKeyPair();
      final pubA = IdentidadeService.bytesParaHex((await parA.extractPublicKey()).bytes);

      final parB = await IdentidadeService.algorithm.newKeyPair();
      final pubB = IdentidadeService.bytesParaHex((await parB.extractPublicKey()).bytes);

      // Registra evento do autor A
      final evA1 = await EventoV2.criar(
        id: 'ev-a-1',
        unidadeId: 'u1',
        tipo: TiposEvento.leitura,
        autor: pubA,
        seq: 1,
        hashAnterior: EventoV2.hashInicial,
        conhecidos: {},
        payload: {'tombamento': '010001'},
        keyPair: parA,
      );
      await EventoService.aplicarEventoExterno(db: db, evento: evA1);

      // Registra eventos do autor B (seq 1 e seq 2)
      final evB1 = await EventoV2.criar(
        id: 'ev-b-1',
        unidadeId: 'u1',
        tipo: TiposEvento.leitura,
        autor: pubB,
        seq: 1,
        hashAnterior: EventoV2.hashInicial,
        conhecidos: {pubA: evA1.hash},
        payload: {'tombamento': '010002'},
        keyPair: parB,
      );
      await EventoService.aplicarEventoExterno(db: db, evento: evB1);

      final evB2 = await EventoV2.criar(
        id: 'ev-b-2',
        unidadeId: 'u1',
        tipo: TiposEvento.confirmacao,
        autor: pubB,
        seq: 2,
        hashAnterior: evB1.hash,
        conhecidos: {pubA: evA1.hash},
        payload: {'tombamento': '010002'},
        keyPair: parB,
      );
      await EventoService.aplicarEventoExterno(db: db, evento: evB2);

      // Calcula resumo
      final resumo = await SyncEngine.calcularResumo(db);
      expect(resumo.maioresSequencias[pubA], equals(1));
      expect(resumo.maioresSequencias[pubB], equals(2));

      await db.close();
    });

    test('Dois bancos convergem para o mesmo conjunto de eventos após sincronização', () async {
      final db1 = AppDatabase(NativeDatabase.memory());
      final db2 = AppDatabase(NativeDatabase.memory());

      final par1 = await IdentidadeService.algorithm.newKeyPair();
      final pub1 = IdentidadeService.bytesParaHex((await par1.extractPublicKey()).bytes);

      final par2 = await IdentidadeService.algorithm.newKeyPair();
      final pub2 = IdentidadeService.bytesParaHex((await par2.extractPublicKey()).bytes);

      // Aparelho 1 cria evento
      final ev1 = await EventoV2.criar(
        id: 'ev-1',
        unidadeId: 'u1',
        tipo: TiposEvento.leitura,
        autor: pub1,
        seq: 1,
        hashAnterior: EventoV2.hashInicial,
        conhecidos: {},
        payload: {'sala': '101'},
        keyPair: par1,
      );
      await EventoService.aplicarEventoExterno(db: db1, evento: ev1);

      // Aparelho 2 cria evento
      final ev2 = await EventoV2.criar(
        id: 'ev-2',
        unidadeId: 'u1',
        tipo: TiposEvento.leitura,
        autor: pub2,
        seq: 1,
        hashAnterior: EventoV2.hashInicial,
        conhecidos: {},
        payload: {'sala': '102'},
        keyPair: par2,
      );
      await EventoService.aplicarEventoExterno(db: db2, evento: ev2);

      // Troca de resumos: db1 pergunta o que falta para db2 e vice-versa
      final resumo1 = await SyncEngine.calcularResumo(db1);
      final resumo2 = await SyncEngine.calcularResumo(db2);

      final paraDb2 = await SyncEngine.extrairEventosParaEnvio(db1, resumo2);
      final paraDb1 = await SyncEngine.extrairEventosParaEnvio(db2, resumo1);

      expect(paraDb2.length, equals(1));
      expect(paraDb2.first.id, equals('ev-1'));

      expect(paraDb1.length, equals(1));
      expect(paraDb1.first.id, equals('ev-2'));

      // Aplicação mútua
      await SyncEngine.aplicarEventos(db2, paraDb2);
      await SyncEngine.aplicarEventos(db1, paraDb1);

      // Ambos os bancos agora têm exatamente os mesmos 2 eventos
      final eventosDb1 = await db1.select(db1.eventos).get();
      final eventosDb2 = await db2.select(db2.eventos).get();

      expect(eventosDb1.length, equals(2));
      expect(eventosDb2.length, equals(2));

      final hashesDb1 = (eventosDb1.map((e) => e.hash).toList()..sort());
      final hashesDb2 = (eventosDb2.map((e) => e.hash).toList()..sort());
      expect(hashesDb1, equals(hashesDb2));

      await db1.close();
      await db2.close();
    });

    test('Três bancos com ordens de sincronização distintas convergem para o mesmo estado', () async {
      final dbA = AppDatabase(NativeDatabase.memory());
      final dbB = AppDatabase(NativeDatabase.memory());
      final dbC = AppDatabase(NativeDatabase.memory());

      final parA = await IdentidadeService.algorithm.newKeyPair();
      final pubA = IdentidadeService.bytesParaHex((await parA.extractPublicKey()).bytes);

      final parB = await IdentidadeService.algorithm.newKeyPair();
      final pubB = IdentidadeService.bytesParaHex((await parB.extractPublicKey()).bytes);

      final parC = await IdentidadeService.algorithm.newKeyPair();
      final pubC = IdentidadeService.bytesParaHex((await parC.extractPublicKey()).bytes);

      // Cada aparelho cria um evento independente
      final evA = await EventoV2.criar(
        id: 'ev-A',
        unidadeId: 'u1',
        tipo: TiposEvento.leitura,
        autor: pubA,
        seq: 1,
        hashAnterior: EventoV2.hashInicial,
        conhecidos: {},
        payload: {'item': 'A'},
        keyPair: parA,
      );
      await EventoService.aplicarEventoExterno(db: dbA, evento: evA);

      final evB = await EventoV2.criar(
        id: 'ev-B',
        unidadeId: 'u1',
        tipo: TiposEvento.leitura,
        autor: pubB,
        seq: 1,
        hashAnterior: EventoV2.hashInicial,
        conhecidos: {},
        payload: {'item': 'B'},
        keyPair: parB,
      );
      await EventoService.aplicarEventoExterno(db: dbB, evento: evB);

      final evC = await EventoV2.criar(
        id: 'ev-C',
        unidadeId: 'u1',
        tipo: TiposEvento.leitura,
        autor: pubC,
        seq: 1,
        hashAnterior: EventoV2.hashInicial,
        conhecidos: {},
        payload: {'item': 'C'},
        keyPair: parC,
      );
      await EventoService.aplicarEventoExterno(db: dbC, evento: evC);

      // Topologia em anel: A sincroniza com B, B com C, e C com A
      // 1. A -> B
      var resB = await SyncEngine.calcularResumo(dbB);
      var envioAparaB = await SyncEngine.extrairEventosParaEnvio(dbA, resB);
      await SyncEngine.aplicarEventos(dbB, envioAparaB);

      // 2. B -> C
      var resC = await SyncEngine.calcularResumo(dbC);
      var envioBparaC = await SyncEngine.extrairEventosParaEnvio(dbB, resC);
      await SyncEngine.aplicarEventos(dbC, envioBparaC);

      // 3. C -> A
      var resA = await SyncEngine.calcularResumo(dbA);
      var envioCparaA = await SyncEngine.extrairEventosParaEnvio(dbC, resA);
      await SyncEngine.aplicarEventos(dbA, envioCparaA);

      // 4. Fechamento final: A -> B
      resB = await SyncEngine.calcularResumo(dbB);
      envioAparaB = await SyncEngine.extrairEventosParaEnvio(dbA, resB);
      await SyncEngine.aplicarEventos(dbB, envioAparaB);

      // Todos os 3 bancos devem ter os 3 eventos exatos
      final evsA = await dbA.select(dbA.eventos).get();
      final evsB = await dbB.select(dbB.eventos).get();
      final evsC = await dbC.select(dbC.eventos).get();

      expect(evsA.length, equals(3));
      expect(evsB.length, equals(3));
      expect(evsC.length, equals(3));

      final hashesA = (evsA.map((e) => e.hash).toList()..sort());
      final hashesB = (evsB.map((e) => e.hash).toList()..sort());
      final hashesC = (evsC.map((e) => e.hash).toList()..sort());

      expect(hashesA, equals(hashesB));
      expect(hashesB, equals(hashesC));

      await dbA.close();
      await dbB.close();
      await dbC.close();
    });

    test('Aplicação de eventos é estritamente idempotente', () async {
      final db = AppDatabase(NativeDatabase.memory());

      final par = await IdentidadeService.algorithm.newKeyPair();
      final pub = IdentidadeService.bytesParaHex((await par.extractPublicKey()).bytes);

      final ev = await EventoV2.criar(
        id: 'ev-idempotente',
        unidadeId: 'u1',
        tipo: TiposEvento.leitura,
        autor: pub,
        seq: 1,
        hashAnterior: EventoV2.hashInicial,
        conhecidos: {},
        payload: {'teste': 1},
        keyPair: par,
      );

      // Aplica primeira vez
      final res1 = await SyncEngine.aplicarEventos(db, [ev]);
      expect(res1.eventosAplicados, equals(1));

      // Aplica segunda vez (deve ser no-op)
      final res2 = await SyncEngine.aplicarEventos(db, [ev]);
      expect(res2.eventosAplicados, equals(0));

      final total = await db.select(db.eventos).get();
      expect(total.length, equals(1));

      await db.close();
    });

    test('Evento inválido é enviado para quarentena sem quebrar a sincronização', () async {
      final db = AppDatabase(NativeDatabase.memory());

      final par = await IdentidadeService.algorithm.newKeyPair();
      final pub = IdentidadeService.bytesParaHex((await par.extractPublicKey()).bytes);

      final evValido = await EventoV2.criar(
        id: 'ev-valido',
        unidadeId: 'u1',
        tipo: TiposEvento.leitura,
        autor: pub,
        seq: 1,
        hashAnterior: EventoV2.hashInicial,
        conhecidos: {},
        payload: {'ok': true},
        keyPair: par,
      );

      // Evento adulterado (hash não confere)
      final evAdulterado = EventoV2(
        id: 'ev-adulterado',
        unidadeId: 'u1',
        tipo: TiposEvento.leitura,
        autor: pub,
        seq: 2,
        hashAnterior: evValido.hash,
        conhecidos: {},
        timestamp: DateTime.now().toUtc(),
        payload: {'corrompido': true},
        hash: '0000000000000000000000000000000000000000000000000000000000000000',
        assinatura: '00' * 64,
      );

      final res = await SyncEngine.aplicarEventos(db, [evValido, evAdulterado]);

      expect(res.eventosAplicados, equals(1));
      expect(res.eventosQuarentena, equals(1));
      expect(res.convergente, isFalse);

      final eventosValidos = await db.select(db.eventos).get();
      expect(eventosValidos.length, equals(1));
      expect(eventosValidos.first.id, equals('ev-valido'));

      final quarentena = await db.obterEventosQuarentena();
      expect(quarentena.length, equals(1));
      expect(quarentena.first.id, equals('ev-adulterado'));

      await db.close();
    });

    test('Exportação e importação de pacote .tombox preserva eventos e fotos', () async {
      final dbOrigem = AppDatabase(NativeDatabase.memory());
      final dbDestino = AppDatabase(NativeDatabase.memory());

      final par = await IdentidadeService.algorithm.newKeyPair();
      final pub = IdentidadeService.bytesParaHex((await par.extractPublicKey()).bytes);

      // 1. Criar foto de teste
      final imgTeste = img.Image(width: 400, height: 300);
      img.fill(imgTeste, color: img.ColorRgb8(100, 150, 200));
      final bytesFoto = Uint8List.fromList(img.encodeJpg(imgTeste, quality: 60));
      final resFoto = FotoService.processarBytes(bytesFoto);

      // 2. Registrar evento FOTO com hash
      final evFoto = await EventoV2.criar(
        id: 'ev-foto-01',
        unidadeId: 'unidade_breves',
        tipo: TiposEvento.foto,
        autor: pub,
        seq: 1,
        hashAnterior: EventoV2.hashInicial,
        conhecidos: {},
        payload: {
          'tombamento': '010001',
          'hash_foto': resFoto.hash,
        },
        keyPair: par,
      );
      await EventoService.aplicarEventoExterno(db: dbOrigem, evento: evFoto);

      // 3. Exportar pacote .tombox (zip)
      final zipBytes = await SyncEngine.exportarPacoteTombox(dbOrigem, unidadeId: 'unidade_breves');
      expect(zipBytes, isNotEmpty);
      expect(zipBytes.length, greaterThan(100));

      // 4. Limpar storage em memória para garantir restauração via pacote
      FotoService.limparStorageParaTestes();
      expect(FotoService.existeFoto(resFoto.hash), isFalse);

      // 5. Importar pacote no banco de destino
      final resultadoImport = await SyncEngine.importarPacoteTombox(dbDestino, zipBytes);

      expect(resultadoImport.eventosAplicados, equals(1));
      expect(resultadoImport.eventosQuarentena, equals(0));
      expect(resultadoImport.convergente, isTrue);

      // Foto restaurada no storage pelo seu hash SHA-256
      expect(FotoService.existeFoto(resFoto.hash), isTrue);

      final evsDestino = await dbDestino.select(dbDestino.eventos).get();
      expect(evsDestino.length, equals(1));
      expect(evsDestino.first.id, equals('ev-foto-01'));

      await dbOrigem.close();
      await dbDestino.close();
    });
  });
}
