import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

class AbaItem {
  final String rotulo;
  final int? contagem;

  const AbaItem({
    required this.rotulo,
    this.contagem,
  });
}

/// Abas v2 do Tombox
/// Texto com contagem em SemiBold, sublinhado de 2 px na aba ativa, divisória de 1 px abaixo.
class Abas extends StatelessWidget {
  final List<AbaItem> abas;
  final int indiceAtivo;
  final ValueChanged<int> onMudou;

  const Abas({
    super.key,
    required this.abas,
    required this.indiceAtivo,
    required this.onMudou,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final corAtiva = isDark ? AppTokens.tintaEscuro : AppTokens.tinta;
    final corInativa = isDark ? AppTokens.cinzaEscuro : AppTokens.cinza;
    final corDivisoria = isDark ? AppTokens.linhaEscura : AppTokens.linha;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTokens.brancoEscuro : AppTokens.branco,
        border: Border(
          bottom: BorderSide(color: corDivisoria, width: 1),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < abas.length; i++)
            Expanded(
              child: _buildAba(
                aba: abas[i],
                ativo: i == indiceAtivo,
                corAtiva: corAtiva,
                corInativa: corInativa,
                onTap: () => onMudou(i),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAba({
    required AbaItem aba,
    required bool ativo,
    required Color corAtiva,
    required Color corInativa,
    required VoidCallback onTap,
  }) {
    final corTexto = ativo ? corAtiva : corInativa;
    final texto = aba.contagem != null
        ? '${aba.rotulo} (${aba.contagem})'
        : aba.rotulo;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: ativo ? corAtiva : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTokens.fontePadrao,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: corTexto,
              fontFeatures: AppTokens.algarismosTabulares,
            ),
          ),
        ),
      ),
    );
  }
}
