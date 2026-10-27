import 'package:flutter/material.dart';
import '../../../domain/casamento/casamento_models.dart';
import '../../../domain/casamento/estabilidade_filtro.dart';

class CameraOverlayPainter extends CustomPainter {
  final List<CaixaVisivel> caixas;
  final Size cameraImageSize;
  final int sensorOrientation;
  final bool isFrontCamera;
  final bool modoDiagnostico;
  final List<TextoBrutoDeteccao> textosBrutos;
  final int tempoProcessamentoMs;
  final double fps;

  CameraOverlayPainter({
    required this.caixas,
    required this.cameraImageSize,
    this.sensorOrientation = 90,
    this.isFrontCamera = false,
    this.modoDiagnostico = false,
    this.textosBrutos = const [],
    this.tempoProcessamentoMs = 0,
    this.fps = 0.0,
  });

  Rect _mapearCoordenadas(RectDeteccao box, Size size) {
    final double bufW;
    final double bufH;

    if (sensorOrientation == 90 || sensorOrientation == 270) {
      bufW = cameraImageSize.height > 0 ? cameraImageSize.height : 480;
      bufH = cameraImageSize.width > 0 ? cameraImageSize.width : 640;
    } else {
      bufW = cameraImageSize.width > 0 ? cameraImageSize.width : 640;
      bufH = cameraImageSize.height > 0 ? cameraImageSize.height : 480;
    }

    final double scaleX = size.width / bufW;
    final double scaleY = size.height / bufH;
    final double scale = scaleX > scaleY ? scaleX : scaleY;

    final double offsetX = (size.width - bufW * scale) / 2;
    final double offsetY = (size.height - bufH * scale) / 2;

    double left = box.left * scale + offsetX;
    double top = box.top * scale + offsetY;
    double width = box.width * scale;
    double height = box.height * scale;

    if (isFrontCamera) {
      left = size.width - (left + width);
    }

    return Rect.fromLTWH(left, top, width, height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Modo Diagnóstico: desenha textos brutos do OCR em cinza
    if (modoDiagnostico && textosBrutos.isNotEmpty) {
      final grayPaint = Paint()
        ..color = Colors.white.withAlpha(120)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      for (final raw in textosBrutos) {
        final rect = _mapearCoordenadas(raw.caixa, size);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          grayPaint,
        );

        // Exibe texto bruto em tamanho reduzido
        final span = TextSpan(
          text: raw.texto.length > 20 ? '${raw.texto.substring(0, 18)}...' : raw.texto,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            backgroundColor: Color(0x66000000),
          ),
        );
        final tp = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(rect.left, rect.top > 12 ? rect.top - 12 : rect.top));
      }
    }

    // 2. Desenha caixas ativas identificadas pelo motor de casamento
    for (final item in caixas) {
      Color boxColor;
      switch (item.classificacao) {
        case ClassificacaoPlaqueta.verde:
          boxColor = const Color(0xFF2E7D32); // Verde: esperado na sala
          break;
        case ClassificacaoPlaqueta.amarelo:
          boxColor = const Color(0xFFF57F17); // Amarelo: esperado em outra sala
          break;
        case ClassificacaoPlaqueta.vermelho:
          boxColor = const Color(0xFFC62828); // Vermelho: código desconhecido
          break;
      }

      final rect = _mapearCoordenadas(item.caixa, size);

      // Contorno da caixa
      final boxPaint = Paint()
        ..color = boxColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        boxPaint,
      );

      // Preenchimento translúcido
      final fillPaint = Paint()
        ..color = boxColor.withAlpha(45)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        fillPaint,
      );

      // Badge superior com número de tombamento
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
      )..layout();

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

    // 3. HUD de Desempenho do Modo Diagnóstico (Pitch e Calibração)
    if (modoDiagnostico) {
      final hudText =
          '⚡ FPS: ${fps.toStringAsFixed(1)} | Processamento: ${tempoProcessamentoMs}ms | Caixas: ${caixas.length}';
      final hudSpan = TextSpan(
        text: hudText,
        style: const TextStyle(
          color: Colors.lightGreenAccent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      );
      final hudPainter = TextPainter(
        text: hudSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final hudBgRect = Rect.fromLTWH(
        12,
        8,
        hudPainter.width + 16,
        hudPainter.height + 8,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(hudBgRect, const Radius.circular(6)),
        Paint()..color = const Color(0xCC000000),
      );

      hudPainter.paint(canvas, Offset(hudBgRect.left + 8, hudBgRect.top + 4));
    }
  }

  @override
  bool shouldRepaint(covariant CameraOverlayPainter oldDelegate) {
    return true;
  }
}
