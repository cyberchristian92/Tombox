import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Barra de busca v2 do Tombox
/// Campo retangular com raio 4, borda fina na cor linha, ícone de busca em traço fino
class BarraBusca extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final List<Widget>? filtrosAbaixo;

  const BarraBusca({
    super.key,
    required this.controller,
    this.hintText = 'Buscar por tombamento, descrição...',
    this.onChanged,
    this.onClear,
    this.filtrosAbaixo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final corFundo = isDark ? AppTokens.brancoEscuro : AppTokens.branco;
    final corBorda = isDark ? AppTokens.linhaEscura : AppTokens.linha;
    final corTexto = isDark ? AppTokens.grafiteEscuro : AppTokens.grafite;
    final corHint = isDark ? AppTokens.cinzaEscuro : AppTokens.cinza;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: corFundo,
            borderRadius: BorderRadius.circular(AppTokens.raioBloco),
            border: Border.all(color: corBorda, width: 1),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(
              fontFamily: AppTokens.fontePadrao,
              fontSize: 14,
              color: corTexto,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.search_outlined,
                size: 20,
                color: corHint,
              ),
              hintText: hintText,
              hintStyle: TextStyle(
                fontFamily: AppTokens.fontePadrao,
                fontSize: 14,
                color: corHint,
              ),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_outlined, size: 18, color: corHint),
                      onPressed: () {
                        controller.clear();
                        onChanged?.call('');
                        onClear?.call();
                      },
                    )
                  : null,
            ),
          ),
        ),
        if (filtrosAbaixo != null && filtrosAbaixo!.isNotEmpty) ...[
          const SizedBox(height: AppTokens.s8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filtrosAbaixo!
                  .map((w) => Padding(
                        padding: const EdgeInsets.only(right: AppTokens.s8),
                        child: w,
                      ))
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
}
