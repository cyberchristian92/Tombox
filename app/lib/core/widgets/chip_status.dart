import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

enum StatusBem {
  encontrado,
  outraSala,
  naoCadastrado,
  pendente;

  static StatusBem fromString(String? val) {
    if (val == null) return StatusBem.pendente;
    final v = val.toLowerCase().replaceAll(' ', '_');
    if (v.contains('encontrad') || v.contains('lido') || v.contains('confirmado')) {
      return StatusBem.encontrado;
    }
    if (v.contains('outra')) {
      return StatusBem.outraSala;
    }
    if (v.contains('nao_cadastrado') || v.contains('nao_localizado') || v.contains('diverg')) {
      return StatusBem.naoCadastrado;
    }
    return StatusBem.pendente;
  }

  String get label {
    switch (this) {
      case StatusBem.encontrado:
        return 'Encontrado';
      case StatusBem.outraSala:
        return 'Outra Sala';
      case StatusBem.naoCadastrado:
        return 'Não Localizado';
      case StatusBem.pendente:
        return 'Pendente';
    }
  }

  Color get cor {
    switch (this) {
      case StatusBem.encontrado:
        return AppTokens.statusEncontrado;
      case StatusBem.outraSala:
        return AppTokens.statusOutraSala;
      case StatusBem.naoCadastrado:
        return AppTokens.statusNaoCadastrado;
      case StatusBem.pendente:
        return AppTokens.statusPendente;
    }
  }

  IconData get icone {
    switch (this) {
      case StatusBem.encontrado:
        return AppTokens.iconeEncontrado;
      case StatusBem.outraSala:
        return AppTokens.iconeOutraSala;
      case StatusBem.naoCadastrado:
        return AppTokens.iconeNaoCadastrado;
      case StatusBem.pendente:
        return AppTokens.iconePendente;
    }
  }
}

class ChipStatus extends StatelessWidget {
  final StatusBem status;
  final bool compacto;

  const ChipStatus({
    super.key,
    required this.status,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    final cor = status.cor;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 6.0 : 8.0,
        vertical: compacto ? 2.0 : 4.0,
      ),
      decoration: BoxDecoration(
        color: cor.withAlpha(25),
        borderRadius: BorderRadius.circular(AppTokens.raioChip),
        border: Border.all(color: cor.withAlpha(80), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icone, size: compacto ? 12 : 14, color: cor),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: cor,
              fontSize: compacto ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
