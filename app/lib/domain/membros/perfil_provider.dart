import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'membro_models.dart';

/// Notifier para o papel do usuário ativo na sessão do app (Gestor vs Conferente)
class PerfilUsuarioNotifier extends Notifier<PapelUsuario> {
  @override
  PapelUsuario build() {
    // Por padrão o app inicia em modo Gestor para permitir demonstração completa
    return PapelUsuario.gestor;
  }

  void alternarPerfil() {
    state = state == PapelUsuario.gestor ? PapelUsuario.conferente : PapelUsuario.gestor;
  }

  void definirPerfil(PapelUsuario novoPapel) {
    state = novoPapel;
  }
}

final perfilUsuarioProvider = NotifierProvider<PerfilUsuarioNotifier, PapelUsuario>(
  PerfilUsuarioNotifier.new,
);
