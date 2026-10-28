import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Barra segmentada de situação (altura 10, raio 2, segmentos proporcionais)
class BarraSituacao extends StatelessWidget {
  final int conferidos;
  final int outraSala;
  final int semCadastro;
  final int pendentes;

  const BarraSituacao({
    super.key,
    required this.conferidos,
    required this.outraSala,
    required this.semCadastro,
    required this.pendentes,
  });

  int get _total => conferidos + outraSala + semCadastro + pendentes;

  @override
  Widget build(BuildContext context) {
    final total = _total;
    if (total == 0) {
      return Container(
        height: 10,
        decoration: BoxDecoration(
          color: AppTokens.statusPendente.withAlpha(60),
          borderRadius: BorderRadius.circular(AppTokens.raioBarra),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.raioBarra),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            if (conferidos > 0)
              Flexible(
                flex: conferidos,
                child: Container(color: AppTokens.statusConferido),
              ),
            if (outraSala > 0)
              Flexible(
                flex: outraSala,
                child: Container(color: AppTokens.statusOutraSala),
              ),
            if (semCadastro > 0)
              Flexible(
                flex: semCadastro,
                child: Container(color: AppTokens.statusSemCadastro),
              ),
            if (pendentes > 0)
              Flexible(
                flex: pendentes,
                child: Container(color: AppTokens.statusPendente),
              ),
          ],
        ),
      ),
    );
  }
}

/// Legenda de situação: linhas com quadrado colorido, rótulo e número
class LegendaSituacao extends StatelessWidget {
  final int conferidos;
  final int outraSala;
  final int semCadastro;
  final int pendentes;

  const LegendaSituacao({
    super.key,
    required this.conferidos,
    required this.outraSala,
    required this.semCadastro,
    required this.pendentes,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTokens.grafiteEscuro : AppTokens.grafite;
    final dividerColor = isDark ? AppTokens.linhaEscura : AppTokens.linha;

    return Column(
      children: [
        _linhaLegenda('Conferidos', conferidos, AppTokens.statusConferido, textColor),
        Divider(height: 1, color: dividerColor),
        _linhaLegenda('Em outra sala', outraSala, AppTokens.statusOutraSala, textColor),
        Divider(height: 1, color: dividerColor),
        _linhaLegenda('Sem cadastro', semCadastro, AppTokens.statusSemCadastro, textColor),
        Divider(height: 1, color: dividerColor),
        _linhaLegenda('Pendentes', pendentes, AppTokens.statusPendente, textColor),
      ],
    );
  }

  Widget _linhaLegenda(String rotulo, int valor, Color cor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: cor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              rotulo,
              style: TextStyle(
                fontFamily: AppTokens.fontePadrao,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: textColor,
              ),
            ),
          ),
          Text(
            '$valor',
            style: TextStyle(
              fontFamily: AppTokens.fontePadrao,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
              fontFeatures: AppTokens.algarismosTabulares,
            ),
          ),
        ],
      ),
    );
  }
}
