import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';
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
        canvas.drawRect(rect, grayPaint);

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

    // 2. Desenha caixas retangulares (2 px, sem cantos arredondados, Barlow Condensed)
    for (final item in caixas) {
      Color boxColor;
      switch (item.classificacao) {
        case ClassificacaoPlaqueta.verde:
          boxColor = AppTokens.statusConferido;
          break;
        case ClassificacaoPlaqueta.amarelo:
          boxColor = AppTokens.statusOutraSala;
          break;
        case ClassificacaoPlaqueta.vermelho:
          boxColor = AppTokens.statusSemCadastro;
          break;
      }

      final rect = _mapearCoordenadas(item.caixa, size);

      // Contorno retangular de 2 px sem cantos arredondados
      final boxPaint = Paint()
        ..color = boxColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRect(rect, boxPaint);

      // Preenchimento translúcido sutil
      final fillPaint = Paint()
        ..color = boxColor.withAlpha(30)
        ..style = PaintingStyle.fill;

      canvas.drawRect(rect, fillPaint);

      // Etiqueta no canto superior esquerdo com o número em Barlow Condensed
      final label = item.isProvavel ? '${item.tombamento}?' : item.tombamento;
      final textSpan = TextSpan(
        text: ' $label ',
        style: const TextStyle(
          fontFamily: AppTokens.fontePlaqueta,
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          fontFeatures: AppTokens.algarismosTabulares,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeRect = Rect.fromLTWH(
        rect.left,
        rect.top > 20 ? rect.top - 20 : rect.top,
        textPainter.width + 4,
        textPainter.height + 2,
      );

      final badgePaint = Paint()..color = boxColor;
      canvas.drawRect(badgeRect, badgePaint);

      textPainter.paint(canvas, Offset(badgeRect.left + 2, badgeRect.top + 1));
    }
  }

  @override
  bool shouldRepaint(covariant CameraOverlayPainter oldDelegate) {
    return true;
  }
}
