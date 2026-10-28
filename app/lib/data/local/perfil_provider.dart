import 'package:flutter_riverpod/flutter_riverpod.dart';

class PerfilUsuario {
  final String nome;
  final String matricula;
  final String papel; // 'conferente' ou 'gestor'
  final String aparelhoId;

  const PerfilUsuario({
    this.nome = '',
    this.matricula = '',
    this.papel = 'conferente',
    this.aparelhoId = 'dev-8f3a9c2b-e14d-4b92-971c-4b53ef12039a',
  });

  bool get configurado => nome.trim().isNotEmpty;

  PerfilUsuario copyWith({
    String? nome,
    String? matricula,
    String? papel,
    String? aparelhoId,
  }) {
    return PerfilUsuario(
      nome: nome ?? this.nome,
      matricula: matricula ?? this.matricula,
      papel: papel ?? this.papel,
      aparelhoId: aparelhoId ?? this.aparelhoId,
    );
  }
}

class PerfilNotifier extends Notifier<PerfilUsuario> {
  @override
  PerfilUsuario build() => const PerfilUsuario(
        nome: '',
        matricula: '',
        papel: 'conferente',
      );

  void carregarPerfilDemonstracao() {
    state = const PerfilUsuario(
      nome: 'Rosilene Silva',
      matricula: 'TJ-34587',
      papel: 'conferente',
    );
  }

  void atualizar({String? nome, String? matricula, String? papel}) {
    state = state.copyWith(
      nome: nome,
      matricula: matricula,
      papel: papel,
    );
  }

  void alternarPapel() {
    state = state.copyWith(
      papel: state.papel == 'conferente' ? 'gestor' : 'conferente',
    );
  }
}

final perfilProvider = NotifierProvider<PerfilNotifier, PerfilUsuario>(
  PerfilNotifier.new,
);
