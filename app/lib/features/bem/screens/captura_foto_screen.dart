import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_tokens.dart';

/// Tela de captura de evidência fotográfica pela câmera nativa do app
class CapturaFotoScreen extends StatefulWidget {
  const CapturaFotoScreen({super.key});

  @override
  State<CapturaFotoScreen> createState() => _CapturaFotoScreenState();
}

class _CapturaFotoScreenState extends State<CapturaFotoScreen> {
  CameraController? _controller;
  bool _iniciada = false;
  bool _capturando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _iniciarCamera();
  }

  Future<void> _iniciarCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _erro = 'Nenhuma câmera disponível no dispositivo.');
        return;
      }

      // Prioriza câmera traseira
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() => _iniciada = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _erro = 'Erro ao inicializar câmera: $e');
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _tirarFoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _capturando) return;

    setState(() => _capturando = true);
    try {
      final file = await _controller!.takePicture();
      final bytes = await file.readAsBytes();
      if (mounted) {
        Navigator.pop(context, bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao capturar foto: $e')),
        );
        setState(() => _capturando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_erro != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _erro!,
              style: const TextStyle(color: Colors.white, fontFamily: AppTokens.fontePadrao),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (!_iniciada || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Preview da câmera
          Center(
            child: CameraPreview(_controller!),
          ),

          // Barra superior com fechar
          PositionBarraSuperior(
            onClose: () => Navigator.pop(context),
          ),

          // Botão retangular de captura no rodapé
          Positioned(
            left: 24,
            right: 24,
            bottom: 36,
            child: SizedBox(
              height: AppTokens.alturaBotaoPrincipal,
              child: ElevatedButton.icon(
                onPressed: _capturando ? null : _tirarFoto,
                icon: _capturando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt_outlined),
                label: Text(
                  _capturando ? 'PROCESSANDO...' : 'CAPTURAR FOTO',
                  style: const TextStyle(
                    fontFamily: AppTokens.fonteTitulo,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTokens.tinta,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.raioBotao),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PositionBarraSuperior extends StatelessWidget {
  final VoidCallback onClose;

  const PositionBarraSuperior({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      left: 16,
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
        onPressed: onClose,
      ),
    );
  }
}
