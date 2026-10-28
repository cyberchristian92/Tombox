import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import 'plaqueta.dart';

/// Situação de um bem para o marcador visual
enum SituacaoBem { conferido, outraSala, semCadastro, pendente }

/// Linha de bem v2: plaqueta pequena, descrição, categoria, marcador de situação
class LinhaBem extends StatelessWidget {
  final String tombamento;
  final String descricao;
  final String? categoria;
  final SituacaoBem situacao;
  final VoidCallback? onTap;

  const LinhaBem({
    super.key,
    required this.tombamento,
    required this.descricao,
    this.categoria,
    this.situacao = SituacaoBem.pendente,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTokens.grafiteEscuro : AppTokens.grafite;
    final subColor = isDark ? AppTokens.cinzaEscuro : AppTokens.cinza;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        child: Row(
          children: [
            // Plaqueta pequena
            Plaqueta(numero: tombamento),
            const SizedBox(width: 12),
            // Descrição e categoria
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    descricao,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTokens.fontePadrao,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: textColor,
                    ),
                  ),
                  if (categoria != null && categoria!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      categoria!,
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
            // Marcador de situação
            _marcador(),
          ],
        ),
      ),
    );
  }

  Widget _marcador() {
    switch (situacao) {
      case SituacaoBem.conferido:
        return _quadrado(AppTokens.statusConferido, cheio: true);
      case SituacaoBem.outraSala:
        return _quadrado(AppTokens.statusOutraSala, cheio: true);
      case SituacaoBem.semCadastro:
        return _quadrado(AppTokens.statusSemCadastro, cheio: true);
      case SituacaoBem.pendente:
        return _quadrado(AppTokens.statusPendente, cheio: false);
    }
  }

  Widget _quadrado(Color cor, {required bool cheio}) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: cheio ? cor : Colors.transparent,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: cor,
          width: cheio ? 0 : 1.5,
        ),
      ),
    );
  }
}
