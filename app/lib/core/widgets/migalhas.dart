import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Migalhas v2 em texto simples ("Breves, Fórum Juiz Vicente, Térreo")
class Migalhas extends StatelessWidget {
  final List<String> partes;
  final void Function(int index, String parte)? onParteTap;
  final double fontSize;

  const Migalhas({
    super.key,
    required this.partes,
    this.onParteTap,
    this.fontSize = 13.0,
  });

  factory Migalhas.fromCaminho(
    String caminho, {
    void Function(int index, String parte)? onParteTap,
    double fontSize = 13.0,
  }) {
    final partesLimpos = caminho
        .split(RegExp(r'[/›,]'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    return Migalhas(
      partes: partesLimpos,
      onParteTap: onParteTap,
      fontSize: fontSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (partes.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final corTexto = isDark ? AppTokens.cinzaEscuro : AppTokens.cinza;

    final texto = partes.join(', ');

    return Text(
      texto,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: AppTokens.fontePadrao,
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: corTexto,
      ),
    );
  }
}
