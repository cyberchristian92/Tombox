import 'dart:convert';
import '../identidade/identidade_service.dart';

/// Papéis formais de atuação patrimonial conforme arquitetura v2
enum PapelUsuario {
  gestor,
  conferente;

  String get rotulo {
    switch (this) {
      case PapelUsuario.gestor:
        return 'Gestor Patrimonial';
      case PapelUsuario.conferente:
        return 'Conferente de Campo';
    }
  }

  String get descricao {
    switch (this) {
      case PapelUsuario.gestor:
        return 'Cria unidade, convida e revoga membros, homologa conferências, resolve divergências e emite termos.';
      case PapelUsuario.conferente:
        return 'Abre salas, lê plaquetas e códigos de barra, registra estado físico, fotos e propõe novos bens.';
    }
  }

  static PapelUsuario aPartirDeTexto(String? texto) {
    if (texto == null) return PapelUsuario.conferente;
    final t = texto.toLowerCase().trim();
    if (t == 'gestor') return PapelUsuario.gestor;
    return PapelUsuario.conferente;
  }
}

/// Representa um membro registrado da comissão inventariante
class Membro {
  final String chavePublica;
  final String nome;
  final String matricula;
  final PapelUsuario papel;
  final bool ativo;
  final DateTime dataIngresso;
  final String? revogadoPor;
  final DateTime? dataRevogacao;
  final String? motivoRevogacao;

  const Membro({
    required this.chavePublica,
    required this.nome,
    required this.matricula,
    required this.papel,
    this.ativo = true,
    required this.dataIngresso,
    this.revogadoPor,
    this.dataRevogacao,
    this.motivoRevogacao,
  });

  String get impressaoDigital {
    return IdentidadeService.gerarImpressaoCurtaDeHex(chavePublica);
  }

  Map<String, dynamic> toMap() {
    return {
      'chave_publica': chavePublica,
      'nome': nome,
      'matricula': matricula,
      'papel': papel.name,
      'ativo': ativo,
      'data_ingresso': dataIngresso.toUtc().toIso8601String(),
      'revogado_por': revogadoPor,
      'data_revogacao': dataRevogacao?.toUtc().toIso8601String(),
      'motivo_revogacao': motivoRevogacao,
    };
  }

  factory Membro.fromMap(Map<String, dynamic> map) {
    return Membro(
      chavePublica: map['chave_publica'] as String? ?? map['autor'] as String? ?? '',
      nome: map['nome'] as String? ?? 'Conferente',
      matricula: map['matricula'] as String? ?? 'TJPA-9999',
      papel: PapelUsuario.aPartirDeTexto(map['papel']?.toString()),
      ativo: map['ativo'] as bool? ?? true,
      dataIngresso: map['data_ingresso'] != null
          ? DateTime.parse(map['data_ingresso'].toString())
          : DateTime.now(),
      revogadoPor: map['revogado_por'] as String?,
      dataRevogacao: map['data_revogacao'] != null
          ? DateTime.parse(map['data_revogacao'].toString())
          : null,
      motivoRevogacao: map['motivo_revogacao'] as String?,
    );
  }
}

/// Convite temporário de uso único gerado por um Gestor para ingresso na unidade
class ConviteMembro {
  final String codigo;
  final String unidadeId;
  final PapelUsuario papel;
  final String criadoPor;
  final DateTime criadoEm;
  final DateTime expiraEm;
  final bool usado;
  final String? usadoPor;

  const ConviteMembro({
    required this.codigo,
    required this.unidadeId,
    required this.papel,
    required this.criadoPor,
    required this.criadoEm,
    required this.expiraEm,
    this.usado = false,
    this.usadoPor,
  });

  bool get expirado => DateTime.now().toUtc().isAfter(expiraEm);

  bool get isValido => !usado && !expirado;

  String get payloadQr {
    return jsonEncode({
      'protocolo': 'tombox_convite_v2',
      'unidade_id': unidadeId,
      'codigo': codigo,
      'papel': papel.name,
      'criado_por': criadoPor,
      'expira_em': expiraEm.toUtc().toIso8601String(),
    });
  }

  static ConviteMembro? tentarDecodificarQr(String payloadTexto) {
    try {
      final mapa = jsonDecode(payloadTexto);
      if (mapa is Map && mapa['protocolo'] == 'tombox_convite_v2') {
        return ConviteMembro(
          codigo: mapa['codigo'].toString(),
          unidadeId: mapa['unidade_id'].toString(),
          papel: PapelUsuario.aPartirDeTexto(mapa['papel']?.toString()),
          criadoPor: mapa['criado_por'].toString(),
          criadoEm: DateTime.now().toUtc(),
          expiraEm: DateTime.parse(mapa['expira_em'].toString()),
        );
      }
    } catch (_) {}
    return null;
  }
}
