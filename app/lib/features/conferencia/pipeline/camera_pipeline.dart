import 'dart:async';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../domain/casamento/casamento_models.dart';
import '../../../domain/casamento/casamento_motor.dart';
import '../../../domain/casamento/estabilidade_filtro.dart';
import 'camera_image_converter.dart';

class DeteccaoSessao {
  final List<CaixaVisivel> caixasVisiveis;
  final ResultadoCasamento? leituraProvavel;
  final String? ultimoTombamentoConfirmado;

  const DeteccaoSessao({
    required this.caixasVisiveis,
    this.leituraProvavel,
    this.ultimoTombamentoConfirmado,
  });
}

class CameraPipeline {
  final CasamentoMotor motor;
  final EstabilidadeFiltro estabilidade;
  final Function(String tombamento, String formaLeitura, bool daSala) onConfirmado;

  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  bool _isProcessing = false;
  DateTime _lastProcessedTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _intervaloMinMs = 200; // Intervalo de 150 a 250 ms (seção 8)
  static const int _maxDeteccoesPorQuadro = 15; // Máximo de 15 detecções (seção 8)

  final _streamController = StreamController<DeteccaoSessao>.broadcast();
  Stream<DeteccaoSessao> get stream => _streamController.stream;

  CameraPipeline({
    required this.motor,
    required this.estabilidade,
    required this.onConfirmado,
  });

  Future<void> processarQuadro({
    required CameraImage cameraImage,
    required CameraDescription camera,
  }) async {
    final agora = DateTime.now();
    if (_isProcessing ||
        agora.difference(_lastProcessedTime).inMilliseconds < _intervaloMinMs) {
      return;
    }

    _isProcessing = true;
    _lastProcessedTime = agora;

    try {
      final inputImage = CameraImageConverter.convert(
        cameraImage: cameraImage,
        camera: camera,
      );

      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      // Executa OCR e Código de Barras no mesmo quadro
      final resultados = await Future.wait([
        _textRecognizer.processImage(inputImage),
        _barcodeScanner.processImage(inputImage),
      ]);

      final RecognizedText recognizedText = resultados[0] as RecognizedText;
      final List<Barcode> barcodes = resultados[1] as List<Barcode>;

      ResultadoCasamento? provavelAtual;
      String? tombamentoConfirmado;
      int detecCount = 0;

      // 1. Processa Códigos de Barras e QR Codes
      for (final barcode in barcodes) {
        if (detecCount >= _maxDeteccoesPorQuadro) break;
        final rawValue = barcode.rawValue ?? '';
        if (rawValue.trim().isEmpty) continue;
        detecCount++;

        final bBox = barcode.boundingBox;
        final rect = RectDeteccao(
          left: bBox.left,
          top: bBox.top,
          width: bBox.width,
          height: bBox.height,
        );

        final avaliacao = motor.avaliarCodigoBarras(rawValue, caixa: rect);
        if (avaliacao.isConfirmado && avaliacao.tombamentoIdentificado != null) {
          final tomb = avaliacao.tombamentoIdentificado!;
          estabilidade.registrarDeteccao(
            tombamento: tomb,
            caixa: rect,
            classificacao: avaliacao.classificacao ?? ClassificacaoPlaqueta.verde,
            isProvavel: false,
            timestamp: agora,
          );

          if (!estabilidade.isJaConfirmado(tomb)) {
            estabilidade.marcarConfirmado(tomb);
            tombamentoConfirmado = tomb;
            onConfirmado(
              tomb,
              'codigo',
              avaliacao.classificacao == ClassificacaoPlaqueta.verde,
            );
          }
        }
      }

      // 2. Processa Blocos e Linhas de Texto do OCR
      for (final block in recognizedText.blocks) {
        if (detecCount >= _maxDeteccoesPorQuadro) break;

        for (final line in block.lines) {
          if (detecCount >= _maxDeteccoesPorQuadro) break;
          final lineText = line.text;
          if (lineText.trim().isEmpty) continue;
          detecCount++;

          final rect = RectDeteccao(
            left: line.boundingBox.left,
            top: line.boundingBox.top,
            width: line.boundingBox.width,
            height: line.boundingBox.height,
          );

          final avaliacao = motor.avaliarTextoOcr(lineText, caixa: rect);

          if (avaliacao.isConfirmado && avaliacao.tombamentoIdentificado != null) {
            final tomb = avaliacao.tombamentoIdentificado!;
            final estavel = estabilidade.registrarDeteccao(
              tombamento: tomb,
              caixa: rect,
              classificacao: avaliacao.classificacao ?? ClassificacaoPlaqueta.verde,
              isProvavel: false,
              timestamp: agora,
            );

            if (estavel && !estabilidade.isJaConfirmado(tomb)) {
              estabilidade.marcarConfirmado(tomb);
              tombamentoConfirmado = tomb;
              onConfirmado(
                tomb,
                'ocr',
                avaliacao.classificacao == ClassificacaoPlaqueta.verde,
              );
            }
          } else if (avaliacao.isProvavel && avaliacao.tombamentoIdentificado != null) {
            final tomb = avaliacao.tombamentoIdentificado!;
            estabilidade.registrarDeteccao(
              tombamento: tomb,
              caixa: rect,
              classificacao: avaliacao.classificacao ?? ClassificacaoPlaqueta.verde,
              isProvavel: true,
              timestamp: agora,
            );
            if (!estabilidade.isJaConfirmado(tomb)) {
              provavelAtual = avaliacao;
            }
          }
        }
      }

      final caixasAtivas = estabilidade.obterCaixasAtivas(timestamp: agora);

      if (!_streamController.isClosed) {
        _streamController.add(
          DeteccaoSessao(
            caixasVisiveis: caixasAtivas,
            leituraProvavel: provavelAtual,
            ultimoTombamentoConfirmado: tombamentoConfirmado,
          ),
        );
      }
    } catch (_) {
      // Ignora erro transitório em quadro corrompido de câmera
    } finally {
      _isProcessing = false;
    }
  }

  void confirmarProvavelManual(ResultadoCasamento provavel) {
    if (provavel.tombamentoIdentificado != null) {
      final tomb = provavel.tombamentoIdentificado!;
      estabilidade.marcarConfirmado(tomb);
      onConfirmado(
        tomb,
        'ocr',
        provavel.classificacao == ClassificacaoPlaqueta.verde,
      );
    }
  }

  Future<void> dispose() async {
    await _streamController.close();
    await _textRecognizer.close();
    await _barcodeScanner.close();
  }
}
