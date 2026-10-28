import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../domain/provisorio/cartela_qr_service.dart';

class CartelaQrScreen extends StatefulWidget {
  const CartelaQrScreen({super.key});

  @override
  State<CartelaQrScreen> createState() => _CartelaQrScreenState();
}

class _CartelaQrScreenState extends State<CartelaQrScreen> {
  int _numeroInicial = 1;
  final int _quantidade = 24;
  bool _gerando = false;
  Uint8List? _pdfGerado;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final corFundoBloco = isDark ? AppTokens.brancoEscuro : AppTokens.branco;
    final corBorda = isDark ? AppTokens.linhaEscura : AppTokens.linha;
    final corTexto = isDark ? AppTokens.grafiteEscuro : AppTokens.grafite;
    final corSub = isDark ? AppTokens.cinzaEscuro : AppTokens.cinza;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cartela de QR Provisórios'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.paddingLateral),
        children: [
          // 1. Apresentação
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: corFundoBloco,
              border: Border.all(color: corBorda),
              borderRadius: BorderRadius.circular(AppTokens.raioBloco),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTokens.tinta.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.qr_code_2, color: AppTokens.tinta, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plaquetas Provisórias A4',
                            style: TextStyle(
                              fontFamily: AppTokens.fonteTitulo,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: corTexto,
                            ),
                          ),
                          Text(
                            'Grade de 24 etiquetas adesivas para bens sem plaqueta',
                            style: TextStyle(
                              fontFamily: AppTokens.fontePadrao,
                              fontSize: 12,
                              color: corSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Imprima esta cartela em folhas adesivas antes de ir a campo. Ao encontrar um bem sem tombamento, cole uma das etiquetas e escaneie no app durante o fluxo de cadastro de Bem Novo.',
                  style: TextStyle(
                    fontFamily: AppTokens.fontePadrao,
                    fontSize: 13,
                    color: corSub,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. Configuração de Faixa
          Text(
            'Configuração da Folha',
            style: TextStyle(
              fontFamily: AppTokens.fonteTitulo,
              fontSize: AppTokens.tamSecao,
              fontWeight: FontWeight.w600,
              color: corTexto,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: corFundoBloco,
              border: Border.all(color: corBorda),
              borderRadius: BorderRadius.circular(AppTokens.raioBloco),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Número inicial da faixa:',
                      style: TextStyle(
                        fontFamily: AppTokens.fontePadrao,
                        fontSize: 13,
                        color: corTexto,
                      ),
                    ),
                    DropdownButton<int>(
                      value: _numeroInicial,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('001 a 024')),
                        DropdownMenuItem(value: 25, child: Text('025 a 048')),
                        DropdownMenuItem(value: 49, child: Text('049 a 072')),
                        DropdownMenuItem(value: 73, child: Text('073 a 096')),
                        DropdownMenuItem(value: 97, child: Text('097 a 120')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _numeroInicial = v;
                            _pdfGerado = null;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Formato gerado: PROV-000-${_numeroInicial.toString().padLeft(3, '0')} a PROV-000-${(_numeroInicial + _quantidade - 1).toString().padLeft(3, '0')}',
                  style: const TextStyle(
                    fontFamily: AppTokens.fontePlaqueta,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.tinta,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. Botão Gerar PDF
          BotaoPrincipal(
            texto: _gerando ? 'Gerando Cartela PDF...' : 'Gerar Cartela PDF A4',
            icone: Icons.print_outlined,
            onPressed: _gerando ? null : _gerarCartela,
          ),

          if (_pdfGerado != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTokens.statusConferido.withValues(alpha: 0.1),
                border: Border.all(color: AppTokens.statusConferido),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTokens.statusConferido, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PDF A4 Pronto para Impressão',
                          style: TextStyle(
                            fontFamily: AppTokens.fonteTitulo,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTokens.statusConferido,
                          ),
                        ),
                        Text(
                          'Tamanho: ${(_pdfGerado!.length / 1024).toStringAsFixed(1)} KB (24 etiquetas QR com padrão ISO/IEC 18004)',
                          style: TextStyle(
                            fontFamily: AppTokens.fontePadrao,
                            fontSize: 12,
                            color: corTexto,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _gerarCartela() async {
    setState(() => _gerando = true);
    await HapticFeedback.mediumImpact();

    try {
      final bytes = await CartelaQrService.gerarCartelaA4(
        numeroInicial: _numeroInicial,
        quantidade: _quantidade,
      );

      if (mounted) {
        setState(() {
          _gerando = false;
          _pdfGerado = bytes;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cartela de QR Codes gerada com sucesso!'),
            backgroundColor: AppTokens.statusConferido,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _gerando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar cartela: $e')),
        );
      }
    }
  }
}
