import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatador.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../data/local/database_provider.dart';
import '../../../data/local/perfil_provider.dart';
import '../../../domain/eventos/evento_service.dart';
import '../../../domain/eventos/evento_v2.dart';
import '../../../domain/identidade/identidade_provider.dart';

/// Modal para captura contínua via leitores externos RFID ou código de barras (HID / Keyboard Wedge)
class LeitorExternoDialog extends ConsumerStatefulWidget {
  final String salaId;

  const LeitorExternoDialog({
    super.key,
    required this.salaId,
  });

  @override
  ConsumerState<LeitorExternoDialog> createState() => _LeitorExternoDialogState();
}

class _LeitorExternoDialogState extends ConsumerState<LeitorExternoDialog> {
  final FocusNode _focusNode = FocusNode();
  final StringBuffer _buffer = StringBuffer();
  final List<RegistroLeituraExterna> _leituras = [];
  String _ultimoCodigoLido = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        final codigo = _buffer.toString().trim();
        _buffer.clear();
        if (codigo.isNotEmpty) {
          _processarLeitura(codigo);
        }
      } else {
        final char = event.character;
        if (char != null && char.isNotEmpty && char.codeUnitAt(0) >= 32) {
          _buffer.write(char);
        }
      }
    }
  }

  Future<void> _processarLeitura(String tombamento) async {
    await HapticFeedback.heavyImpact();
    setState(() => _ultimoCodigoLido = tombamento);

    final db = ref.read(databaseProvider);
    final perfil = ref.read(perfilProvider);
    final idAparelho = await ref.read(identidadeAparelhoProvider.future);

    // Consulta se o bem existe no banco
    final bem = await (db.select(db.bens)..where((b) => b.tombamento.equals(tombamento))).getSingleOrNull();

    String status;
    String descricao;
    if (bem != null) {
      status = bem.localEsperadoId == widget.salaId ? 'CONFERIDO' : 'OUTRA_SALA';
      descricao = bem.descricao;
    } else {
      status = 'SEM_CADASTRO';
      descricao = 'Bem não catalogado no Thema-GRP';
    }

    // Registra evento auditável assinado com Ed25519
    await EventoService.registrar(
      db: db,
      tipo: TiposEvento.leitura,
      localId: widget.salaId,
      aparelhoId: idAparelho.impressaoCurta,
      conferente: perfil.nome,
      tombamento: tombamento,
      payload: {
        'tombamento': tombamento,
        'sala_id': widget.salaId,
        'fonte': 'leitor_externo_hid',
        'status_detectado': status,
      },
    );

    if (mounted) {
      setState(() {
        _leituras.insert(
          0,
          RegistroLeituraExterna(
            tombamento: tombamento,
            descricao: descricao,
            status: status,
            horario: DateTime.now(),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final corFundoBloco = isDark ? AppTokens.brancoEscuro : AppTokens.branco;
    final corBorda = isDark ? AppTokens.linhaEscura : AppTokens.linha;
    final corTexto = isDark ? AppTokens.grafiteEscuro : AppTokens.grafite;
    final corSub = isDark ? AppTokens.cinzaEscuro : AppTokens.cinza;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Dialog(
        backgroundColor: corFundoBloco,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 560),
          padding: const EdgeInsets.all(20),
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
                    child: const Icon(Icons.barcode_reader, color: AppTokens.tinta, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modo Leitor Externo (HID)',
                          style: TextStyle(
                            fontFamily: AppTokens.fonteTitulo,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: corTexto,
                          ),
                        ),
                        Text(
                          'Recepção contínua via Bluetooth ou USB OTG',
                          style: TextStyle(
                            fontFamily: AppTokens.fontePadrao,
                            fontSize: 12,
                            color: corSub,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status do canal de leitura
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTokens.statusConferido.withValues(alpha: 0.1),
                  border: Border.all(color: AppTokens.statusConferido),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_tethering, size: 18, color: AppTokens.statusConferido),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _ultimoCodigoLido.isEmpty
                            ? 'Aguardando bip do leitor RFID / Código de barras...'
                            : 'Último tombamento processado: $_ultimoCodigoLido',
                        style: TextStyle(
                          fontFamily: AppTokens.fontePadrao,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: corTexto,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'Leituras Realizadas nesta Sessão (${_leituras.length})',
                style: TextStyle(
                  fontFamily: AppTokens.fontePadrao,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: corSub,
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: _leituras.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhuma leitura efetuada.\nBipe os códigos com o leitor para conferir em lote.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTokens.fontePadrao,
                            fontSize: 13,
                            color: corSub,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _leituras.length,
                        separatorBuilder: (_, _) => Divider(color: corBorda, height: 1),
                        itemBuilder: (context, index) {
                          final item = _leituras[index];
                          Color corStatus = AppTokens.statusConferido;
                          if (item.status == 'OUTRA_SALA') corStatus = AppTokens.statusOutraSala;
                          if (item.status == 'SEM_CADASTRO') corStatus = AppTokens.statusSemCadastro;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Text(
                                  item.tombamento,
                                  style: const TextStyle(
                                    fontFamily: AppTokens.fontePlaqueta,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.descricao,
                                        style: TextStyle(
                                          fontFamily: AppTokens.fontePadrao,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: corTexto,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        Formatador.dataHora(item.horario),
                                        style: TextStyle(
                                          fontFamily: AppTokens.fontePadrao,
                                          fontSize: 10,
                                          color: corSub,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: corStatus.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    item.status,
                                    style: TextStyle(
                                      fontFamily: AppTokens.fontePadrao,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: corStatus,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 12),
              BotaoPrincipal(
                texto: 'Concluir Varredura Externa',
                icone: Icons.check,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegistroLeituraExterna {
  final String tombamento;
  final String descricao;
  final String status;
  final DateTime horario;

  RegistroLeituraExterna({
    required this.tombamento,
    required this.descricao,
    required this.status,
    required this.horario,
  });
}
