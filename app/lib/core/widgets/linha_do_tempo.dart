import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_tokens.dart';

/// Item individual da linha do tempo
class ItemLinhaDoTempo {
  final DateTime dataHora;
  final String titulo;
  final String? detalhe;
  final Color? corMarcador;
  final bool? assinaturaValida;
  final String? hash;
  final String? autorCurto;

  const ItemLinhaDoTempo({
    required this.dataHora,
    required this.titulo,
    this.detalhe,
    this.corMarcador,
    this.assinaturaValida,
    this.hash,
    this.autorCurto,
  });
}

/// Linha do tempo v2: coluna de data/hora, traço vertical, marcador quadrado, texto
class LinhaDoTempo extends StatelessWidget {
  final List<ItemLinhaDoTempo> itens;

  const LinhaDoTempo({super.key, required this.itens});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTokens.grafiteEscuro : AppTokens.grafite;
    final subColor = isDark ? AppTokens.cinzaEscuro : AppTokens.cinza;
    final lineColor = isDark ? AppTokens.linhaEscura : AppTokens.linha;
    final fmtData = DateFormat('dd/MM', 'pt_BR');
    final fmtHora = DateFormat('HH:mm', 'pt_BR');

    return Column(
      children: [
        for (int i = 0; i < itens.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coluna de data/hora
                SizedBox(
                  width: 48,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        fmtData.format(itens[i].dataHora),
                        style: TextStyle(
                          fontFamily: AppTokens.fontePadrao,
                          fontSize: 13,
                          color: subColor,
                          fontFeatures: AppTokens.algarismosTabulares,
                        ),
                      ),
                      Text(
                        fmtHora.format(itens[i].dataHora),
                        style: TextStyle(
                          fontFamily: AppTokens.fontePadrao,
                          fontSize: 13,
                          color: subColor,
                          fontFeatures: AppTokens.algarismosTabulares,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Traço vertical + marcador
                Column(
                  children: [
                    const SizedBox(height: 4),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: itens[i].corMarcador ?? textColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    if (i < itens.length - 1)
                      Expanded(
                        child: Container(
                          width: 1,
                          color: lineColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                // Texto do evento
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itens[i].titulo,
                          style: TextStyle(
                            fontFamily: AppTokens.fontePadrao,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                        if (itens[i].detalhe != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            itens[i].detalhe!,
                            style: TextStyle(
                              fontFamily: AppTokens.fontePadrao,
                              fontSize: 13,
                              color: subColor,
                            ),
                          ),
                        ],
                        if (itens[i].assinaturaValida != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                itens[i].assinaturaValida == true
                                    ? Icons.verified_user_outlined
                                    : Icons.gpp_bad_outlined,
                                size: 13,
                                color: itens[i].assinaturaValida == true
                                    ? AppTokens.statusConferido
                                    : AppTokens.statusSemCadastro,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                itens[i].assinaturaValida == true
                                    ? 'assinatura verificada'
                                    : 'assinatura inválida',
                                style: TextStyle(
                                  fontFamily: AppTokens.fontePadrao,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: itens[i].assinaturaValida == true
                                      ? AppTokens.statusConferido
                                      : AppTokens.statusSemCadastro,
                                  fontFeatures: AppTokens.algarismosTabulares,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
