import '../../data/local/app_database.dart';

/// Dados extraídos da etiqueta do fabricante
class DadosEtiquetaFabricante {
  final String? fabricante;
  final String? modelo;
  final String? numeroSerie;
  final double confianca;
  final String textoOcrBruto;
  final Bem? bemDuplicadoEncontrado;

  const DadosEtiquetaFabricante({
    this.fabricante,
    this.modelo,
    this.numeroSerie,
    this.confianca = 0.90,
    required this.textoOcrBruto,
    this.bemDuplicadoEncontrado,
  });

  bool get isDuplicado => bemDuplicadoEncontrado != null;
}

/// Serviço de análise de OCR para etiquetas de fabricantes
class EtiquetaOcrService {
  static const List<String> marcasConhecidas = [
    'Dell',
    'HP',
    'Lenovo',
    'Positivo',
    'Samsung',
    'LG',
    'Epson',
    'Canon',
    'Apple',
    'Cisco',
    'Intelbras',
    'AOC',
    'Acer',
    'Asus',
    'Brother',
    'Philco',
    'Itautec',
  ];

  /// Extrai dados estruturados a partir do texto do OCR da etiqueta
  static Future<DadosEtiquetaFabricante> analisarEtiqueta({
    required String textoOcr,
    required AppDatabase db,
  }) async {
    final textoUpper = textoOcr.toUpperCase();
    String? fabricante;
    String? modelo;
    String? numeroSerie;

    // 1. Detecção de Fabricante
    for (final marca in marcasConhecidas) {
      if (textoUpper.contains(marca.toUpperCase())) {
        fabricante = marca;
        break;
      }
    }

    // 2. Extração de Número de Série (S/N, Serial, Service Tag)
    // Padrão Dell Service Tag: 7 caracteres alfanuméricos
    final matchServiceTag = RegExp(r'(?:SERVICE TAG|ST)[:\s]+([A-Z0-9]{7})\b').firstMatch(textoUpper);
    if (matchServiceTag != null) {
      numeroSerie = matchServiceTag.group(1);
    } else {
      // Padrão geral S/N ou Serial
      final matchSn = RegExp(r'(?:S/N|SERIAL(?: NO| NUMBER)?|SN)[:\s]+([A-Z0-9-]{6,16})\b').firstMatch(textoUpper);
      if (matchSn != null) {
        numeroSerie = matchSn.group(1);
      }
    }

    // 3. Extração de Modelo
    final matchModelo = RegExp(r'(?:MODEL|MODELO|MOD)[:\s]+([A-Z0-9\s-]{3,20})').firstMatch(textoUpper);
    if (matchModelo != null) {
      modelo = matchModelo.group(1)?.trim();
    } else if (fabricante != null) {
      // Heurística de modelos comuns por fabricante
      if (fabricante == 'Dell') {
        final m = RegExp(r'(LATITUDE\s\d{4}|OPTIPLEX\s\d{4}|VOSTRO\s\d{4}|P\d{2}\w{2})').firstMatch(textoUpper);
        if (m != null) modelo = m.group(1);
      } else if (fabricante == 'HP') {
        final m = RegExp(r'(PROBOOK\s\d{3}|ELITEDESK\s\d{3}|LASERJET\s\w+)').firstMatch(textoUpper);
        if (m != null) modelo = m.group(1);
      }
    }

    // 4. Detecção de Duplicidade no banco de dados local
    Bem? duplicado;
    if (numeroSerie != null && numeroSerie.isNotEmpty) {
      final bensComMesmoSerial = await (db.select(db.bens)
            ..where((b) => b.numeroSerie.equals(numeroSerie!)))
          .get();

      if (bensComMesmoSerial.isNotEmpty) {
        duplicado = bensComMesmoSerial.first;
      }
    }

    return DadosEtiquetaFabricante(
      fabricante: fabricante,
      modelo: modelo,
      numeroSerie: numeroSerie,
      confianca: (fabricante != null && numeroSerie != null) ? 0.95 : 0.80,
      textoOcrBruto: textoOcr,
      bemDuplicadoEncontrado: duplicado,
    );
  }

  /// Retorna dados simulados para a prévia Web com marcação explícita
  static DadosEtiquetaFabricante dadosSimuladosWeb() {
    return const DadosEtiquetaFabricante(
      fabricante: 'Dell (simulação)',
      modelo: 'Latitude 5420 (simulação)',
      numeroSerie: '8XYZ123 (simulação)',
      confianca: 0.96,
      textoOcrBruto: 'DELL LATITUDE 5420 S/N: 8XYZ123',
    );
  }
}
