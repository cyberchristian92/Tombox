import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/local/database_provider.dart';
import '../../../domain/identidade/identidade_service.dart';
import '../../../domain/membros/membro_models.dart';
import '../../../domain/membros/membro_service.dart';
import '../../../domain/membros/perfil_provider.dart';

final membrosListaProvider = FutureProvider.autoDispose<List<Membro>>((ref) async {
  final db = ref.watch(databaseProvider);
  return MembroService.obterMembros(db);
});

class MembrosScreen extends ConsumerStatefulWidget {
  const MembrosScreen({super.key});

  @override
  ConsumerState<MembrosScreen> createState() => _MembrosScreenState();
}

class _MembrosScreenState extends ConsumerState<MembrosScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final corFundoBloco = isDark ? AppTokens.brancoEscuro : AppTokens.branco;
    final corBorda = isDark ? AppTokens.linhaEscura : AppTokens.linha;
    final corTexto = isDark ? AppTokens.grafiteEscuro : AppTokens.grafite;
    final corTextoSec = isDark ? AppTokens.cinzaEscuro : AppTokens.cinza;

    final membrosAsync = ref.watch(membrosListaProvider);
    final papelAtual = ref.watch(perfilUsuarioProvider);
    final isGestor = papelAtual == PapelUsuario.gestor;

    return Scaffold(
      backgroundColor: isDark ? AppTokens.papelEscuro : AppTokens.papel,
      appBar: AppBar(
        title: Text(
          'Equipe e convites',
          style: AppTokens.tituloSecao.copyWith(color: isDark ? AppTokens.grafiteEscuro : AppTokens.grafite),
        ),
        backgroundColor: corFundoBloco,
        elevation: 0,
        iconTheme: IconThemeData(color: corTexto),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: corBorda, height: 1),
        ),
      ),
      body: membrosAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTokens.tinta),
        ),
        error: (err, stack) => Center(
          child: Text('Erro ao listar membros: $err'),
        ),
        data: (membros) {
          return Column(
            children: [
              // Banner de contexto
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTokens.s16),
                decoration: BoxDecoration(
                  color: corFundoBloco,
                  border: Border(bottom: BorderSide(color: corBorda)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isGestor ? Icons.group_add_outlined : Icons.badge_outlined,
                      size: 20,
                      color: isGestor ? AppTokens.douradoMarca : AppTokens.tinta,
                    ),
                    const SizedBox(width: AppTokens.s12),
                    Expanded(
                      child: Text(
                        isGestor
                            ? 'Você é Gestor Patrimonial: pode convidar novos conferentes por QR Code de uso único e revogar acessos.'
                            : 'Você é Conferente: visualiza a composição da equipe inventariante e impressões digitais Ed25519.',
                        style: TextStyle(
                          fontFamily: AppTokens.fontePadrao,
                          fontSize: AppTokens.tamSecundario,
                          color: corTextoSec,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de Membros
              Expanded(
                child: membros.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 48, color: corTextoSec),
                            const SizedBox(height: 12),
                            Text(
                              'Nenhum membro registrado além do aparelho local',
                              style: TextStyle(fontFamily: AppTokens.fontePadrao, color: corTextoSec),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: membros.length,
                        itemBuilder: (context, index) {
                          final m = membros[index];
                          return _buildCardMembro(m, isGestor, corFundoBloco, corBorda, corTexto, corTextoSec);
                        },
                      ),
              ),

              // Botão de Convite por QR (Apenas Gestor)
              if (isGestor)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: corFundoBloco,
                    border: Border(top: BorderSide(color: corBorda)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: AppTokens.alturaBotaoPrincipal,
                    child: ElevatedButton.icon(
                      onPressed: _gerarConviteQr,
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('GERAR CONVITE POR QR CODE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTokens.tinta,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.raioBotao),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: AppTokens.fonteTitulo,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCardMembro(
    Membro membro,
    bool isGestor,
    Color corFundoBloco,
    Color corBorda,
    Color corTexto,
    Color corTextoSec,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: corFundoBloco,
        borderRadius: BorderRadius.circular(AppTokens.raioBloco),
        border: Border.all(
          color: membro.ativo ? corBorda : AppTokens.statusSemCadastro.withAlpha(100),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        membro.nome,
                        style: TextStyle(
                          fontFamily: AppTokens.fonteTitulo,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: corTexto,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Matrícula: ${membro.matricula}',
                        style: TextStyle(
                          fontFamily: AppTokens.fontePadrao,
                          fontSize: 13,
                          color: corTextoSec,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: membro.ativo
                        ? (membro.papel == PapelUsuario.gestor
                            ? AppTokens.douradoMarca.withAlpha(30)
                            : AppTokens.statusConferido.withAlpha(30))
                        : AppTokens.statusSemCadastro.withAlpha(30),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    membro.papel == PapelUsuario.gestor ? 'GESTOR' : 'CONFERENTE',
                    style: TextStyle(
                      fontFamily: AppTokens.fontePadrao,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: membro.ativo
                          ? (membro.papel == PapelUsuario.gestor
                              ? AppTokens.douradoMarca
                              : AppTokens.statusConferido)
                          : AppTokens.statusSemCadastro,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: corBorda),
            const SizedBox(height: 10),

            Row(
              children: [
                Icon(Icons.fingerprint, size: 16, color: corTextoSec),
                const SizedBox(width: 6),
                Text(
                  membro.impressaoDigital,
                  style: TextStyle(
                    fontFamily: AppTokens.fontePlaqueta,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    fontSize: 13,
                    color: AppTokens.tinta,
                  ),
                ),
                const Spacer(),
                if (!membro.ativo)
                  const Text(
                    'REVOGADO',
                    style: TextStyle(
                      fontFamily: AppTokens.fontePadrao,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.statusSemCadastro,
                    ),
                  ),
              ],
            ),

            if (isGestor && membro.ativo && membro.papel != PapelUsuario.gestor) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _confirmarRevogacao(membro),
                  icon: const Icon(Icons.person_remove_outlined, size: 16, color: AppTokens.statusSemCadastro),
                  label: const Text(
                    'REVOGAR ACESSO',
                    style: TextStyle(
                      fontFamily: AppTokens.fontePadrao,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.statusSemCadastro,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _gerarConviteQr() async {
    try {
      final idAparelho = await IdentidadeService.obterOuCriarIdentidade();
      final convite = MembroService.gerarConvite(
        unidadeId: 'unidade_demo',
        gestorChavePublica: idAparelho.publicKeyHex,
        papel: PapelUsuario.conferente,
        validade: const Duration(minutes: 15),
      );

      if (!mounted) return;

      final isDark = Theme.of(context).brightness == Brightness.dark;
      final corFundo = isDark ? AppTokens.brancoEscuro : AppTokens.branco;
      final corTexto = isDark ? AppTokens.grafiteEscuro : AppTokens.grafite;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: corFundo,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.raioFolha)),
        ),
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CONVITE PARA CONFERENTE',
                      style: AppTokens.tituloSecao.copyWith(color: corTexto),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Aponte a câmera do novo aparelho para ler o QR Code ou digite o código de uso único.',
                  style: TextStyle(
                    fontFamily: AppTokens.fontePadrao,
                    fontSize: AppTokens.tamSecundario,
                    color: AppTokens.cinza,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // QR Code
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: QrImageView(
                    data: convite.payloadQr,
                    version: QrVersions.auto,
                    size: 200,
                    gapless: false,
                  ),
                ),
                const SizedBox(height: 16),

                // Código amigável
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppTokens.papelEscuro : AppTokens.papel,
                    border: Border.all(color: isDark ? AppTokens.linhaEscura : AppTokens.linha),
                    borderRadius: BorderRadius.circular(AppTokens.raioBloco),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CÓDIGO: ${convite.codigo}',
                        style: const TextStyle(
                          fontFamily: AppTokens.fontePlaqueta,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                          color: AppTokens.tinta,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy_outlined, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: convite.codigo));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Código copiado!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.schedule_outlined, size: 14, color: AppTokens.douradoMarca),
                    SizedBox(width: 4),
                    Text(
                      'Válido por 15 minutos • Uso único',
                      style: TextStyle(fontFamily: AppTokens.fontePadrao, fontSize: 12, color: AppTokens.douradoMarca),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar convite: $e'), backgroundColor: AppTokens.statusSemCadastro),
      );
    }
  }

  void _confirmarRevogacao(Membro membro) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Revogar Membro', style: TextStyle(fontFamily: AppTokens.fonteTitulo)),
          content: Text(
            'Deseja revogar o acesso de ${membro.nome}? Novos eventos deste conferente serão rejeitados por todos os celulares.',
            style: const TextStyle(fontFamily: AppTokens.fontePadrao),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final db = ref.read(databaseProvider);
                try {
                  final idAparelho = await IdentidadeService.obterOuCriarIdentidade();
                  final keyPair = idAparelho.keyPair;
                  if (keyPair == null) throw Exception('Chave privada indisponível.');

                  await MembroService.revogarMembro(
                    db: db,
                    unidadeId: 'unidade_demo',
                    chavePublicaMembroRevogado: membro.chavePublica,
                    motivo: 'Revogação formal solicitada pelo Gestor',
                    keyPairGestor: keyPair,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Membro ${membro.nome} revogado.'),
                        backgroundColor: AppTokens.statusConferido,
                      ),
                    );
                    ref.invalidate(membrosListaProvider);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro: $e'), backgroundColor: AppTokens.statusSemCadastro),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.statusSemCadastro,
                foregroundColor: Colors.white,
              ),
              child: const Text('REVOGAR'),
            ),
          ],
        );
      },
    );
  }
}
