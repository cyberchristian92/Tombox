import 'package:flutter_test/flutter_test.dart';
import 'package:tombox/domain/eventos/evento_v2.dart';
import 'package:tombox/domain/eventos/evento_validador.dart';
import 'package:tombox/domain/identidade/identidade_service.dart';

void main() {
  setUp(() {
    IdentidadeService.resetarInstanciaParaTestes();
  });

  group('Validação de Eventos Criptográficos (Arquitetura v2)', () {
    test('Evento criado corretamente é aprovado na validação', () async {
      final idAparelho = await IdentidadeService.obterOuCriarIdentidade();

      final evento1 = await EventoV2.criar(
        id: 'evt-001',
        unidadeId: 'unidade_belem',
        tipo: TiposEvento.leitura,
        autor: idAparelho.publicKeyHex,
        seq: 1,
        hashAnterior: EventoV2.hashInicial,
        conhecidos: {},
        payload: {'tombamento': '010001', 'local_id': 'sala_101'},
      );

      final resultado = await EventoValidador.validar(evento: evento1);
      expect(resultado.valido, isTrue);
      expect(resultado.motivo, isNull);
    });

    test('Rejeita evento cujo payload foi adulterado (hash inválido)', () async {
      final idAparelho = await IdentidadeService.obterOuCriarIdentidade();

      final eventoOriginal = await EventoV2.criar(
        id: 'evt-002',
        unidadeId: 'unidade_belem',
        tipo: TiposEvento.leitura,
        autor: idAparelho.publicKeyHex,
        seq: 1,
        hashAnterior: EventoV2.hashInicial,
        conhecidos: {},
        payload: {'tombamento': '010001', 'estado': 'bom'},
      );

      // Adulteração do payload sem recalcular hash
      final eventoAdulterado = EventoV2(
        id: eventoOriginal.id,
        unidadeId: eventoOriginal.unidadeId,
        tipo: eventoOriginal.tipo,
        autor: eventoOriginal.autor,
        seq: eventoOriginal.seq,
        hashAnterior: eventoOriginal.hashAnterior,
        conhecidos: eventoOriginal.conhecidos,
        timestamp: eventoOriginal.timestamp,
        payload: {'tombamento': '010001', 'estado': 'inservivel'}, // <- adulterado!
        hash: eventoOriginal.hash,
        assinatura: eventoOriginal.assinatura,
      );

      final resultado = await EventoValidador.validar(evento: eventoAdulterado);
      expect(resultado.valido, isFalse);
      expect(resultado.motivo, equals(MotivoRejeicao.hashInvalido));
    });

    test('Rejeita evento com assinatura forjada ou corrompida', () async {
      final idAparelho = await IdentidadeService.obterOuCriarIdentidade();

      final evento = await EventoV2.criar(
        id: 'evt-003',
        unidadeId: 'unidade_belem',
        tipo: TiposEvento.confirmacao,
        autor: idAparelho.publicKeyHex,
        seq: 1,
        hashAnterior: EventoV2.hashInicial,
        conhecidos: {},
        payload: {'tombamento': '010002'},
      );

      // Corrompe os últimos 2 bytes da assinatura
      final assinaturaCorrompida =
          '${evento.assinatura.substring(0, evento.assinatura.length - 2)}ff';

      final eventoComAssinaturaFalsa = EventoV2(
        id: evento.id,
        unidadeId: evento.unidadeId,
        tipo: evento.tipo,
        autor: evento.autor,
        seq: evento.seq,
        hashAnterior: evento.hashAnterior,
        conhecidos: evento.conhecidos,
        timestamp: evento.timestamp,
        payload: evento.payload,
        hash: evento.hash,
        assinatura: assinaturaCorrompida,
      );

      final resultado = await EventoValidador.validar(evento: eventoComAssinaturaFalsa);
      expect(resultado.valido, isFalse);
      expect(resultado.motivo, equals(MotivoRejeicao.assinaturaInvalida));
    });

    test('Rejeita evento com quebra de sequência (buraco no seq)', () async {
      final idAparelho = await IdentidadeService.obterOuCriarIdentidade();

      final evento1 = await EventoV2.criar(
        id: 'evt-seq-1',
        unidadeId: 'unidade_belem',
        tipo: TiposEvento.leitura,
        autor: idAparelho.publicKeyHex,
        seq: 1,
        hashAnterior: EventoV2.hashInicial,
        conhecidos: {},
        payload: {'item': 1},
      );

      // Evento 2 pula direto para seq = 3
      final eventoComBuraco = await EventoV2.criar(
        id: 'evt-seq-3',
        unidadeId: 'unidade_belem',
        tipo: TiposEvento.leitura,
        autor: idAparelho.publicKeyHex,
        seq: 3, // Pulo ilegal de 1 para 3
        hashAnterior: evento1.hash,
        conhecidos: {},
        payload: {'item': 3},
      );

      final resultado = await EventoValidador.validar(
        evento: eventoComBuraco,
        ultimoEventoDoAutor: evento1,
      );

      expect(resultado.valido, isFalse);
      expect(resultado.motivo, equals(MotivoRejeicao.seqDescontinuo));
    });

    test('Rejeita evento com hash_anterior inconsistente', () async {
      final idAparelho = await IdentidadeService.obterOuCriarIdentidade();

      final evento1 = await EventoV2.criar(
        id: 'evt-chain-1',
        unidadeId: 'unidade_belem',
        tipo: TiposEvento.leitura,
        autor: idAparelho.publicKeyHex,
        seq: 1,
        hashAnterior: EventoV2.hashInicial,
        conhecidos: {},
        payload: {'passo': 1},
      );

      // Evento 2 com seq = 2 correto, mas hashAnterior forjado
      final eventoCadeiaQuebrada = await EventoV2.criar(
        id: 'evt-chain-2',
        unidadeId: 'unidade_belem',
        tipo: TiposEvento.leitura,
        autor: idAparelho.publicKeyHex,
        seq: 2,
        hashAnterior: '1111111111111111111111111111111111111111111111111111111111111111',
        conhecidos: {},
        payload: {'passo': 2},
      );

      final resultado = await EventoValidador.validar(
        evento: eventoCadeiaQuebrada,
        ultimoEventoDoAutor: evento1,
      );

      expect(resultado.valido, isFalse);
      expect(resultado.motivo, equals(MotivoRejeicao.hashAnteriorInvalido));
    });

    test('Rejeita eventos criados por membro revogado', () async {
      final idAparelho = await IdentidadeService.obterOuCriarIdentidade();

      final evento = await EventoV2.criar(
        id: 'evt-revogado-1',
        unidadeId: 'unidade_belem',
        tipo: TiposEvento.leitura,
        autor: idAparelho.publicKeyHex,
        seq: 1,
        hashAnterior: EventoV2.hashInicial,
        conhecidos: {},
        payload: {},
      );

      final autoresRevogados = {idAparelho.publicKeyHex};

      final resultado = await EventoValidador.validar(
        evento: evento,
        autoresRevogados: autoresRevogados,
      );

      expect(resultado.valido, isFalse);
      expect(resultado.motivo, equals(MotivoRejeicao.autorRevogado));
    });

    test('Geração determinística de hash canônico independente da ordem de chaves', () {
      final agora = DateTime.utc(2026, 10, 28, 12, 0, 0);

      final mapa1 = {
        'id': 'evt-canonico',
        'unidade_id': 'u1',
        'tipo': 'LEITURA',
        'autor': 'key1',
        'seq': 1,
        'hash_anterior': EventoV2.hashInicial,
        'conhecidos': {'autorB': 'hashB'},
        'timestamp': agora,
        'payload': {'z_campo': 1, 'a_campo': 2},
      };

      final mapa2 = {
        'payload': {'a_campo': 2, 'z_campo': 1},
        'unidade_id': 'u1',
        'id': 'evt-canonico',
        'autor': 'key1',
        'seq': 1,
        'timestamp': agora,
        'tipo': 'LEITURA',
        'conhecidos': {'autorB': 'hashB'},
        'hash_anterior': EventoV2.hashInicial,
      };

      final hash1 = EventoV2.calcularHash(
        id: mapa1['id'] as String,
        unidadeId: mapa1['unidade_id'] as String,
        tipo: mapa1['tipo'] as String,
        autor: mapa1['autor'] as String,
        seq: mapa1['seq'] as int,
        hashAnterior: mapa1['hash_anterior'] as String,
        conhecidos: mapa1['conhecidos'] as Map<String, String>,
        timestamp: mapa1['timestamp'] as DateTime,
        payload: mapa1['payload'] as Map<String, dynamic>,
      );

      final hash2 = EventoV2.calcularHash(
        id: mapa2['id'] as String,
        unidadeId: mapa2['unidade_id'] as String,
        tipo: mapa2['tipo'] as String,
        autor: mapa2['autor'] as String,
        seq: mapa2['seq'] as int,
        hashAnterior: mapa2['hash_anterior'] as String,
        conhecidos: mapa2['conhecidos'] as Map<String, String>,
        timestamp: mapa2['timestamp'] as DateTime,
        payload: mapa2['payload'] as Map<String, dynamic>,
      );

      expect(hash1, equals(hash2));
    });
  });
}
