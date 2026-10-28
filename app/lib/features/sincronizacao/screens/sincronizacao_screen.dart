import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatador.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/database_provider.dart';
import '../../../domain/identidade/identidade_service.dart';
import '../../../domain/identidade/identidade_provider.dart';
import '../../../domain/sync/sync_engine.dart';
import '../../../domain/sync/sync_models.dart';
import '../../../domain/sync/transporte_local.dart';

class SincronizacaoScreen extends ConsumerStatefulWidget {
  const SincronizacaoScreen({super.key});

  @override
  ConsumerState<SincronizacaoScreen> createState() => _SincronizacaoScreenState();
}

class _SincronizacaoScreenState extends ConsumerState<SincronizacaoScreen> {
  bool _sincronizando = false;
  ResultadoSincronizacao? _ultimoResultado;
  DateTime _ultimoContato = DateTime.now();

  // Aparelhos reais descobertos via mDNS (_tombox._tcp)
  final List<AparelhoRemoto> _aparelhosDescobertos = [];

  final DescobertaRedeService _descoberta = DescobertaRedeService();
  ServidorSincronizacaoLocal? _servidor;

  @override
  void initState() {
    super.initState();
    _iniciarRede();
  }

  Future<void> _iniciarRede() async {
    if (kIsWeb) return;

    try {
      final db = ref.read(databaseProvider);
      final id = await ref.read(identidadeAparelhoProvider.future);

      _servidor = ServidorSincronizacaoLocal(db: db, porta: 8086);
      await _servidor?.iniciar();

      await _descoberta.registrarServico(
        porta: 8086,
        impressaoCurta: id.impressaoCurta,
      );

      await _descoberta.iniciarDescoberta(
        minhaImpressaoCurta: id.impressaoCurta,
        onAtualizar: (lista) {
          if (mounted) {
            setState(() {
              _aparelhosDescobertos.clear();
              _aparelhosDescobertos.addAll(lista);
            });
          }
        },
      );
    } catch (_) {
      // Ignora falhas em ambientes sem socket/rede
    }
  }

  @override
  void dispose() {
    _descoberta.parar();
    _servidor?.parar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final db = ref.watch(databaseProvider);
    final identidadeAsync = ref.watch(identidadeAparelhoProvider);

    final corFundoBloco = isDark ? AppTokens.brancoEscuro : AppTokens.branco;
    final corBorda = isDark ? AppTokens.linhaEscura : AppTokens.linha;
    final corTexto = isDark ? AppTokens.grafiteEscuro : AppTokens.grafite;
    final corSub = isDark ? AppTokens.cinzaEscuro : AppTokens.cinza;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronização P2P'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.paddingLateral),
        children: [
          // 1. Card de Status da Rede Local ou Aviso Web
          if (kIsWeb) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTokens.statusOutraSala.withValues(alpha: 0.1),
                border: Border.all(color: AppTokens.statusOutraSala, width: 1),
                borderRadius: BorderRadius.circular(AppTokens.raioBloco),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTokens.statusOutraSala,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sincronização P2P na Web',
                          style: TextStyle(
                            fontFamily: AppTokens.fonteTitulo,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: corTexto,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Na prévia web, a sincronização em rede local não está disponível por restrições do navegador. Use a exportação/importação do pacote .tombox abaixo.',
                          style: TextStyle(
                            fontFamily: AppTokens.fontePadrao,
                            fontSize: 13,
                            color: corTexto,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: corFundoBloco,
                border: Border.all(color: corBorda, width: 1),
                borderRadius: BorderRadius.circular(AppTokens.raioBloco),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppTokens.statusConferido,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rede Local Ativa (_tombox._tcp)',
                        style: TextStyle(
                          fontFamily: AppTokens.fonteTitulo,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: corTexto,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Este aparelho anuncia o serviço via mDNS na porta 8086 e autentica membros por desafio mútuo Ed25519.',
                    style: TextStyle(
                      fontFamily: AppTokens.fontePadrao,
                      fontSize: 13,
                      color: corSub,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Identidade local:',
                        style: TextStyle(
                          fontFamily: AppTokens.fontePadrao,
                          fontSize: 12,
                          color: corSub,
                        ),
                      ),
                      Text(
                        identidadeAsync.when(
                          data: (id) => id.impressaoCurta,
                          loading: () => 'Carregando...',
                          error: (_, _) => 'ED25-LOCAL-0001',
                        ),
                        style: const TextStyle(
                          fontFamily: AppTokens.fontePlaqueta,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Última verificação:',
                        style: TextStyle(
                          fontFamily: AppTokens.fontePadrao,
                          fontSize: 12,
                          color: corSub,
                        ),
                      ),
                      Text(
                        Formatador.dataHora(_ultimoContato),
                        style: TextStyle(
                          fontFamily: AppTokens.fontePadrao,
                          fontSize: 12,
                          color: corTexto,
                          fontFeatures: AppTokens.algarismosTabulares,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Botão Sincronizar Agora (somente se não for web)
          if (!kIsWeb) ...[
            BotaoPrincipal(
              texto: _sincronizando ? 'Sincronizando com a rede...' : 'Sincronizar agora',
              icone: Icons.sync,
              onPressed: _sincronizando ? null : () => _executarSincronizacao(db, identidadeAsync.value),
            ),

            if (_ultimoResultado != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _ultimoResultado!.convergente
                      ? AppTokens.statusConferido.withValues(alpha: 0.1)
                      : AppTokens.statusOutraSala.withValues(alpha: 0.1),
                  border: Border.all(
                    color: _ultimoResultado!.convergente
                        ? AppTokens.statusConferido
                        : AppTokens.statusOutraSala,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      _ultimoResultado!.convergente ? Icons.check_circle : Icons.warning_amber,
                      color: _ultimoResultado!.convergente
                          ? AppTokens.statusConferido
                          : AppTokens.statusOutraSala,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _ultimoResultado!.mensagem ?? 'Sincronização processada.',
                        style: TextStyle(
                          fontFamily: AppTokens.fontePadrao,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: corTexto,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 2. Aparelhos na Rede (Reais)
            Text(
              'Aparelhos na mesma rede (${_aparelhosDescobertos.length})',
              style: TextStyle(
                fontFamily: AppTokens.fonteTitulo,
                fontSize: AppTokens.tamSecao,
                fontWeight: FontWeight.w600,
                color: corTexto,
              ),
            ),
            const SizedBox(height: 10),

            if (_aparelhosDescobertos.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: corFundoBloco,
                  border: Border.all(color: corBorda, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.wifi_find, size: 22, color: corSub),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Nenhum outro aparelho encontrado na rede Wi-Fi. Certifique-se de que outro celular com o Tombox está conectado à mesma rede e com o app aberto.',
                        style: TextStyle(
                          fontFamily: AppTokens.fontePadrao,
                          fontSize: 13,
                          color: corSub,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              for (final a in _aparelhosDescobertos) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: corFundoBloco,
                    border: Border.all(color: corBorda, width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTokens.tinta.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.smartphone, size: 20, color: AppTokens.tinta),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.nome,
                              style: TextStyle(
                                fontFamily: AppTokens.fontePadrao,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: corTexto,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${a.enderecoIp}:${a.porta} • Chave ${a.impressaoCurta}',
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
                        icon: const Icon(Icons.sync, color: AppTokens.tinta),
                        tooltip: 'Sincronizar com este nó',
                        onPressed: _sincronizando ? null : () => _sincronizarComPeer(db, identidadeAsync.value, a),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            const SizedBox(height: 24),
          ],

          // 3. Transporte por Arquivo Pacote .tombox
          Text(
            'Pacote offline (.tombox)',
            style: TextStyle(
              fontFamily: AppTokens.fonteTitulo,
              fontSize: AppTokens.tamSecao,
              fontWeight: FontWeight.w600,
              color: corTexto,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Arquivo comprimido contendo a cadeia imutável de eventos e fotos endereçadas por SHA-256 para transferência sem rede.',
            style: TextStyle(
              fontFamily: AppTokens.fontePadrao,
              fontSize: 13,
              color: corSub,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text('Exportar .tombox'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: corBorda),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _exportarPacote(db),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.file_upload_outlined, size: 18),
                  label: const Text('Importar .tombox'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: corBorda),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _importarPacote(db),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _executarSincronizacao(AppDatabase db, IdentidadeAparelho? identidade) async {
    if (identidade == null) return;

    if (_aparelhosDescobertos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum nó disponível na rede para sincronização direta. Use o pacote .tombox ou conecte outro aparelho.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _sincronizando = true);
    await HapticFeedback.mediumImpact();

    int totalRecebidos = 0;
    int totalEnviados = 0;
    int totalFotos = 0;
    String? erroUltimo;

    for (final peer in _aparelhosDescobertos) {
      try {
        final res = await ClienteSincronizacaoLocal.sincronizar(
          aparelho: peer,
          db: db,
          identidadeLocal: identidade,
        );
        totalRecebidos += res.eventosRecebidos;
        totalFotos += res.fotosRecebidas;
      } catch (e) {
        erroUltimo = e.toString();
      }
    }

    if (mounted) {
      setState(() {
        _sincronizando = false;
        _ultimoContato = DateTime.now();
        _ultimoResultado = ResultadoSincronizacao(
          eventosRecebidos: totalRecebidos,
          eventosAplicados: totalRecebidos,
          eventosQuarentena: 0,
          fotosRecebidas: totalFotos,
          convergente: erroUltimo == null,
          mensagem: erroUltimo != null && totalRecebidos == 0
              ? 'Falha ao sincronizar com nó: $erroUltimo'
              : '$totalRecebidos eventos recebidos, $totalEnviados enviados, $totalFotos fotos transferidas.',
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_ultimoResultado!.mensagem ?? 'Sincronização concluída'),
          backgroundColor: _ultimoResultado!.convergente ? AppTokens.statusConferido : AppTokens.statusOutraSala,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sincronizarComPeer(AppDatabase db, IdentidadeAparelho? identidade, AparelhoRemoto peer) async {
    if (identidade == null) return;

    setState(() => _sincronizando = true);
    await HapticFeedback.mediumImpact();

    try {
      final res = await ClienteSincronizacaoLocal.sincronizar(
        aparelho: peer,
        db: db,
        identidadeLocal: identidade,
      );

      if (mounted) {
        setState(() {
          _sincronizando = false;
          _ultimoContato = DateTime.now();
          _ultimoResultado = res;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.mensagem ?? 'Sincronização realizada com sucesso!'),
            backgroundColor: AppTokens.statusConferido,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sincronizando = false;
          _ultimoResultado = ResultadoSincronizacao(
            eventosRecebidos: 0,
            eventosAplicados: 0,
            eventosQuarentena: 0,
            fotosRecebidas: 0,
            convergente: false,
            mensagem: 'Erro na sincronização: $e',
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: AppTokens.statusSemCadastro,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _exportarPacote(AppDatabase db) async {
    try {
      final bytesPacote = await SyncEngine.exportarPacoteTombox(db);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pacote .tombox gerado com sucesso (${(bytesPacote.length / 1024).toStringAsFixed(1)} KB)',
            ),
            backgroundColor: AppTokens.statusConferido,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar pacote: $e')),
        );
      }
    }
  }

  Future<void> _importarPacote(AppDatabase db) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (files.isNotEmpty) {
        final bytes = await files.first.xFile.readAsBytes();
        final resultado = await SyncEngine.importarPacoteTombox(db, bytes);

        if (mounted) {
          setState(() {
            _ultimoResultado = resultado;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Pacote importado: ${resultado.eventosAplicados} eventos aplicados, ${resultado.eventosQuarentena} em quarentena.',
              ),
              backgroundColor: resultado.convergente
                  ? AppTokens.statusConferido
                  : AppTokens.statusOutraSala,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao importar pacote: $e')),
        );
      }
    }
  }
}
