import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/app_database.dart';
import '../eventos/evento_service.dart';
import '../eventos/evento_v2.dart';
import '../identidade/identidade_service.dart';
import 'membro_models.dart';

/// Serviço responsável pelo gerenciamento de comissões, papéis e convites
class MembroService {
  static const _uuid = Uuid();
  static final Map<String, ConviteMembro> _convitesAtivos = {};

  /// Eventos que exigem estritamente perfil de Gestor Patrimonial
  static const Set<String> eventosExclusivosGestor = {
    TiposEvento.unidadeCriada,
    TiposEvento.membroAdicionado,
    TiposEvento.membroRevogado,
    TiposEvento.homologacao,
    TiposEvento.divergenciaResolvida,
  };

  /// Valida se determinado papel possui autorização para emitir o tipo de evento
  static bool verificarPermissao(PapelUsuario papel, String tipoEvento) {
    if (papel == PapelUsuario.gestor) {
      return true; // Gestor tem acesso irrestrito
    }
    // Conferente não pode emitir eventos administrativos
    return !eventosExclusivosGestor.contains(tipoEvento);
  }

  /// Projeta a lista de membros e seus estados a partir dos eventos da unidade
  static Future<List<Membro>> obterMembros(
    AppDatabase db, {
    String? unidadeId,
  }) async {
    final query = db.select(db.eventos);
    if (unidadeId != null && unidadeId.isNotEmpty) {
      query.where((tbl) => tbl.unidadeId.equals(unidadeId));
    }
    query.orderBy([(tbl) => OrderingTerm.asc(tbl.seq)]);
    final eventos = await query.get();

    final membrosPorChave = <String, Membro>{};

    for (final e in eventos) {
      Map<String, dynamic> payload = {};
      try {
        final dec = jsonDecode(e.payload);
        if (dec is Map) payload = Map<String, dynamic>.from(dec);
      } catch (_) {}

      // 1. O autor do evento de criação da unidade é o Gestor Fundador
      if (e.tipo == TiposEvento.unidadeCriada) {
        membrosPorChave[e.autor] = Membro(
          chavePublica: e.autor,
          nome: payload['gestor_nome']?.toString() ?? 'Gestor Fundador',
          matricula: payload['gestor_matricula']?.toString() ?? 'TJPA-0001',
          papel: PapelUsuario.gestor,
          ativo: true,
          dataIngresso: e.timestamp,
        );
      }

      // 2. Membro adicionado por um gestor
      if (e.tipo == TiposEvento.membroAdicionado) {
        final chave = payload['chave_publica']?.toString() ?? '';
        if (chave.isNotEmpty) {
          membrosPorChave[chave] = Membro(
            chavePublica: chave,
            nome: payload['nome']?.toString() ?? 'Conferente',
            matricula: payload['matricula']?.toString() ?? 'TJPA-AUTO',
            papel: PapelUsuario.aPartirDeTexto(payload['papel']?.toString()),
            ativo: true,
            dataIngresso: e.timestamp,
          );
        }
      }

      // 3. Membro revogado
      if (e.tipo == TiposEvento.membroRevogado) {
        final chave = payload['chave_publica']?.toString() ?? '';
        final membroExistente = membrosPorChave[chave];
        if (membroExistente != null) {
          membrosPorChave[chave] = Membro(
            chavePublica: chave,
            nome: membroExistente.nome,
            matricula: membroExistente.matricula,
            papel: membroExistente.papel,
            ativo: false,
            dataIngresso: membroExistente.dataIngresso,
            revogadoPor: e.autor,
            dataRevogacao: e.timestamp,
            motivoRevogacao: payload['motivo']?.toString() ?? 'Revogado pelo gestor',
          );
        }
      }
    }

    return membrosPorChave.values.toList();
  }

  /// Retorna o papel ativo de um membro ou null se não for membro ativo
  static Future<PapelUsuario?> obterPapel(
    AppDatabase db,
    String chavePublica, {
    String? unidadeId,
  }) async {
    final membros = await obterMembros(db, unidadeId: unidadeId);
    for (final m in membros) {
      if (m.chavePublica == chavePublica && m.ativo) {
        return m.papel;
      }
    }
    return null;
  }

  /// Verifica se o autor é membro ativo da unidade
  static Future<bool> isAutorAtivo(
    AppDatabase db,
    String chavePublica, {
    String? unidadeId,
  }) async {
    final papel = await obterPapel(db, chavePublica, unidadeId: unidadeId);
    return papel != null;
  }

  /// Retorna conjunto de chaves públicas de autores revogados
  static Future<Set<String>> obterChavesRevogadas(
    AppDatabase db, {
    String? unidadeId,
  }) async {
    final membros = await obterMembros(db, unidadeId: unidadeId);
    return membros.where((m) => !m.ativo).map((m) => m.chavePublica).toSet();
  }

  /// Gera um convite de uso único com QR Code para um novo aparelho entrar na unidade
  static ConviteMembro gerarConvite({
    required String unidadeId,
    required String gestorChavePublica,
    PapelUsuario papel = PapelUsuario.conferente,
    Duration validade = const Duration(minutes: 15),
  }) {
    final codigo = _uuid.v4().substring(0, 8).toUpperCase();
    final agora = DateTime.now().toUtc();
    final expiraEm = agora.add(validade);

    final convite = ConviteMembro(
      codigo: codigo,
      unidadeId: unidadeId,
      papel: papel,
      criadoPor: gestorChavePublica,
      criadoEm: agora,
      expiraEm: expiraEm,
    );

    _convitesAtivos[codigo] = convite;
    return convite;
  }

  /// Valida e consome um código de convite de uso único
  static ConviteMembro validarEConsumirConvite(String codigo, {required String chavePublicaMembro}) {
    final convite = _convitesAtivos[codigo];
    if (convite == null) {
      throw Exception('Código de convite não encontrado ou inexistente.');
    }
    if (convite.usado) {
      throw Exception('Este convite já foi utilizado anteriormente.');
    }
    if (convite.expirado) {
      throw Exception('O convite expirou. Solicite um novo QR Code ao gestor.');
    }

    final conviteConsumido = ConviteMembro(
      codigo: convite.codigo,
      unidadeId: convite.unidadeId,
      papel: convite.papel,
      criadoPor: convite.criadoPor,
      criadoEm: convite.criadoEm,
      expiraEm: convite.expiraEm,
      usado: true,
      usadoPor: chavePublicaMembro,
    );

    _convitesAtivos[codigo] = conviteConsumido;
    return conviteConsumido;
  }

  /// Emite evento MEMBRO_ADICIONADO assinado pelo Gestor
  static Future<EventoV2> adicionarMembro({
    required AppDatabase db,
    required String unidadeId,
    required String chavePublicaNovoMembro,
    required String nome,
    required String matricula,
    required PapelUsuario papel,
    required SimpleKeyPair keyPairGestor,
  }) async {
    final autorGestor = IdentidadeService.bytesParaHex(
      (await keyPairGestor.extractPublicKey()).bytes,
    );

    // 1. Obter maior sequência e hash anterior do gestor
    final ultimoEventoGestor = await (db.select(db.eventos)
          ..where((tbl) => tbl.autor.equals(autorGestor))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.seq)])
          ..limit(1))
        .getSingleOrNull();

    final seq = (ultimoEventoGestor?.seq ?? 0) + 1;
    final hashAnterior = ultimoEventoGestor?.hash ?? EventoV2.hashInicial;

    final todosEventos = await db.select(db.eventos).get();
    final conhecidos = <String, String>{};
    for (final e in todosEventos) {
      if (e.autor != autorGestor && e.autor.isNotEmpty) {
        conhecidos[e.autor] = e.hash;
      }
    }

    final evento = await EventoV2.criar(
      id: _uuid.v4(),
      unidadeId: unidadeId,
      tipo: TiposEvento.membroAdicionado,
      autor: autorGestor,
      seq: seq,
      hashAnterior: hashAnterior,
      conhecidos: conhecidos,
      payload: {
        'chave_publica': chavePublicaNovoMembro,
        'nome': nome,
        'matricula': matricula,
        'papel': papel.name,
      },
      keyPair: keyPairGestor,
    );

    await EventoService.aplicarEventoExterno(db: db, evento: evento);
    return evento;
  }

  /// Emite evento MEMBRO_REVOGADO assinado pelo Gestor
  static Future<EventoV2> revogarMembro({
    required AppDatabase db,
    required String unidadeId,
    required String chavePublicaMembroRevogado,
    required String motivo,
    required SimpleKeyPair keyPairGestor,
  }) async {
    final autorGestor = IdentidadeService.bytesParaHex(
      (await keyPairGestor.extractPublicKey()).bytes,
    );

    final ultimoEventoGestor = await (db.select(db.eventos)
          ..where((tbl) => tbl.autor.equals(autorGestor))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.seq)])
          ..limit(1))
        .getSingleOrNull();

    final seq = (ultimoEventoGestor?.seq ?? 0) + 1;
    final hashAnterior = ultimoEventoGestor?.hash ?? EventoV2.hashInicial;

    final todosEventos = await db.select(db.eventos).get();
    final conhecidos = <String, String>{};
    for (final e in todosEventos) {
      if (e.autor != autorGestor && e.autor.isNotEmpty) {
        conhecidos[e.autor] = e.hash;
      }
    }

    final evento = await EventoV2.criar(
      id: _uuid.v4(),
      unidadeId: unidadeId,
      tipo: TiposEvento.membroRevogado,
      autor: autorGestor,
      seq: seq,
      hashAnterior: hashAnterior,
      conhecidos: conhecidos,
      payload: {
        'chave_publica': chavePublicaMembroRevogado,
        'motivo': motivo,
      },
      keyPair: keyPairGestor,
    );

    await EventoService.aplicarEventoExterno(db: db, evento: evento);
    return evento;
  }

  /// Limpa convites de teste
  static void limparParaTestes() {
    _convitesAtivos.clear();
  }
}
