import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/chip_status.dart';
import 'app_database.dart';
import 'database_provider.dart';

class SalaComProgresso {
  final String id;
  final String nome;
  final String predioEAndar;
  final String caminhoCompleto;
  final int totalBens;
  final int bensLidos;
  final int divergencias;
  final String status;

  const SalaComProgresso({
    required this.id,
    required this.nome,
    required this.predioEAndar,
    required this.caminhoCompleto,
    required this.totalBens,
    required this.bensLidos,
    this.divergencias = 0,
    required this.status,
  });

  double get progresso => totalBens > 0 ? (bensLidos / totalBens).clamp(0.0, 1.0) : 0.0;
}

class EstatisticasUnidade {
  final int totalBens;
  final int totalConferidos;
  final double percentualConferido;
  final int divergenciasAbertas;
  final int salasPendentes;
  final int salasTotal;

  const EstatisticasUnidade({
    required this.totalBens,
    required this.totalConferidos,
    required this.percentualConferido,
    required this.divergenciasAbertas,
    required this.salasPendentes,
    required this.salasTotal,
  });

  double get progressoGeral => totalBens > 0 ? (totalConferidos / totalBens).clamp(0.0, 1.0) : 0.0;
}

class BemComStatus {
  final Bem bem;
  final String localNome;
  final String localCaminhoCurto;
  final StatusBem status;

  const BemComStatus({
    required this.bem,
    required this.localNome,
    required this.localCaminhoCurto,
    required this.status,
  });
}

class DadosConferenciaSala {
  final Local sala;
  final List<Bem> bensEsperados;
  final List<Bem> todosBensUnidade;
  final Set<String> tombamentosLidos;
  final Set<String> tombamentosOutraSala;
  final String migalhas;

  const DadosConferenciaSala({
    required this.sala,
    required this.bensEsperados,
    required this.todosBensUnidade,
    required this.tombamentosLidos,
    required this.tombamentosOutraSala,
    required this.migalhas,
  });
}

final unidadesStreamProvider = StreamProvider<List<Unidade>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.unidades).watch();
});

class UnidadeAtivaIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  @override
  set state(String? value) => super.state = value;
}

final unidadeAtivaIdProvider = NotifierProvider<UnidadeAtivaIdNotifier, String?>(
  UnidadeAtivaIdNotifier.new,
);

final unidadeAtivaProvider = Provider<Unidade?>((ref) {
  final unidadesAsync = ref.watch(unidadesStreamProvider);
  final ativaId = ref.watch(unidadeAtivaIdProvider);

  return unidadesAsync.maybeWhen(
    data: (lista) {
      if (lista.isEmpty) return null;
      if (ativaId != null) {
        return lista.firstWhere((u) => u.id == ativaId, orElse: () => lista.first);
      }
      return lista.first;
    },
    orElse: () => null,
  );
});

final salasStreamProvider = StreamProvider<List<SalaComProgresso>>((ref) {
  final db = ref.watch(databaseProvider);

  return db.select(db.locais).watch().asyncMap((locais) async {
    final salas = locais.where((l) => l.tipo == 'sala').toList();
    final conferencias = await db.select(db.conferenciaSalas).get();
    final mapaConf = {for (var c in conferencias) c.localId: c};

    final todosBens = await db.select(db.bens).get();
    final eventosLeitura = await (db.select(db.eventos)
          ..where((e) => e.tipo.isIn(const ['LEITURA', 'CONFIRMACAO'])))
        .get();

    final tombamentosLidos = eventosLeitura
        .map((e) => e.tombamento)
        .where((t) => t != null)
        .toSet();

    final resultado = <SalaComProgresso>[];

    for (final sala in salas) {
      final partes = sala.caminhoCompleto.split('/');
      String predioEAndar = 'Geral';
      if (partes.length >= 3) {
        predioEAndar = '${partes[1].trim()} / ${partes[2].trim()}';
      } else if (partes.length >= 2) {
        predioEAndar = partes[1].trim();
      }

      final bensDaSala =
          todosBens.where((b) => b.localEsperadoId == sala.id).toList();
      final lidosNaSala = bensDaSala
          .where((b) => tombamentosLidos.contains(b.tombamento))
          .length;

      // Divergências da sala: leituras nesta sala de bens que pertenciam a outra sala
      final eventosNestaSala = eventosLeitura.where((e) => e.localId == sala.id);
      final tombamentosEsperadosSet = bensDaSala.map((b) => b.tombamento).toSet();
      final divergencias = eventosNestaSala
          .map((e) => e.tombamento)
          .where((t) => t != null && !tombamentosEsperadosSet.contains(t))
          .toSet()
          .length;

      final conf = mapaConf[sala.id];
      String status = conf?.status ?? 'nao_iniciada';
      if (status == 'nao_iniciada' && lidosNaSala > 0) {
        status = 'em_andamento';
      }

      resultado.add(
        SalaComProgresso(
          id: sala.id,
          nome: sala.nome,
          predioEAndar: predioEAndar,
          caminhoCompleto: sala.caminhoCompleto,
          totalBens: bensDaSala.length,
          bensLidos: lidosNaSala,
          divergencias: divergencias,
          status: status,
        ),
      );
    }

    return resultado;
  });
});

final estatisticasUnidadeProvider = StreamProvider<EstatisticasUnidade>((ref) {
  final db = ref.watch(databaseProvider);

  return db.select(db.bens).watch().asyncMap((todosBens) async {
    final todosLocais = await db.select(db.locais).get();
    final salas = todosLocais.where((l) => l.tipo == 'sala').toList();
    final conferencias = await db.select(db.conferenciaSalas).get();
    final mapaConf = {for (var c in conferencias) c.localId: c};

    final eventosLeitura = await (db.select(db.eventos)
          ..where((e) => e.tipo.isIn(const ['LEITURA', 'CONFIRMACAO'])))
        .get();

    final tombamentosLidos = eventosLeitura
        .map((e) => e.tombamento)
        .where((t) => t != null)
        .toSet();

    final totalBens = todosBens.length;
    final totalConferidos = todosBens
        .where((b) => tombamentosLidos.contains(b.tombamento))
        .length;

    int salasPendentes = 0;
    for (final s in salas) {
      final conf = mapaConf[s.id];
      if (conf?.status != 'fechada') {
        salasPendentes++;
      }
    }

    // Divergências: bens lidos em locais divergentes do esperado
    final mapaBens = {for (var b in todosBens) b.tombamento: b};
    int divergenciasAbertas = 0;
    for (final e in eventosLeitura) {
      if (e.tombamento != null) {
        final bem = mapaBens[e.tombamento];
        if (bem != null && bem.localEsperadoId != e.localId) {
          divergenciasAbertas++;
        }
      }
    }

    final percentual = totalBens > 0 ? (totalConferidos / totalBens) * 100 : 0.0;

    return EstatisticasUnidade(
      totalBens: totalBens,
      totalConferidos: totalConferidos,
      percentualConferido: percentual,
      divergenciasAbertas: divergenciasAbertas,
      salasPendentes: salasPendentes,
      salasTotal: salas.length,
    );
  });
});

final bensComStatusStreamProvider = StreamProvider<List<BemComStatus>>((ref) {
  final db = ref.watch(databaseProvider);

  return db.select(db.bens).watch().asyncMap((todosBens) async {
    final todosLocais = await db.select(db.locais).get();
    final mapaLocais = {for (var l in todosLocais) l.id: l};

    final eventosLeitura = await (db.select(db.eventos)
          ..where((e) => e.tipo.isIn(const ['LEITURA', 'CONFIRMACAO'])))
        .get();

    final mapaUltimoEvento = <String, Evento>{};
    for (final e in eventosLeitura) {
      if (e.tombamento != null) {
        mapaUltimoEvento[e.tombamento!] = e;
      }
    }

    final resultado = <BemComStatus>[];

    for (final b in todosBens) {
      final local = mapaLocais[b.localEsperadoId];
      final localNome = local?.nome ?? 'Sem local';

      String localCurto = localNome;
      if (local != null && local.caminhoCompleto.contains('/')) {
        final partes = local.caminhoCompleto.split('/');
        if (partes.length >= 3) {
          localCurto = '${partes[partes.length - 2].trim()} › ${partes.last.trim()}';
        }
      }

      StatusBem status = StatusBem.pendente;
      final ultimoEvt = mapaUltimoEvento[b.tombamento];
      if (ultimoEvt != null) {
        if (ultimoEvt.localId == b.localEsperadoId) {
          status = StatusBem.encontrado;
        } else {
          status = StatusBem.outraSala;
        }
      }

      resultado.add(
        BemComStatus(
          bem: b,
          localNome: localNome,
          localCaminhoCurto: localCurto,
          status: status,
        ),
      );
    }

    return resultado;
  });
});

final dadosConferenciaSalaProvider =
    StreamProvider.family<DadosConferenciaSala, String>((ref, salaId) {
  final db = ref.watch(databaseProvider);

  return db.select(db.locais).watch().asyncMap((locais) async {
    final salas = locais.where((l) => l.tipo == 'sala').toList();
    final sala = salas.firstWhere(
      (l) => l.id == salaId,
      orElse: () => salas.isNotEmpty
          ? salas.first
          : Local(
              id: salaId,
              unidadeId: '',
              nome: 'Sala $salaId',
              tipo: 'sala',
              caminhoCompleto: 'Sala $salaId',
            ),
    );

    final todosBens = await db.select(db.bens).get();
    final bensEsperados =
        todosBens.where((b) => b.localEsperadoId == sala.id).toList();

    final eventosSala = await (db.select(db.eventos)
          ..where((e) => e.localId.equals(sala.id)))
        .get();

    final tombamentosLidos = <String>{};
    final tombamentosOutraSala = <String>{};

    for (final evt in eventosSala) {
      if (evt.tombamento != null) {
        if (bensEsperados.any((b) => b.tombamento == evt.tombamento)) {
          tombamentosLidos.add(evt.tombamento!);
        } else {
          tombamentosOutraSala.add(evt.tombamento!);
        }
      }
    }

    final partes = sala.caminhoCompleto
        .split('/')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    final migalhas = partes.length > 1
        ? partes.sublist(0, partes.length - 1).join(' › ')
        : (partes.isNotEmpty ? partes.first : '');

    return DadosConferenciaSala(
      sala: sala,
      bensEsperados: bensEsperados,
      todosBensUnidade: todosBens,
      tombamentosLidos: tombamentosLidos,
      tombamentosOutraSala: tombamentosOutraSala,
      migalhas: migalhas,
    );
  });
});
