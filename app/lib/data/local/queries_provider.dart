import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';
import 'database_provider.dart';

class SalaComProgresso {
  final String id;
  final String nome;
  final String predioEAndar;
  final String caminhoCompleto;
  final int totalBens;
  final int bensLidos;
  final String status;

  const SalaComProgresso({
    required this.id,
    required this.nome,
    required this.predioEAndar,
    required this.caminhoCompleto,
    required this.totalBens,
    required this.bensLidos,
    required this.status,
  });

  double get progresso => totalBens > 0 ? bensLidos / totalBens : 0.0;
}

final unidadesStreamProvider = StreamProvider<List<Unidade>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.unidades).watch();
});

final salasStreamProvider = StreamProvider<List<SalaComProgresso>>((ref) {
  final db = ref.watch(databaseProvider);

  // Observa salas, bens e conferencias
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
          status: status,
        ),
      );
    }

    return resultado;
  });
});
