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
  final List<TextoBrutoDeteccao> textosBrutos;
  final int tempoProcessamentoMs;
  final double fps;

  const DeteccaoSessao({
    required this.caixasVisiveis,
    this.leituraProvavel,
    this.ultimoTombamentoConfirmado,
    this.textosBrutos = const [],
    this.tempoProcessamentoMs = 0,
    this.fps = 0.0,
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

  final List<DateTime> _historicoFrames = [];
  double _fps = 0.0;

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
    final stopwatch = Stopwatch()..start();

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
      final textosBrutos = <TextoBrutoDeteccao>[];
      int detecCount = 0;

      // 1. Processa Códigos de Barras e QR Codes
      for (final barcode in barcodes) {
        final rawValue = barcode.rawValue ?? '';
        if (rawValue.trim().isEmpty) continue;

        final bBox = barcode.boundingBox;
        final rect = RectDeteccao(
          left: bBox.left,
          top: bBox.top,
          width: bBox.width,
          height: bBox.height,
        );

        textosBrutos.add(TextoBrutoDeteccao(texto: rawValue, caixa: rect));

        final avaliacao = motor.avaliarCodigoBarras(rawValue, caixa: rect);
        // Correção 3: Somente contabiliza e processa se NÃO for descartado (ignora EAN-13, URLs)
        if (!avaliacao.isDescartado) {
          if (detecCount >= _maxDeteccoesPorQuadro) break;
          detecCount++;

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
      }

      // 2. Processa Blocos e Linhas de Texto do OCR
      for (final block in recognizedText.blocks) {
        if (detecCount >= _maxDeteccoesPorQuadro) break;

        for (final line in block.lines) {
          if (detecCount >= _maxDeteccoesPorQuadro) break;
          final lineText = line.text;
          if (lineText.trim().isEmpty) continue;

          final lineRect = RectDeteccao(
            left: line.boundingBox.left,
            top: line.boundingBox.top,
            width: line.boundingBox.width,
            height: line.boundingBox.height,
          );

          textosBrutos.add(TextoBrutoDeteccao(texto: lineText, caixa: lineRect));

          // Correção 1 e 2: Extrai candidatos da linha. Se a linha for texto puro
          // (ex: "SECRETARIA", "CUIDADO"), NÃO consome detecCount!
          final candidatos = motor.extrairCandidatosDeTexto(lineText);
          if (candidatos.isEmpty) {
            continue;
          }

          // Avalia cada palavra individual (line.elements) com sua própria caixa
          bool processouPorElemento = false;
          for (final elem in line.elements) {
            final elemCands = motor.extrairCandidatosDeTexto(elem.text);
            if (elemCands.isNotEmpty) {
              if (detecCount >= _maxDeteccoesPorQuadro) break;
              detecCount++;
              processouPorElemento = true;

              final elemRect = RectDeteccao(
                left: elem.boundingBox.left,
                top: elem.boundingBox.top,
                width: elem.boundingBox.width,
                height: elem.boundingBox.height,
              );

              final avaliacao = motor.avaliarTextoOcr(elem.text, caixa: elemRect);
              if (avaliacao.isConfirmado && avaliacao.tombamentoIdentificado != null) {
                final tomb = avaliacao.tombamentoIdentificado!;
                final estavel = estabilidade.registrarDeteccao(
                  tombamento: tomb,
                  caixa: elemRect,
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
                  caixa: elemRect,
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

          // Se não processou por elemento isolado (ex: hífen ligando palavras)
          if (!processouPorElemento) {
            for (final cand in candidatos) {
              if (detecCount >= _maxDeteccoesPorQuadro) break;
              detecCount++;

              final avaliacao = motor.avaliarTextoOcr(cand, caixa: lineRect);
              if (avaliacao.isConfirmado && avaliacao.tombamentoIdentificado != null) {
                final tomb = avaliacao.tombamentoIdentificado!;
                final estavel = estabilidade.registrarDeteccao(
                  tombamento: tomb,
                  caixa: lineRect,
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
                  caixa: lineRect,
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
        }
      }

      final caixasAtivas = estabilidade.obterCaixasAtivas(timestamp: agora);

      stopwatch.stop();
      final tempoProcessamentoMs = stopwatch.elapsedMilliseconds;

      _historicoFrames.add(agora);
      _historicoFrames.removeWhere((t) => agora.difference(t).inSeconds > 2);
      if (_historicoFrames.length > 1) {
        final diffMs = agora.difference(_historicoFrames.first).inMilliseconds;
        if (diffMs > 0) {
          _fps = (_historicoFrames.length - 1) / (diffMs / 1000.0);
        }
      }

      if (!_streamController.isClosed) {
        _streamController.add(
          DeteccaoSessao(
            caixasVisiveis: caixasAtivas,
            leituraProvavel: provavelAtual,
            ultimoTombamentoConfirmado: tombamentoConfirmado,
            textosBrutos: textosBrutos,
            tempoProcessamentoMs: tempoProcessamentoMs,
            fps: _fps,
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
