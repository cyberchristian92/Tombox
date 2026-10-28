import 'dart:convert';

/// Situação do valor na esteira de auditoria e homologação
enum SituacaoProveniencia {
  sugerido, // IA ou OCR sem confirmação humana
  revisado, // Pessoa conferente confirmou em tela
  homologado, // Gestor aprovou oficialmente
}

/// Fonte de onde o dado foi extraído
enum FonteProveniencia {
  importacao,
  leituraCodigo,
  ocrPlaqueta,
  ocrEtiquetaFabricante,
  iaClassificacao,
  pessoa,
  rfid,
}

/// Representa um atributo de patrimônio acompanhado de sua proveniência estrita (W3C PROV-O)
class ProvenienciaCampo {
  final dynamic valor;
  final String fonte;
  final double confianca;
  final String? evidencia; // hash da foto ou texto bruto
  final String? revisadoPor; // chave pública ou nome
  final String situacao;
  final DateTime? timestamp;

  const ProvenienciaCampo({
    required this.valor,
    required this.fonte,
    this.confianca = 1.0,
    this.evidencia,
    this.revisadoPor,
    this.situacao = 'revisado',
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'valor': valor,
      'fonte': fonte,
      'confianca': confianca,
      if (evidencia != null) 'evidencia': evidencia,
      if (revisadoPor != null) 'revisado_por': revisadoPor,
      'situacao': situacao,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    };
  }

  factory ProvenienciaCampo.fromMap(Map<String, dynamic> map) {
    return ProvenienciaCampo(
      valor: map['valor'],
      fonte: map['fonte'] as String? ?? 'importacao',
      confianca: (map['confianca'] as num?)?.toDouble() ?? 1.0,
      evidencia: map['evidencia'] as String?,
      revisadoPor: map['revisado_por'] as String?,
      situacao: map['situacao'] as String? ?? 'revisado',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String)
          : null,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ProvenienciaCampo.fromJson(String source) =>
      ProvenienciaCampo.fromMap(jsonDecode(source) as Map<String, dynamic>);

  /// Retorna descrição amigável da fonte para exibição na UI
  String get descricaoFonte {
    switch (fonte) {
      case 'ocr_plaqueta':
        return 'OCR da plaqueta patrimonial';
      case 'ocr_etiqueta_fabricante':
        return 'OCR da etiqueta do fabricante';
      case 'ia_classificacao':
        return 'Classificação por IA (visão computacional)';
      case 'leitura_codigo':
        return 'Leitura de código de barras / QR code';
      case 'rfid':
        return 'Leitura via RFID sem fio';
      case 'pessoa':
        return 'Digitado manualmente pelo conferente';
      case 'importacao':
      default:
        return 'Importação de base inicial do TJPA';
    }
  }

  /// Retorna descrição amigável da situação
  String get descricaoSituacao {
    switch (situacao) {
      case 'sugerido':
        return 'Sugerido por IA (não homologado)';
      case 'homologado':
        return 'Homologado pelo Gestor';
      case 'revisado':
      default:
        return 'Revisado pelo Conferente';
    }
  }
}
