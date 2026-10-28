import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Carimbo v2: borda colorida pela situação, raio 3, ícone de traço e texto
class Carimbo extends StatelessWidget {
  final String titulo;
  final String? detalhe;
  final Color cor;
  final IconData icone;

  const Carimbo({
    super.key,
    required this.titulo,
    this.detalhe,
    required this.cor,
    required this.icone,
  });

  /// Carimbo pré-configurado para cada situação
  factory Carimbo.conferido({String? detalhe}) => Carimbo(
        titulo: 'Conferido na sala esperada',
        detalhe: detalhe,
        cor: AppTokens.statusConferido,
        icone: AppTokens.iconeConferido,
      );

  factory Carimbo.outraSala({String? detalhe}) => Carimbo(
        titulo: 'Encontrado em outra sala',
        detalhe: detalhe,
        cor: AppTokens.statusOutraSala,
        icone: AppTokens.iconeOutraSala,
      );

  factory Carimbo.semCadastro({String? detalhe}) => Carimbo(
        titulo: 'Sem cadastro na unidade',
        detalhe: detalhe,
        cor: AppTokens.statusSemCadastro,
        icone: AppTokens.iconeSemCadastro,
      );

  factory Carimbo.pendente({String? detalhe}) => Carimbo(
        titulo: 'Pendente de conferência',
        detalhe: detalhe,
        cor: AppTokens.statusPendente,
        icone: AppTokens.iconePendente,
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTokens.brancoEscuro : AppTokens.branco;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTokens.raioCarimbo),
        border: Border.all(color: cor, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icone, size: 18, color: cor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontFamily: AppTokens.fontePadrao,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cor,
                  ),
                ),
                if (detalhe != null && detalhe!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    detalhe!,
                    style: TextStyle(
                      fontFamily: AppTokens.fontePadrao,
                      fontSize: 13,
                      color: isDark ? AppTokens.cinzaEscuro : AppTokens.cinza,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
