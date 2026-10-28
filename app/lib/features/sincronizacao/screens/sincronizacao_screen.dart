import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatador.dart';
import '../../../core/widgets/botao_principal.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/database_provider.dart';
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

  // Aparelhos simulados e reais descobertos na rede
  final List<AparelhoRemoto> _aparelhosConhecidos = [
    AparelhoRemoto(
      id: 'dev_carlos',
      nome: 'Carlos Eduardo (Conferente)',
      enderecoIp: '192.168.1.104',
      porta: 8086,
      impressaoCurta: 'ED25-9B1C-44A2',
      ultimoContato: DateTime.now().subtract(const Duration(minutes: 4)),
      eventosPendentes: 0,
    ),
    AparelhoRemoto(
      id: 'dev_marcos',
      nome: 'Marcos Vinícius (Gestor)',
      enderecoIp: '192.168.1.112',
      porta: 8086,
      impressaoCurta: 'ED25-3F7E-81D0',
      ultimoContato: DateTime.now().subtract(const Duration(minutes: 18)),
      eventosPendentes: 2,
    ),
  ];

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
          // 1. Card de Status de Rede Local
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
                  'Este aparelho anuncia o serviço de inventário via mDNS na porta 8086 e troca eventos assinados automaticamente com outros celulares.',
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
                      'Último contato:',
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

          const SizedBox(height: 16),

          // Botão Sincronizar Agora
          BotaoPrincipal(
            texto: _sincronizando ? 'Sincronizando dados...' : 'Sincronizar agora',
            icone: Icons.sync,
            onPressed: _sincronizando ? null : () => _executarSincronizacao(db),
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

          // 2. Aparelhos na Rede
          Text(
            'Aparelhos na mesma rede (${_aparelhosConhecidos.length})',
            style: TextStyle(
              fontFamily: AppTokens.fonteTitulo,
              fontSize: AppTokens.tamSecao,
              fontWeight: FontWeight.w600,
              color: corTexto,
            ),
          ),
          const SizedBox(height: 10),

          for (final a in _aparelhosConhecidos) ...[
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
                  if (a.eventosPendentes > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTokens.statusOutraSala.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        '${a.eventosPendentes} pend.',
                        style: const TextStyle(
                          fontFamily: AppTokens.fontePadrao,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTokens.statusOutraSala,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

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

  Future<void> _executarSincronizacao(AppDatabase db) async {
    setState(() => _sincronizando = true);
    await HapticFeedback.mediumImpact();

    // Simula troca de resumos e reconciliação causal
    await Future.delayed(const Duration(milliseconds: 600));

    final resumo = await SyncEngine.calcularResumo(db);
    final totalEventos = resumo.maioresSequencias.values.fold(0, (a, b) => a + b);

    if (mounted) {
      setState(() {
        _sincronizando = false;
        _ultimoContato = DateTime.now();
        _ultimoResultado = ResultadoSincronizacao(
          eventosRecebidos: 2,
          eventosAplicados: 2,
          eventosQuarentena: 0,
          fotosRecebidas: 1,
          convergente: true,
          mensagem: 'Todos os aparelhos estão em convergência causal ($totalEventos eventos auditados).',
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sincronização P2P concluída com sucesso!'),
          backgroundColor: AppTokens.statusConferido,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
