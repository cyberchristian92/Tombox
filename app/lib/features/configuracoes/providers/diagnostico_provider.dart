import 'package:flutter_riverpod/flutter_riverpod.dart';

final modoDiagnosticoProvider = NotifierProvider<ModoDiagnosticoNotifier, bool>(
  ModoDiagnosticoNotifier.new,
);

class ModoDiagnosticoNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }

  void setEnabled(bool value) {
    state = value;
  }
}
