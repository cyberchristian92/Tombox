import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Barra inferior v2 do Tombox
/// Fundo branco, divisória superior, 5 posições;
/// "Conferir" é um botão retangular azul com raio 6 dentro da barra (ícone + texto), não um círculo flutuante.
class BarraInferior extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onConferir;

  const BarraInferior({
    super.key,
    required this.selectedIndex,
    required this.onSelectTab,
    required this.onConferir,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final corFundo = isDark ? AppTokens.brancoEscuro : AppTokens.branco;
    final corDivisoria = isDark ? AppTokens.linhaEscura : AppTokens.linha;

    return Container(
      decoration: BoxDecoration(
        color: corFundo,
        border: Border(
          top: BorderSide(color: corDivisoria, width: 1),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              // 1. Início (index 0)
              Expanded(
                child: _buildItem(
                  index: 0,
                  label: 'Início',
                  icon: Icons.home_outlined,
                  isDark: isDark,
                ),
              ),

              // 2. Locais (index 1)
              Expanded(
                child: _buildItem(
                  index: 1,
                  label: 'Locais',
                  icon: Icons.meeting_room_outlined,
                  isDark: isDark,
                ),
              ),

              // 3. Botão Conferir central retangular azul com raio 6 (ícone + texto)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                child: InkWell(
                  onTap: onConferir,
                  borderRadius: BorderRadius.circular(AppTokens.raioConferir),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTokens.tinta,
                      borderRadius: BorderRadius.circular(AppTokens.raioConferir),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          color: AppTokens.branco,
                          size: 20,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Conferir',
                          style: TextStyle(
                            fontFamily: AppTokens.fontePadrao,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTokens.branco,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Bens (index 3)
              Expanded(
                child: _buildItem(
                  index: 3,
                  label: 'Bens',
                  icon: Icons.inventory_2_outlined,
                  isDark: isDark,
                ),
              ),

              // 5. Mais (index 4)
              Expanded(
                child: _buildItem(
                  index: 4,
                  label: 'Mais',
                  icon: Icons.more_horiz_outlined,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem({
    required int index,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = selectedIndex == index;
    final corAtiva = isDark ? AppTokens.tintaEscuro : AppTokens.tinta;
    final corInativa = isDark ? AppTokens.cinzaEscuro : AppTokens.cinza;
    final cor = isSelected ? corAtiva : corInativa;

    return InkWell(
      onTap: () => onSelectTab(index),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: cor),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTokens.fontePadrao,
                fontSize: AppTokens.tamNavegacao,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: cor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
