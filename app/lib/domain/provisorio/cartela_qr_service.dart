import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Serviço de geração de cartela de plaquetas e QR Codes provisórios em PDF A4
class CartelaQrService {
  /// Gera cartela A4 com 24 etiquetas adesivas provisórias (4 colunas x 6 linhas)
  static Future<Uint8List> gerarCartelaA4({
    int numeroInicial = 1,
    int quantidade = 24,
    String prefixoAparelho = 'PROV-000',
  }) async {
    final doc = pw.Document(title: 'Cartela de QR Codes Provisórios - TJPA');

    final etiquetas = <String>[];
    for (int i = 0; i < quantidade; i++) {
      final numFormatado = (numeroInicial + i).toString().padLeft(3, '0');
      etiquetas.add('$prefixoAparelho-$numFormatado');
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            children: [
              // Cabeçalho da folha
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TRIBUNAL DE JUSTIÇA DO ESTADO DO PARÁ - TJPA',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'CARTELA DE PLAQUETAS PROVISÓRIAS',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Divider(thickness: 0.5, height: 10),

              // Grade de 4 colunas x 6 linhas
              pw.Expanded(
                child: pw.GridView(
                  crossAxisCount: 4,
                  childAspectRatio: 1.15,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: etiquetas.map((codigo) {
                    return pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColors.grey500,
                          width: 0.8,
                          style: pw.BorderStyle.dashed,
                        ),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                      ),
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            'TJPA - TOMBOX',
                            style: pw.TextStyle(
                              fontSize: 6.5,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey800,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: codigo,
                            width: 52,
                            height: 52,
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            codigo,
                            style: pw.TextStyle(
                              fontSize: 7.5,
                              fontWeight: pw.FontWeight.bold,
                              font: pw.Font.courier(),
                            ),
                          ),
                          pw.Text(
                            'PLAQUETA PROVISÓRIA',
                            style: const pw.TextStyle(
                              fontSize: 5,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Folha A4 para impressão em papel adesivo picotado. Cada código é de uso único para novos bens identificados em campo.',
                style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
}
