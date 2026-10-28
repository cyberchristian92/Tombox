import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tombox/data/local/app_database.dart';
import 'package:tombox/domain/divergencias/divergencia_models.dart';
import 'package:tombox/domain/divergencias/divergencia_service.dart';
import 'package:tombox/domain/eventos/evento_service.dart';
import 'package:tombox/domain/eventos/evento_v2.dart';
import 'package:tombox/domain/eventos/evento_validador.dart';
import 'package:tombox/domain/homologacao/homologacao_service.dart';
import 'package:tombox/domain/identidade/identidade_service.dart';
import 'package:tombox/domain/membros/membro_models.dart';
import 'package:tombox/domain/membros/membro_service.dart';

void main() {
  setUp(() {
    IdentidadeService.resetarInstanciaParaTestes();
    MembroService.limparParaTestes();
  });

  group('Papéis, Membros e Permissões (Arquitetura v2)', () {
    test('Conferente não pode emitir eventos exclusivos de Gestor', () {
      expect(
        MembroService.verificarPermissao(PapelUsuario.conferente, TiposEvento.homologacao),
        isFalse,
      );
      expect(
        MembroService.verificarPermissao(PapelUsuario.conferente, TiposEvento.membroAdicionado),
        isFalse,
      );
      expect(
        MembroService.verificarPermissao(PapelUsuario.conferente, TiposEvento.membroRevogado),
        isFalse,
      );
      expect(
        MembroService.verificarPermissao(PapelUsuario.conferente, TiposEvento.divergenciaResolvida),
        isFalse,
      );
      expect(
        MembroService.verificarPermissao(PapelUsuario.conferente, TiposEvento.unidadeCriada),
        isFalse,
      );

      // Conferente pode emitir leituras, estados, observações e fotos
      expect(
        MembroService.verificarPermissao(PapelUsuario.conferente, TiposEvento.leitura),
        isTrue,
      );
      expect(
        MembroService.verificarPermissao(PapelUsuario.conferente, TiposEvento.estado),
        isTrue,
      );
      expect(
        MembroService.verificarPermissao(PapelUsuario.conferente, TiposEvento.foto),
        isTrue,
      );
      expect(
        MembroService.verificarPermissao(PapelUsuario.conferente, TiposEvento.fechamentoSala),
        isTrue,
      );
    });

    test('Gestor possui autorização irrestrita para todos os tipos de eventos', () {
      for (final tipo in [
        TiposEvento.unidadeCriada,
        TiposEvento.membroAdicionado,
        TiposEvento.membroRevogado,
        TiposEvento.homologacao,
        TiposEvento.divergenciaResolvida,
        TiposEvento.leitura,
        TiposEvento.foto,
      ]) {
        expect(MembroService.verificarPermissao(PapelUsuario.gestor, tipo), isTrue);
      }
    });

    test('Evento restrito assinado por conferente falha com papelNaoAutorizado', () async {
      final par = await IdentidadeService.algorithm.newKeyPair();
      final pub = IdentidadeService.bytesParaHex((await par.extractPublicKey()).bytes);

      final evHomologacaoIlegal = await EventoV2.criar(
        id: 'ev-ilegal-01',
        unidadeId: 'u1',
        tipo: TiposEvento.homologacao,
        autor: pub,
        seq: 1,
        hashAnterior: EventoV2.hashInicial,
        conhecidos: {},
        payload: {'sala_id': 'sala_101'},
        keyPair: par,
      );

      final resultado = await EventoValidador.validar(
        evento: evHomologacaoIlegal,
        papelDoAutor: PapelUsuario.conferente,
      );

      expect(resultado.valido, isFalse);
      expect(resultado.motivo, equals(MotivoRejeicao.papelNaoAutorizado));
    });

    test('Convite por QR Code com uso único e prazo de expiração', () {
      final convite = MembroService.gerarConvite(
        unidadeId: 'unidade_breves',
        gestorChavePublica: 'chave_gestor_123',
        papel: PapelUsuario.conferente,
        validade: const Duration(minutes: 10),
      );

      expect(convite.codigo.length, equals(8));
      expect(convite.isValido, isTrue);
      expect(convite.usado, isFalse);

      // Decodificação do payload do QR
      final decodificado = ConviteMembro.tentarDecodificarQr(convite.payloadQr);
      expect(decodificado, isNotNull);
      expect(decodificado!.codigo, equals(convite.codigo));
      expect(decodificado.unidadeId, equals('unidade_breves'));
      expect(decodificado.papel, equals(PapelUsuario.conferente));

      // 1º consumo: sucesso
      final consumido = MembroService.validarEConsumirConvite(
        convite.codigo,
        chavePublicaMembro: 'pub_novo_membro_abc',
      );
      expect(consumido.usado, isTrue);
      expect(consumido.usadoPor, equals('pub_novo_membro_abc'));

      // 2º consumo: falha (uso único)
      expect(
        () => MembroService.validarEConsumirConvite(
          convite.codigo,
          chavePublicaMembro: 'pub_outro_membro',
        ),
        throwsException,
      );
    });

    test('Adição e revogação de membro projetam estados corretos e barram eventos futuros', () async {
      final db = AppDatabase(NativeDatabase.memory());

      final parGestor = await IdentidadeService.algorithm.newKeyPair();
      final pubGestor = IdentidadeService.bytesParaHex((await parGestor.extractPublicKey()).bytes);

      final parMembro = await IdentidadeService.algorithm.newKeyPair();
      final pubMembro = IdentidadeService.bytesParaHex((await parMembro.extractPublicKey()).bytes);

      // 1. Criar unidade com gestor fundador
      final evUnidade = await EventoV2.criar(
        id: 'ev-unidade-01',
        unidadeId: 'u1',
        tipo: TiposEvento.unidadeCriada,
        autor: pubGestor,
        seq: 1,
        hashAnterior: EventoV2.hashInicial,
        conhecidos: {},
        payload: {
          'gestor_nome': 'Dr. Marcos Gestor',
          'gestor_matricula': 'TJPA-1010',
        },
        keyPair: parGestor,
      );
      await EventoService.aplicarEventoExterno(db: db, evento: evUnidade);

      // 2. Gestor adiciona novo membro conferente
      await MembroService.adicionarMembro(
        db: db,
        unidadeId: 'u1',
        chavePublicaNovoMembro: pubMembro,
        nome: 'Rosilene Silva',
        matricula: 'TJPA-8842',
        papel: PapelUsuario.conferente,
        keyPairGestor: parGestor,
      );

      var membros = await MembroService.obterMembros(db, unidadeId: 'u1');
      expect(membros.length, equals(2));
      expect(membros.any((m) => m.chavePublica == pubMembro && m.ativo), isTrue);

      // 3. Gestor revoga o membro
      await MembroService.revogarMembro(
        db: db,
        unidadeId: 'u1',
        chavePublicaMembroRevogado: pubMembro,
        motivo: 'Fim da designação na comarca',
        keyPairGestor: parGestor,
      );

      membros = await MembroService.obterMembros(db, unidadeId: 'u1');
      final membroRevogado = membros.firstWhere((m) => m.chavePublica == pubMembro);
      expect(membroRevogado.ativo, isFalse);
      expect(membroRevogado.motivoRevogacao, equals('Fim da designação na comarca'));

      final chavesRevogadas = await MembroService.obterChavesRevogadas(db, unidadeId: 'u1');
      expect(chavesRevogadas.contains(pubMembro), isTrue);

      // 4. Tentativa de emitir novo evento pelo membro revogado é rejeitada
      final evAposRevogacao = await EventoV2.criar(
        id: 'ev-ilegal-pos-revogacao',
        unidadeId: 'u1',
        tipo: TiposEvento.leitura,
        autor: pubMembro,
        seq: 1,
        hashAnterior: EventoV2.hashInicial,
        conhecidos: {},
        payload: {'tombamento': '010001'},
        keyPair: parMembro,
      );

      final val = await EventoValidador.validar(
        evento: evAposRevogacao,
        autoresRevogados: chavesRevogadas,
      );
      expect(val.valido, isFalse);
      expect(val.motivo, equals(MotivoRejeicao.autorRevogado));

      await db.close();
    });
  });

  group('Fila de Divergências e Homologação (Arquitetura v2)', () {
    test('Detecta divergências de sala incorreta e diagnóstico de causa provável', () async {
      final db = AppDatabase(NativeDatabase.memory());

      final par = await IdentidadeService.algorithm.newKeyPair();
      final pub = IdentidadeService.bytesParaHex((await par.extractPublicKey()).bytes);

      // Inserir local e bem
      await db.into(db.locais).insert(
            LocaisCompanion.insert(
              id: 'sala_101',
              unidadeId: 'u1',
              nome: 'Gabinete 101',
              caminhoCompleto: 'Fórum / 1º Andar / Gabinete 101',
              tipo: 'sala',
            ),
          );
      await db.into(db.locais).insert(
            LocaisCompanion.insert(
              id: 'sala_102',
              unidadeId: 'u1',
              nome: 'Secretaria 102',
              caminhoCompleto: 'Fórum / 1º Andar / Secretaria 102',
              tipo: 'sala',
            ),
          );
      await db.into(db.bens).insert(
            BensCompanion.insert(
              tombamento: '099001',
              unidadeId: 'u1',
              descricao: 'Monitor Dell 24"',
              localEsperadoId: 'sala_101',
            ),
          );

      // Conferente lê o bem na sala 102 (sala incorreta)
      final evLeitura = await EventoV2.criar(
        id: 'ev-leit-01',
        unidadeId: 'u1',
        tipo: TiposEvento.leitura,
        autor: pub,
        seq: 1,
        hashAnterior: EventoV2.hashInicial,
        conhecidos: {},
        payload: {
          'tombamento': '099001',
          'local_id': 'sala_102',
          'conferente': 'Conferente A',
        },
        keyPair: par,
      );
      await EventoService.aplicarEventoExterno(db: db, evento: evLeitura);

      final divergencias = await DivergenciaService.obterFilaDivergencias(db);
      expect(divergencias.length, equals(1));

      final div = divergencias.first;
      expect(div.tipo, equals(TipoDivergencia.salaIncorreta));
      expect(div.tombamento, equals('099001'));
      expect(div.localEsperadoId, equals('sala_101'));
      expect(div.localEncontradoId, equals('sala_102'));
      expect(div.causaProvavel, contains('Movimentação física'));
      expect(div.proximoPasso, contains('Aprovar transferência'));
      expect(div.resolvida, isFalse);

      // Resolução pelo Gestor
      await DivergenciaService.resolverDivergencia(
        db: db,
        unidadeId: 'u1',
        tombamento: '099001',
        decisao: 'Transferência confirmada para Secretaria 102',
        justificativa: 'Bem remanejado em definitivo por necessidade de serviço.',
        novoLocalId: 'sala_102',
        keyPairGestor: par,
      );

      final divergenciasApos = await DivergenciaService.obterFilaDivergencias(db);
      expect(divergenciasApos.first.resolvida, isTrue);

      await db.close();
    });

    test('Conflito lado a lado entre leituras concorrentes de dois conferentes', () async {
      final db = AppDatabase(NativeDatabase.memory());

      final parA = await IdentidadeService.algorithm.newKeyPair();
      final pubA = IdentidadeService.bytesParaHex((await parA.extractPublicKey()).bytes);

      final parB = await IdentidadeService.algorithm.newKeyPair();
      final pubB = IdentidadeService.bytesParaHex((await parB.extractPublicKey()).bytes);

      await db.into(db.locais).insert(
            LocaisCompanion.insert(
              id: 'sala_a',
              unidadeId: 'u1',
              nome: 'Sala A',
              caminhoCompleto: 'Fórum / Sala A',
              tipo: 'sala',
            ),
          );
      await db.into(db.locais).insert(
            LocaisCompanion.insert(
              id: 'sala_b',
              unidadeId: 'u1',
              nome: 'Sala B',
              caminhoCompleto: 'Fórum / Sala B',
              tipo: 'sala',
            ),
          );
      await db.into(db.bens).insert(
            BensCompanion.insert(
              tombamento: '088002',
              unidadeId: 'u1',
              descricao: 'Notebook HP ProBook',
              localEsperadoId: 'sala_a',
            ),
          );

      // Conferente A registra na Sala A
      final evA = await EventoV2.criar(
        id: 'ev-conf-a',
        unidadeId: 'u1',
        tipo: TiposEvento.leitura,
        autor: pubA,
        seq: 1,
        hashAnterior: EventoV2.hashInicial,
        conhecidos: {},
        payload: {
          'tombamento': '088002',
          'local_id': 'sala_a',
          'conferente': 'Conferente Ana',
          'hash_foto': 'sha256_foto_ana',
        },
        keyPair: parA,
      );
      await EventoService.aplicarEventoExterno(db: db, evento: evA);

      // Conferente B registra na Sala B
      final evB = await EventoV2.criar(
        id: 'ev-conf-b',
        unidadeId: 'u1',
        tipo: TiposEvento.leitura,
        autor: pubB,
        seq: 1,
        hashAnterior: EventoV2.hashInicial,
        conhecidos: {},
        payload: {
          'tombamento': '088002',
          'local_id': 'sala_b',
          'conferente': 'Conferente Bruno',
          'hash_foto': 'sha256_foto_bruno',
        },
        keyPair: parB,
      );
      await EventoService.aplicarEventoExterno(db: db, evento: evB);

      final divs = await DivergenciaService.obterFilaDivergencias(db);
      final divConflito = divs.firstWhere((d) => d.tipo == TipoDivergencia.conflitoConferentes);

      expect(divConflito.conflito, isNotNull);
      expect(divConflito.conflito!.conferenteA, equals('Conferente Ana'));
      expect(divConflito.conflito!.conferenteB, equals('Conferente Bruno'));
      expect(divConflito.conflito!.hashFotoA, equals('sha256_foto_ana'));
      expect(divConflito.conflito!.hashFotoB, equals('sha256_foto_bruno'));

      await db.close();
    });

    test('Homologação pelo Gestor aprova sala e apenas homologados entram no relatório oficial', () async {
      final db = AppDatabase(NativeDatabase.memory());

      final parGestor = await IdentidadeService.algorithm.newKeyPair();
      final pubGestor = IdentidadeService.bytesParaHex((await parGestor.extractPublicKey()).bytes);

      await db.into(db.locais).insert(
            LocaisCompanion.insert(
              id: 'sala_homologada',
              unidadeId: 'u1',
              nome: 'Vara Única',
              caminhoCompleto: 'Fórum / Vara Única',
              tipo: 'sala',
            ),
          );
      await db.into(db.locais).insert(
            LocaisCompanion.insert(
              id: 'sala_pendente',
              unidadeId: 'u1',
              nome: 'Depósito Geral',
              caminhoCompleto: 'Fórum / Depósito Geral',
              tipo: 'sala',
            ),
          );

      await db.into(db.bens).insert(
            BensCompanion.insert(
              tombamento: '077001',
              unidadeId: 'u1',
              descricao: 'Cadeira Ergonômica',
              localEsperadoId: 'sala_homologada',
            ),
          );
      await db.into(db.bens).insert(
            BensCompanion.insert(
              tombamento: '077002',
              unidadeId: 'u1',
              descricao: 'Mesa Reunião',
              localEsperadoId: 'sala_pendente',
            ),
          );

      // Leitura na sala homologada
      final evLido = await EventoV2.criar(
        id: 'ev-lido-77001',
        unidadeId: 'u1',
        tipo: TiposEvento.leitura,
        autor: pubGestor,
        seq: 1,
        hashAnterior: EventoV2.hashInicial,
        conhecidos: {},
        payload: {
          'tombamento': '077001',
          'local_id': 'sala_homologada',
          'conferente': 'Gestor',
        },
        keyPair: parGestor,
      );
      await EventoService.aplicarEventoExterno(db: db, evento: evLido);

      // Antes da homologação: nenhum bem homologado
      var bensHomologados = await HomologacaoService.obterBensHomologados(db);
      expect(bensHomologados, isEmpty);

      // Gestor homologa a sala
      final evHomologacao = await HomologacaoService.homologarSala(
        db: db,
        unidadeId: 'u1',
        salaId: 'sala_homologada',
        keyPairGestor: parGestor,
        observacao: 'Conferência de Vara Única 100% conferida e auditada.',
      );

      expect(evHomologacao.tipo, equals(TiposEvento.homologacao));

      // Após a homologação: apenas o bem da sala homologada entra
      bensHomologados = await HomologacaoService.obterBensHomologados(db);
      expect(bensHomologados.length, equals(1));
      expect(bensHomologados.first.tombamento, equals('077001'));

      final statusSalas = await HomologacaoService.obterStatusSalas(db);
      final statusVara = statusSalas.firstWhere((s) => s.salaId == 'sala_homologada');
      expect(statusVara.homologada, isTrue);
      expect(statusVara.observacao, contains('auditada'));

      await db.close();
    });
  });
}
