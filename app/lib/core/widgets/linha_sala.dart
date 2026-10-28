import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Linha de sala v2: nome SemiBold, andar cinza, barra de 4px, contador
class LinhaSala extends StatelessWidget {
  final String nome;
  final String? andar;
  final int totalBens;
  final int bensLidos;
  final VoidCallback? onTap;

  const LinhaSala({
    super.key,
    required this.nome,
    this.andar,
    required this.totalBens,
    required this.bensLidos,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTokens.grafiteEscuro : AppTokens.grafite;
    final subColor = isDark ? AppTokens.cinzaEscuro : AppTokens.cinza;
    final barBg = isDark ? AppTokens.linhaEscura : AppTokens.linha;
    final progresso = totalBens > 0 ? (bensLidos / totalBens).clamp(0.0, 1.0) : 0.0;

    Color barColor;
    if (bensLidos >= totalBens && totalBens > 0) {
      barColor = AppTokens.statusConferido;
    } else if (bensLidos > 0) {
      barColor = AppTokens.statusOutraSala;
    } else {
      barColor = AppTokens.statusPendente;
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTokens.fontePadrao,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      if (andar != null && andar!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          andar!,
                          style: TextStyle(
                            fontFamily: AppTokens.fontePadrao,
                            fontSize: 13,
                            color: subColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$bensLidos/$totalBens',
                  style: AppTokens.contadorNumero.copyWith(
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.raioBarra),
              child: LinearProgressIndicator(
                value: progresso,
                minHeight: 4,
                backgroundColor: barBg,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
