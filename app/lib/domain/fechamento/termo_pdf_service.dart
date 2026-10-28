import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'fechamento_models.dart';

/// Serviço responsável por gerar o Termo de Responsabilidade em formato PDF A4
class TermoPdfService {
  /// Gera o arquivo PDF formatado do Termo de Responsabilidade
  static Future<Uint8List> gerarTermoPdf(DadosTermoResponsabilidade dados) async {
    final doc = pw.Document(
      title: 'Termo de Responsabilidade - ${dados.resumo.salaNome}',
      author: 'TJPA - Tombox Inventário Patrimonial',
    );

    final formatoDataHora = DateFormat('dd/MM/yyyy HH:mm:ss');
    final dataHoraFormatada = formatoDataHora.format(dados.dataHora);

    pw.ImageProvider? assinaturaImagem;
    if (dados.assinaturaBytes.isNotEmpty) {
      assinaturaImagem = pw.MemoryImage(dados.assinaturaBytes);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // 1. Cabeçalho Institucional
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PODER JUDICIÁRIO DO ESTADO DO PARÁ',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'TRIBUNAL DE JUSTIÇA DO ESTADO DO PARÁ - TJPA',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      'Departamento de Patrimônio e Logística - Tombox',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey800, width: 1),
                  ),
                  child: pw.Text(
                    'TERMO DE RESPONSABILIDADE',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            pw.Divider(thickness: 1, height: 16),

            // 2. Metadados do Local e Conferência
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Unidade Administrativa: ${dados.resumo.unidadeNome}',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Local / Sala: ${dados.resumo.salaNome} (Cód: ${dados.resumo.salaId})',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Responsável do Setor: ${dados.responsavelNome} (Matrícula: ${dados.responsavelMatricula})',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Data/Hora: $dataHoraFormatada',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Conferente: ${dados.conferenteNome}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Chave: ${dados.chaveConferente}',
                        style: pw.TextStyle(fontSize: 8, font: pw.Font.courier()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // 3. Resumo Estatístico da Conferência
            pw.Text(
              '1. RESUMO DA CONFERÊNCIA INVENTARIAL',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cellHeader('Esperados'),
                    _cellHeader('Conferidos'),
                    _cellHeader('Não Localizados'),
                    _cellHeader('Outra Sala'),
                    _cellHeader('Sem Cadastro'),
                    _cellHeader('Taxa de Cobertura'),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _cellValue('${dados.resumo.totalEsperados}'),
                    _cellValue('${dados.resumo.totalConferidos}'),
                    _cellValue('${dados.resumo.totalNaoEncontrados}'),
                    _cellValue('${dados.resumo.totalOutraSala}'),
                    _cellValue('${dados.resumo.totalSemCadastro}'),
                    _cellValue('${dados.resumo.taxaConferencia.toStringAsFixed(1)}%'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            // 4. Relação dos Bens Inventariados
            pw.Text(
              '2. RELAÇÃO DE BENS PATRIMONIAIS NO LOCAL',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FixedColumnWidth(60),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FixedColumnWidth(65),
                4: const pw.FixedColumnWidth(55),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cellHeader('Tombamento'),
                    _cellHeader('Descrição'),
                    _cellHeader('Categoria'),
                    _cellHeader('Situação'),
                    _cellHeader('Estado'),
                  ],
                ),
                for (final bem in dados.resumo.bens)
                  pw.TableRow(
                    children: [
                      _cellValue(bem.tombamento),
                      _cellValue(bem.descricao),
                      _cellValue(bem.categoria),
                      _cellValue(_formatarSituacao(bem.situacao)),
                      _cellValue(bem.estadoConservacao),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 14),

            // 5. Termo de Aceite e Responsabilidade
            pw.Text(
              '3. DECLARAÇÃO DE RESPONSABILIDADE',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Text(
                'Declaro para os devidos fins de direito e controle administrativo que conferi os bens acima relacionados presentes no setor sob minha responsabilidade nesta data, assumindo a fiel guarda e conservação dos mesmos, de acordo com as normas patrimoniais vigentes no Tribunal de Justiça do Estado do Pará.',
                style: const pw.TextStyle(fontSize: 9, lineSpacing: 2),
                textAlign: pw.TextAlign.justify,
              ),
            ),
            pw.SizedBox(height: 16),

            // 6. Bloco de Assinaturas
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Assinatura do Responsável (Canvas capturado)
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      if (assinaturaImagem != null)
                        pw.Container(
                          height: 50,
                          child: pw.Image(assinaturaImagem, fit: pw.BoxFit.contain),
                        )
                      else
                        pw.SizedBox(height: 50),
                      pw.Container(width: 200, height: 1, color: PdfColors.grey700),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        dados.responsavelNome,
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Responsável pelo Setor - Matrícula: ${dados.responsavelMatricula}',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                // Assinatura do Conferente / Gestor
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.SizedBox(height: 50),
                      pw.Container(width: 200, height: 1, color: PdfColors.grey700),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        dados.conferenteNome,
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Conferente Patrimonial - Matrícula: ${dados.conferenteMatricula}',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // 7. Rodapé de Auditoria e Integridade Criptográfica
            pw.Divider(thickness: 0.5, color: PdfColors.grey400),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Cadeia de Auditoria Causal (Ed25519 & SHA-256):',
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      'Hash do Último Evento: ${dados.resumo.hashUltimoEvento}',
                      style: pw.TextStyle(fontSize: 6.5, font: pw.Font.courier()),
                    ),
                  ],
                ),
                pw.Text(
                  'Tombox TJPA - Documento Auditável',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _cellHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _cellValue(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8),
      ),
    );
  }

  static String _formatarSituacao(String situacao) {
    switch (situacao.toLowerCase()) {
      case 'conferido':
        return 'CONFERIDO';
      case 'pendente':
        return 'NÃO LOCALIZADO';
      case 'outra_sala':
        return 'OUTRA SALA';
      case 'sem_cadastro':
        return 'SEM CADASTRO';
      default:
        return situacao.toUpperCase();
    }
  }
}
