import 'package:flutter_test/flutter_test.dart';
import 'package:tombox/domain/proveniencia/proveniencia_model.dart';

void main() {
  group('Proveniência por Campo (W3C PROV-O)', () {
    test('Serializa e deserializa atributo com proveniência completa', () {
      final dataHora = DateTime.utc(2026, 10, 27, 15, 30, 0);
      final prov = ProvenienciaCampo(
        valor: 'Dell Latitude 3420',
        fonte: 'ocr_etiqueta_fabricante',
        confianca: 0.96,
        evidencia: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        revisadoPor: 'Rosilene Miranda (Matr. 84920)',
        situacao: 'revisado',
        timestamp: dataHora,
      );

      final map = prov.toMap();
      expect(map['valor'], equals('Dell Latitude 3420'));
      expect(map['fonte'], equals('ocr_etiqueta_fabricante'));
      expect(map['confianca'], equals(0.96));
      expect(map['revisado_por'], contains('Rosilene'));
      expect(map['situacao'], equals('revisado'));

      final jsonStr = prov.toJson();
      final reconstruido = ProvenienciaCampo.fromJson(jsonStr);

      expect(reconstruido.valor, equals(prov.valor));
      expect(reconstruido.fonte, equals(prov.fonte));
      expect(reconstruido.confianca, equals(prov.confianca));
      expect(reconstruido.evidencia, equals(prov.evidencia));
      expect(reconstruido.revisadoPor, equals(prov.revisadoPor));
      expect(reconstruido.situacao, equals(prov.situacao));
      expect(reconstruido.timestamp, equals(dataHora));
    });

    test('Retorna descrições amigáveis corretas para a interface', () {
      const p1 = ProvenienciaCampo(
        valor: '010001',
        fonte: 'ocr_plaqueta',
        situacao: 'homologado',
      );
      expect(p1.descricaoFonte, equals('OCR da plaqueta patrimonial'));
      expect(p1.descricaoSituacao, equals('Homologado pelo Gestor'));

      const p2 = ProvenienciaCampo(
        valor: 'Cadeira Ergonômica Giratória',
        fonte: 'ia_classificacao',
        situacao: 'sugerido',
      );
      expect(p2.descricaoFonte, contains('visão computacional'));
      expect(p2.descricaoSituacao, contains('Sugerido por IA'));

      const p3 = ProvenienciaCampo(
        valor: 'Monitor Dell 24"',
        fonte: 'importacao',
        situacao: 'revisado',
      );
      expect(p3.descricaoFonte, contains('base inicial'));
      expect(p3.descricaoSituacao, equals('Revisado pelo Conferente'));
    });
  });
}
