import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Botão principal v2 do Tombox
/// 48 de altura, raio 4, fundo tinta, texto branco SemiBold 16, ícone opcional
class BotaoPrincipal extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final IconData? icone;
  final bool secundario;
  final bool expandir;
  final Color? corFundo;
  final Color? corTexto;

  const BotaoPrincipal({
    super.key,
    required this.texto,
    required this.onPressed,
    this.icone,
    this.secundario = false,
    this.expandir = true,
    this.corFundo,
    this.corTexto,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final background = corFundo ??
        (secundario
            ? (isDark ? AppTokens.brancoEscuro : AppTokens.branco)
            : (isDark ? AppTokens.tintaEscuro : AppTokens.tinta));

    final foreground = corTexto ??
        (secundario
            ? (isDark ? AppTokens.grafiteEscuro : AppTokens.tinta)
            : (isDark ? AppTokens.grafite : AppTokens.branco));

    Widget content = SizedBox(
      height: AppTokens.alturaBotaoPrincipal,
      child: Material(
        color: onPressed == null
            ? (isDark ? AppTokens.linhaEscura : AppTokens.linha)
            : background,
        borderRadius: BorderRadius.circular(AppTokens.raioBotao),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTokens.raioBotao),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.s16),
            decoration: secundario
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTokens.raioBotao),
                    border: Border.all(
                      color: isDark ? AppTokens.linhaEscura : AppTokens.linha,
                      width: 1,
                    ),
                  )
                : null,
            child: Row(
              mainAxisSize: expandir ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icone != null) ...[
                  Icon(
                    icone,
                    size: 20,
                    color: onPressed == null ? AppTokens.cinza : foreground,
                  ),
                  const SizedBox(width: AppTokens.s8),
                ],
                Text(
                  texto,
                  style: TextStyle(
                    fontFamily: AppTokens.fontePadrao,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: onPressed == null ? AppTokens.cinza : foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (expandir) {
      return SizedBox(
        width: double.infinity,
        child: content,
      );
    }
    return content;
  }
}
