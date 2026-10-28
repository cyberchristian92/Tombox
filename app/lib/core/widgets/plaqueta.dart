import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Plaqueta de alumínio: o número de tombamento desenhado como plaqueta.
/// Dois tamanhos: pequena (listas) e grande (topo da ficha).
class Plaqueta extends StatelessWidget {
  final String numero;
  final bool grande;
  /// Texto sob o número na plaqueta grande (ex: "TJPA, patrimônio")
  final String? subtitulo;

  const Plaqueta({
    super.key,
    required this.numero,
    this.grande = false,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    if (grande) return _buildGrande(context);
    return _buildPequena(context);
  }

  Widget _buildPequena(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTokens.aluminio,
        borderRadius: BorderRadius.circular(AppTokens.raioPlaquetaPequena),
        border: Border.all(color: AppTokens.aluminioBorda, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _rebite(5),
          const SizedBox(width: 6),
          Text(
            numero,
            style: AppTokens.plaquetaPequenaNumero,
          ),
          const SizedBox(width: 6),
          _rebite(5),
        ],
      ),
    );
  }

  Widget _buildGrande(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTokens.aluminio,
        borderRadius: BorderRadius.circular(AppTokens.raioPlaquetaGrande),
        border: Border.all(color: AppTokens.aluminioBorda, width: 1),
      ),
      child: Stack(
        children: [
          // Rebites nas extremidades
          Positioned(
            left: 4,
            top: 0,
            bottom: 0,
            child: Center(child: _rebite(9)),
          ),
          Positioned(
            right: 4,
            top: 0,
            bottom: 0,
            child: Center(child: _rebite(9)),
          ),
          // Número e subtítulo centralizados
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  numero,
                  style: AppTokens.plaquetaGrandeNumero,
                  textAlign: TextAlign.center,
                ),
                if (subtitulo != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitulo!,
                    style: AppTokens.plaquetaGrandeSubtitulo,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rebite(double tamanho) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTokens.aluminioRebite,
        border: Border.all(
          color: AppTokens.aluminioBorda,
          width: 0.5,
        ),
      ),
    );
  }
}
