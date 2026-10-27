import 'package:flutter_test/flutter_test.dart';
import 'package:tombox/domain/casamento/casamento_models.dart';
import 'package:tombox/domain/casamento/casamento_motor.dart';
import 'package:tombox/domain/casamento/distancia_ponderada.dart';
import 'package:tombox/domain/casamento/estabilidade_filtro.dart';

void main() {
  group('Distância Ponderada de Levenshtein', () {
    test('Distância entre strings idênticas é 0.0', () {
      expect(DistanciaPonderada.calcular('010001', '010001'), 0.0);
    });

    test('Pares confundíveis (0/O, 1/I, 1/L, 8/B, 5/S, 2/Z, 6/G) custam 0.3', () {
      expect(DistanciaPonderada.calcular('010001', 'O10001'), 0.3);
      expect(DistanciaPonderada.calcular('010001', '0I0001'), 0.3);
      expect(DistanciaPonderada.calcular('010001', '0L0001'), 0.3);
      expect(DistanciaPonderada.calcular('080001', '0B0001'), 0.3);
      expect(DistanciaPonderada.calcular('050001', '0S0001'), 0.3);
      expect(DistanciaPonderada.calcular('020001', '0Z0001'), 0.3);
      expect(DistanciaPonderada.calcular('060001', '0G0001'), 0.3);
    });

    test('Múltiplos pares confundíveis somam 0.3 por substituição', () {
      // 2 trocas: 0->O (0.3) + 8->B (0.3) = 0.6
      expect(DistanciaPonderada.calcular('080001', 'OB0001'), 0.6);
    });

    test('Substituição de caracteres normais não-confundíveis custa 1.0', () {
      expect(DistanciaPonderada.calcular('010001', '010002'), 1.0);
    });

    test('Inserção e deleção custam 1.0', () {
      expect(DistanciaPonderada.calcular('010001', '01000'), 1.0);
      expect(DistanciaPonderada.calcular('010001', '0100019'), 1.0);
    });
  });

  group('CasamentoMotor - Regras de Decisão e Classificação', () {
    late CasamentoMotor motor;
    final bensSala = {'010001', '010002', '010003', '010004', '010005'};
    final bensOutraSala = {'020001', '020002', '030001', '030002'};
    final todosBens = {...bensSala, ...bensOutraSala};

    setUp(() {
      motor = CasamentoMotor(
        bensSala: bensSala,
        todosBensUnidade: todosBens,
      );
    });

    test('Leitura exata na sala atual retorna CONFIRMADO e VERDE', () {
      final res = motor.avaliarTextoOcr('010001');
      expect(res.decisao, DecisaoLeitura.confirmado);
      expect(res.classificacao, ClassificacaoPlaqueta.verde);
      expect(res.tombamentoIdentificado, '010001');
      expect(res.menorDistancia, 0.0);
    });

    test('Leitura exata de outra sala retorna CONFIRMADO e AMARELO', () {
      final res = motor.avaliarTextoOcr('020001');
      expect(res.decisao, DecisaoLeitura.confirmado);
      expect(res.classificacao, ClassificacaoPlaqueta.amarelo);
      expect(res.tombamentoIdentificado, '020001');
      expect(res.menorDistancia, 0.0);
    });

    test('Código de barras exato que não existe na unidade retorna VERMELHO', () {
      final res = motor.avaliarCodigoBarras('999999');
      expect(res.decisao, DecisaoLeitura.confirmado);
      expect(res.classificacao, ClassificacaoPlaqueta.vermelho);
      expect(res.tombamentoIdentificado, '999999');
    });

    test('OCR com normalização de trocas confundíveis resulta em CONFIRMADO', () {
      // O10001 é normalizado no passo 1 para 010001
      final res = motor.avaliarTextoOcr('O10001');
      expect(res.decisao, DecisaoLeitura.confirmado);
      expect(res.tombamentoIdentificado, '010001');
    });

    test('Preserva zeros à esquerda e pontuações na leitura do OCR', () {
      final res = motor.avaliarTextoOcr(' 01.000-2 ');
      expect(res.decisao, DecisaoLeitura.confirmado);
      expect(res.tombamentoIdentificado, '010002');
    });

    test('Leitura provável quando distância <= 1.0 e vantagem >= 0.5', () {
      // Supondo uma leitura com 1 caractere divergente não-confundível (distância 1.0)
      // Se não houver concorrente próximo na unidade (vantagem >= 0.5):
      final motorIsolado = CasamentoMotor(
        bensSala: {'010001'},
        todosBensUnidade: {'010001', '099999'},
      );

      // '010007' tem distância 1.0 para '010001' e distância 5.0 para '099999'
      final res = motorIsolado.avaliarTextoOcr('010007');
      expect(res.decisao, DecisaoLeitura.provavel);
      expect(res.tombamentoIdentificado, '010001');
      expect(res.classificacao, ClassificacaoPlaqueta.verde);
      expect(res.menorDistancia, 1.0);
    });

    test('Descarta quando houver empate ou vantagem < 0.5 entre dois candidatos', () {
      // '010001' e '010002' estão cadastrados
      // Leitura '010009': distância 1.0 para ambos (vantagem = 0.0 < 0.5) -> deve descartar!
      final res = motor.avaliarTextoOcr('010009');
      expect(res.decisao, DecisaoLeitura.descartado);
    });

    test('Descarta tokens que não atendem ao tamanho mínimo ou % de dígitos', () {
      // Texto muito curto
      expect(motor.avaliarTextoOcr('12').decisao, DecisaoLeitura.descartado);
      // Texto com menos de 60% de dígitos
      expect(motor.avaliarTextoOcr('ABCDEF').decisao, DecisaoLeitura.descartado);
      expect(motor.avaliarTextoOcr('TRIBUNAL').decisao, DecisaoLeitura.descartado);
    });
  });

  group('EstabilidadeFiltro - Temporal e Suavização', () {
    late EstabilidadeFiltro filtro;

    setUp(() {
      filtro = EstabilidadeFiltro();
    });

    test('Exige pelo menos 2 quadros dentro de 1 segundo para ser estável', () {
      const caixa = RectDeteccao(left: 10, top: 10, width: 100, height: 50);
      final t0 = DateTime(2026, 10, 27, 10, 0, 0, 0);

      // 1º quadro: ainda não é estável
      final estavel1 = filtro.registrarDeteccao(
        tombamento: '010001',
        caixa: caixa,
        classificacao: ClassificacaoPlaqueta.verde,
        isProvavel: false,
        timestamp: t0,
      );
      expect(estavel1, isFalse);
      expect(filtro.obterCaixasAtivas(timestamp: t0), isEmpty);

      // 2º quadro após 300 ms: torna-se estável!
      final t1 = t0.add(const Duration(milliseconds: 300));
      final estavel2 = filtro.registrarDeteccao(
        tombamento: '010001',
        caixa: caixa,
        classificacao: ClassificacaoPlaqueta.verde,
        isProvavel: false,
        timestamp: t1,
      );
      expect(estavel2, isTrue);
      expect(filtro.obterCaixasAtivas(timestamp: t1).length, 1);
    });

    test('Descarta quadros antigos (> 1s) para cálculo de estabilidade', () {
      const caixa = RectDeteccao(left: 10, top: 10, width: 100, height: 50);
      final t0 = DateTime(2026, 10, 27, 10, 0, 0, 0);

      filtro.registrarDeteccao(
        tombamento: '010001',
        caixa: caixa,
        classificacao: ClassificacaoPlaqueta.verde,
        isProvavel: false,
        timestamp: t0,
      );

      // 2º quadro após 1500 ms (> 1s): não considera o t0, logo ainda não é estável
      final t2 = t0.add(const Duration(milliseconds: 1500));
      final estavel = filtro.registrarDeteccao(
        tombamento: '010001',
        caixa: caixa,
        classificacao: ClassificacaoPlaqueta.verde,
        isProvavel: false,
        timestamp: t2,
      );
      expect(estavel, isFalse);
    });

    test('Suaviza posição da caixa e remove após 1.5s sem detecção', () {
      const caixa1 = RectDeteccao(left: 10, top: 10, width: 100, height: 50);
      const caixa2 = RectDeteccao(left: 20, top: 20, width: 100, height: 50);
      final t0 = DateTime(2026, 10, 27, 10, 0, 0, 0);
      final t1 = t0.add(const Duration(milliseconds: 200));

      filtro.registrarDeteccao(
        tombamento: '010001',
        caixa: caixa1,
        classificacao: ClassificacaoPlaqueta.verde,
        isProvavel: false,
        timestamp: t0,
      );
      filtro.registrarDeteccao(
        tombamento: '010001',
        caixa: caixa2,
        classificacao: ClassificacaoPlaqueta.verde,
        isProvavel: false,
        timestamp: t1,
      );

      final caixas = filtro.obterCaixasAtivas(timestamp: t1);
      expect(caixas.length, 1);
      // Suavização lerp 0.6: 10 + (20-10)*0.6 = 16
      expect(caixas.first.caixa.left, 16.0);

      // Após 1600 ms (> 1.5s), a caixa deve expirar e sumir
      final tExpirado = t1.add(const Duration(milliseconds: 1600));
      expect(filtro.obterCaixasAtivas(timestamp: tExpirado), isEmpty);
    });
  });
}
