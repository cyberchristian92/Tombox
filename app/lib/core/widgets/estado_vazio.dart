import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Esqueleto v2: linhas cinza claro com as mesmas medidas da lista.
/// Nunca mostra zeros enquanto carrega.
class Esqueleto extends StatelessWidget {
  final int? linhas;
  final double? altura;
  final double? largura;

  const Esqueleto({
    super.key,
    this.linhas,
    this.altura,
    this.largura,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final corBloco = isDark
        ? AppTokens.brancoEscuro
        : AppTokens.aluminio.withAlpha(100);

    if (altura != null) {
      return Container(
        height: altura,
        width: largura ?? double.infinity,
        decoration: BoxDecoration(
          color: corBloco,
          borderRadius: BorderRadius.circular(AppTokens.raioBloco),
        ),
      );
    }

    final numLinhas = linhas ?? 5;

    return Column(
      children: List.generate(numLinhas, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              // Plaqueta esqueleto
              Container(
                width: 80,
                height: 24,
                decoration: BoxDecoration(
                  color: corBloco,
                  borderRadius: BorderRadius.circular(AppTokens.raioPlaquetaPequena),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: corBloco,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 12,
                      width: 120,
                      decoration: BoxDecoration(
                        color: corBloco,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: corBloco,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Estado vazio v2: ícone de traço grande, frase direta, botão principal.
/// Sem ilustração.
class EstadoVazio extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String? subtitulo;
  final String? textoBotaoPrincipal;
  final VoidCallback? onBotaoPrincipal;
  final String? textoBotaoSecundario;
  final VoidCallback? onBotaoSecundario;

  const EstadoVazio({
    super.key,
    required this.icone,
    required this.titulo,
    this.subtitulo,
    this.textoBotaoPrincipal,
    this.onBotaoPrincipal,
    this.textoBotaoSecundario,
    this.onBotaoSecundario,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final corTexto = isDark ? AppTokens.grafiteEscuro : AppTokens.grafite;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.paddingLateral * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icone,
              size: 56,
              color: isDark ? AppTokens.cinzaEscuro : AppTokens.cinza,
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTokens.fonteTitulo,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: corTexto,
              ),
            ),
            if (subtitulo != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitulo!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTokens.fontePadrao,
                  fontSize: 14,
                  color: AppTokens.cinza,
                  height: 1.3,
                ),
              ),
            ],
            if (textoBotaoPrincipal != null && onBotaoPrincipal != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: Material(
                  color: isDark ? AppTokens.tintaEscuro : AppTokens.tinta,
                  borderRadius: BorderRadius.circular(AppTokens.raioBotao),
                  child: InkWell(
                    onTap: onBotaoPrincipal,
                    borderRadius: BorderRadius.circular(AppTokens.raioBotao),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: Text(
                          textoBotaoPrincipal!,
                          style: TextStyle(
                            fontFamily: AppTokens.fontePadrao,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTokens.grafite : AppTokens.branco,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (textoBotaoSecundario != null && onBotaoSecundario != null) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: onBotaoSecundario,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    textoBotaoSecundario!,
                    style: TextStyle(
                      fontFamily: AppTokens.fontePadrao,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTokens.tintaEscuro : AppTokens.tinta,
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
}
