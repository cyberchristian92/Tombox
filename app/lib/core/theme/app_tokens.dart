import 'package:flutter/material.dart';

/// Tokens visuais v2 do Tombox conforme design-ui-v2.md
/// Linguagem visual: plaqueta de alumínio e livro de tombo
class AppTokens {
  // --- Escala de Espaçamento ---
  static const double s4 = 4.0;
  static const double s6 = 6.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;

  static const double paddingLateral = 16.0;
  static const double toqueMinimo = 48.0;
  static const double alturaBotaoPrincipal = 48.0;

  // --- Raios v2: nada acima de 6 exceto folhas inferiores ---
  static const double raioBotao = 4.0;
  static const double raioBloco = 4.0;
  static const double raioPlaquetaGrande = 4.0;
  static const double raioPlaquetaPequena = 3.0;
  static const double raioCarimbo = 3.0;
  static const double raioBarra = 2.0;
  static const double raioConferir = 6.0;
  static const double raioFolha = 12.0;

  // --- Famílias Tipográficas v2: Barlow ---
  static const String fontePadrao = 'Barlow';
  static const String fonteTitulo = 'BarlowSemiCondensed';
  static const String fontePlaqueta = 'BarlowCondensed';

  // --- Cores de Superfície (Modo Claro) ---
  static const Color tinta = Color(0xFF13365C);
  static const Color papel = Color(0xFFF2F4F6);
  static const Color branco = Color(0xFFFFFFFF);
  static const Color grafite = Color(0xFF1F2933);
  static const Color cinza = Color(0xFF5B6672);
  static const Color linha = Color(0xFFD6DCE1);
  static const Color douradoMarca = Color(0xFFC9A227);

  // --- Cores da Plaqueta ---
  static const Color aluminio = Color(0xFFDDE3E8);
  static const Color aluminioBorda = Color(0xFFA9B4BE);
  static const Color aluminioRebite = Color(0xFFB7C1CA);

  // --- Cores de Superfície (Modo Escuro) ---
  static const Color papelEscuro = Color(0xFF11161C);
  static const Color brancoEscuro = Color(0xFF1A2129);
  static const Color grafiteEscuro = Color(0xFFE6EAEE);
  static const Color cinzaEscuro = Color(0xFF9AA5B1);
  static const Color linhaEscura = Color(0xFF2C3640);
  static const Color tintaEscuro = Color(0xFF7FA6D6);
  static const Color barraEscura = Color(0xFF0F2B4A);

  // --- Cores de Status (Fixas, nunca dependem da marca) ---
  static const Color statusConferido = Color(0xFF2F7D4F);
  static const Color statusOutraSala = Color(0xFFB5781A);
  static const Color statusSemCadastro = Color(0xFFB3261E);
  static const Color statusPendente = Color(0xFF98A2AD);

  // Ícones de status: traço fino (Outlined)
  static const IconData iconeConferido = Icons.check_outlined;
  static const IconData iconeOutraSala = Icons.swap_horiz_outlined;
  static const IconData iconeSemCadastro = Icons.error_outline;
  static const IconData iconePendente = Icons.schedule_outlined;

  // --- Tamanhos de Tipografia v2 ---
  static const double tamTituloTela = 26.0;
  static const double tamTituloFicha = 22.0;
  static const double tamSecao = 18.0;
  static const double tamLinhaPrincipal = 15.0;
  static const double tamSecundario = 13.0;
  static const double tamNavegacao = 12.0;
  static const double alturaLinhaTexto = 1.3;

  // --- Features tipográficas ---
  static const List<FontFeature> algarismosTabulares = [
    FontFeature.tabularFigures(),
  ];

  // --- Estilos de Texto v2 ---
  static const TextStyle tituloTela = TextStyle(
    fontFamily: fonteTitulo,
    fontSize: tamTituloTela,
    fontWeight: FontWeight.w600,
    color: grafite,
    height: 1.2,
  );

  static const TextStyle tituloFicha = TextStyle(
    fontFamily: fonteTitulo,
    fontSize: tamTituloFicha,
    fontWeight: FontWeight.w600,
    color: grafite,
    height: 1.2,
  );

  static const TextStyle tituloSecao = TextStyle(
    fontFamily: fonteTitulo,
    fontSize: tamSecao,
    fontWeight: FontWeight.w600,
    color: grafite,
    height: 1.2,
  );

  static const TextStyle linhaPrincipal = TextStyle(
    fontFamily: fontePadrao,
    fontSize: tamLinhaPrincipal,
    fontWeight: FontWeight.w600,
    color: grafite,
  );

  static const TextStyle linhaSecundaria = TextStyle(
    fontFamily: fontePadrao,
    fontSize: tamSecundario,
    fontWeight: FontWeight.w400,
    color: cinza,
  );

  // --- Estilos da Plaqueta ---
  static const TextStyle plaquetaGrandeNumero = TextStyle(
    fontFamily: fontePlaqueta,
    fontSize: 52,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.08 * 52, // 0.08 em
    color: grafite,
    fontFeatures: algarismosTabulares,
  );

  static const TextStyle plaquetaGrandeSubtitulo = TextStyle(
    fontFamily: fontePadrao,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: cinza,
  );

  static const TextStyle plaquetaPequenaNumero = TextStyle(
    fontFamily: fontePlaqueta,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.06 * 17, // 0.06 em
    color: grafite,
    fontFeatures: algarismosTabulares,
  );

  // --- Contador (ex: 7/18) ---
  static const TextStyle contadorNumero = TextStyle(
    fontFamily: fontePlaqueta,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: grafite,
    fontFeatures: algarismosTabulares,
  );

  // --- Ícone por Categoria (ícones de traço fino) ---
  static IconData iconePorCategoria(String? categoria) {
    if (categoria == null) return Icons.inventory_2_outlined;
    final c = categoria.toLowerCase();
    if (c.contains('inform') || c.contains('comput') || c.contains('ti') ||
        c.contains('monitor') || c.contains('notebook')) {
      return Icons.computer_outlined;
    } else if (c.contains('mobil') || c.contains('mesa') ||
        c.contains('cadeira') || c.contains('armario') || c.contains('arquivo')) {
      return Icons.chair_outlined;
    } else if (c.contains('aparelh') || c.contains('eletro') ||
        c.contains('ar cond') || c.contains('bebedouro') || c.contains('cafeteira')) {
      return Icons.kitchen_outlined;
    } else if (c.contains('veic')) {
      return Icons.directions_car_outlined;
    }
    return Icons.inventory_2_outlined;
  }

  /// Cor do marcador de situação
  static Color corSituacao(String situacao) {
    switch (situacao) {
      case 'conferido':
        return statusConferido;
      case 'outra_sala':
        return statusOutraSala;
      case 'sem_cadastro':
      case 'nao_localizado':
        return statusSemCadastro;
      case 'pendente':
      default:
        return statusPendente;
    }
  }

  /// Divisória padrão (1 px na cor linha)
  static const BorderSide divisoria = BorderSide(
    color: linha,
    width: 1,
  );

  static const BorderSide divisoriaEscura = BorderSide(
    color: linhaEscura,
    width: 1,
  );

  // --- Aliases de compatibilidade para código em transição ---
  static const Color statusEncontrado = statusConferido;
  static const IconData iconeEncontrado = iconeConferido;
  static const Color statusNaoCadastrado = statusSemCadastro;
  static const IconData iconeNaoCadastrado = iconeSemCadastro;
  static const Color statusAlerta = statusOutraSala;
  static const Color statusErro = statusSemCadastro;
  static const Color statusSucesso = statusConferido;
  static const Color statusNeutro = statusPendente;
  static const IconData iconeAlerta = iconeOutraSala;
  static const IconData iconeErro = iconeSemCadastro;
  static const IconData iconeSucesso = iconeConferido;
  static const IconData iconeNeutro = iconePendente;
  static const TextStyle tombamentoPequeno = plaquetaPequenaNumero;
  static const TextStyle tombamentoMedio = TextStyle(
    fontFamily: fontePlaqueta,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    fontFeatures: algarismosTabulares,
    color: grafite,
  );
  static const TextStyle tombamentoGrande = plaquetaGrandeNumero;
  static const double raioCard = raioBloco;
  static const double raioChip = raioCarimbo;
  static const String fonteMono = fontePlaqueta;
  static const Color corTexto = grafite;
  static const Color corTextoSecundario = cinza;
  static const Color corFundo = papel;
  static const Color corBranca = branco;
}
