import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Lista de dados da ficha: rótulo cinza + valor em Medium, com divisórias
class ListaDados extends StatelessWidget {
  final List<(String rotulo, String valor)> dados;
  final void Function(String rotulo, String valor)? onTapItem;

  const ListaDados({
    super.key,
    required this.dados,
    this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppTokens.cinzaEscuro : AppTokens.cinza;
    final valueColor = isDark ? AppTokens.grafiteEscuro : AppTokens.grafite;
    final dividerColor = isDark ? AppTokens.linhaEscura : AppTokens.linha;

    return Column(
      children: [
        for (int i = 0; i < dados.length; i++) ...[
          InkWell(
            onTap: onTapItem != null
                ? () => onTapItem!(dados[i].$1, dados[i].$2)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 118,
                    child: Text(
                      dados[i].$1,
                      style: TextStyle(
                        fontFamily: AppTokens.fontePadrao,
                        fontSize: 14,
                        color: labelColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      dados[i].$2,
                      style: TextStyle(
                        fontFamily: AppTokens.fontePadrao,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: valueColor,
                      ),
                    ),
                  ),
                  if (onTapItem != null)
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: labelColor.withValues(alpha: 0.5),
                    ),
                ],
              ),
            ),
          ),
          if (i < dados.length - 1)
            Divider(height: 1, color: dividerColor),
        ],
      ],
    );
  }
}
