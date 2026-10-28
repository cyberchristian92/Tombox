import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import 'botao_principal.dart';

enum EstadoSync {
  sincronizado,
  pendente,
  semOutrosAparelhos,
}

class IndicadorSync extends StatelessWidget {
  final EstadoSync estado;
  final int eventosPendentes;
  final VoidCallback? onTap;

  const IndicadorSync({
    super.key,
    this.estado = EstadoSync.sincronizado,
    this.eventosPendentes = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color cor;
    IconData icone;
    String tooltip;

    switch (estado) {
      case EstadoSync.sincronizado:
        cor = AppTokens.statusConferido;
        icone = Icons.cloud_done_outlined;
        tooltip = 'Todos os dados sincronizados';
        break;
      case EstadoSync.pendente:
        cor = AppTokens.statusOutraSala;
        icone = Icons.sync_outlined;
        tooltip = '$eventosPendentes eventos pendentes de sincronização';
        break;
      case EstadoSync.semOutrosAparelhos:
        cor = AppTokens.statusPendente;
        icone = Icons.cloud_off_outlined;
        tooltip = 'Nenhum outro celular na rede local';
        break;
    }

    return IconButton(
      tooltip: tooltip,
      onPressed: onTap ?? () => _mostrarDetalhesSync(context),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icone, color: AppTokens.branco, size: 22),
          if (estado == EstadoSync.pendente && eventosPendentes > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: cor,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  eventosPendentes > 9 ? '9+' : '$eventosPendentes',
                  style: const TextStyle(
                    fontFamily: AppTokens.fontePadrao,
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _mostrarDetalhesSync(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTokens.brancoEscuro : AppTokens.branco,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.raioFolha)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.s20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.sync_outlined,
                      color: AppTokens.statusConferido,
                      size: 24,
                    ),
                    const SizedBox(width: AppTokens.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sincronização em rede local',
                            style: TextStyle(
                              fontFamily: AppTokens.fonteTitulo,
                              fontSize: AppTokens.tamSecao,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTokens.grafiteEscuro : AppTokens.grafite,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'mDNS e Wi-Fi Direct',
                            style: TextStyle(
                              fontFamily: AppTokens.fontePadrao,
                              fontSize: AppTokens.tamSecundario,
                              color: AppTokens.cinza,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s16),
                Divider(
                  color: isDark ? AppTokens.linhaEscura : AppTokens.linha,
                  height: 1,
                ),
                const SizedBox(height: AppTokens.s12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.devices_outlined, color: AppTokens.cinza, size: 22),
                  title: const Text(
                    'Aparelhos na rede',
                    style: TextStyle(
                      fontFamily: AppTokens.fontePadrao,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: const Text(
                    '1 aparelho local ativo',
                    style: TextStyle(
                      fontFamily: AppTokens.fontePadrao,
                      fontSize: 13,
                      color: AppTokens.cinza,
                    ),
                  ),
                  trailing: const Icon(Icons.check_outlined, color: AppTokens.statusConferido, size: 20),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history_outlined, color: AppTokens.cinza, size: 22),
                  title: const Text(
                    'Último sincronismo',
                    style: TextStyle(
                      fontFamily: AppTokens.fontePadrao,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: const Text(
                    'Agora mesmo (cópia íntegra)',
                    style: TextStyle(
                      fontFamily: AppTokens.fontePadrao,
                      fontSize: 13,
                      color: AppTokens.cinza,
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.s16),
                BotaoPrincipal(
                  texto: 'Sincronizar agora',
                  icone: Icons.refresh_outlined,
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sincronização local concluída!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
