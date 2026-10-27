import 'package:flutter/material.dart';
import '../../../domain/casamento/casamento_models.dart';
import '../../../domain/casamento/estabilidade_filtro.dart';

class CameraOverlayPainter extends CustomPainter {
  final List<CaixaVisivel> caixas;
  final Size cameraImageSize;

  CameraOverlayPainter({
    required this.caixas,
    required this.cameraImageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (caixas.isEmpty) return;

    // Fatores de escala entre a resolução da câmera e a área de exibição da tela
    final double scaleX = cameraImageSize.width > 0 ? size.width / cameraImageSize.width : 1.0;
    final double scaleY = cameraImageSize.height > 0 ? size.height / cameraImageSize.height : 1.0;

    for (final item in caixas) {
      Color boxColor;
      switch (item.classificacao) {
        case ClassificacaoPlaqueta.verde:
          boxColor = const Color(0xFF2E7D32); // Verde
          break;
        case ClassificacaoPlaqueta.amarelo:
          boxColor = const Color(0xFFF57F17); // Amarelo
          break;
        case ClassificacaoPlaqueta.vermelho:
          boxColor = const Color(0xFFC62828); // Vermelho
          break;
      }

      final rect = Rect.fromLTWH(
        item.caixa.left * scaleX,
        item.caixa.top * scaleY,
        item.caixa.width * scaleX,
        item.caixa.height * scaleY,
      );

      // 1. Desenha contorno da caixa
      final boxPaint = Paint()
        ..color = boxColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        boxPaint,
      );

      // 2. Preenchimento translúcido suave
      final fillPaint = Paint()
        ..color = boxColor.withAlpha(40)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        fillPaint,
      );

      // 3. Badge superior com o número de tombamento
      final label = item.isProvavel ? '${item.tombamento}?' : item.tombamento;
      final textSpan = TextSpan(
        text: ' #$label ',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final badgeRect = Rect.fromLTWH(
        rect.left,
        rect.top > 24 ? rect.top - 22 : rect.top,
        textPainter.width + 4,
        textPainter.height + 2,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(badgeRect, const Radius.circular(4)),
        Paint()..color = boxColor,
      );

      textPainter.paint(canvas, Offset(badgeRect.left + 2, badgeRect.top + 1));
    }
  }

  @override
  bool shouldRepaint(covariant CameraOverlayPainter oldDelegate) {
    return true;
  }
}
