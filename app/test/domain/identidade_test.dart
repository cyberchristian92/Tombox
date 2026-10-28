import 'package:flutter_test/flutter_test.dart';
import 'package:tombox/domain/identidade/identidade_service.dart';

void main() {
  setUp(() {
    IdentidadeService.resetarInstanciaParaTestes();
  });

  group('IdentidadeService Ed25519', () {
    test('Gera par de chaves Ed25519 e assina mensagem com sucesso', () async {
      final identidade = await IdentidadeService.obterOuCriarIdentidade();
      expect(identidade.publicKeyHex, isNotEmpty);
      expect(identidade.publicKeyHex.length, equals(64)); // 32 bytes hex = 64 chars
      expect(identidade.impressaoCurta.startsWith('ED25-'), isTrue);

      const mensagem = 'tombamento:010001|sala:101|status:conferido';
      final assinaturaHex = await IdentidadeService.assinar(mensagem, keyPair: identidade.keyPair);
      expect(assinaturaHex, isNotEmpty);
      expect(assinaturaHex.length, equals(128)); // 64 bytes Ed25519 sig = 128 chars hex

      final ehValida = await IdentidadeService.verificarAssinatura(
        mensagem: mensagem,
        assinaturaHex: assinaturaHex,
        publicKeyHex: identidade.publicKeyHex,
      );
      expect(ehValida, isTrue);
    });

    test('Rejeita assinatura com mensagem adulterada', () async {
      final identidade = await IdentidadeService.obterOuCriarIdentidade();
      const mensagemOriginal = 'evento:conferencia_sala_101';
      final assinatura = await IdentidadeService.assinar(mensagemOriginal, keyPair: identidade.keyPair);

      const mensagemAdulterada = 'evento:conferencia_sala_999';
      final ehValida = await IdentidadeService.verificarAssinatura(
        mensagem: mensagemAdulterada,
        assinaturaHex: assinatura,
        publicKeyHex: identidade.publicKeyHex,
      );
      expect(ehValida, isFalse);
    });

    test('Rejeita assinatura com chave pública incorreta', () async {
      final identidade1 = await IdentidadeService.obterOuCriarIdentidade();
      const mensagem = 'dados_de_auditoria';
      final assinatura = await IdentidadeService.assinar(mensagem, keyPair: identidade1.keyPair);

      // Cria um segundo par de chaves diferente
      final outroPar = await IdentidadeService.algorithm.newKeyPair();
      final outraPubKey = await outroPar.extractPublicKey();
      final outraPubKeyHex = IdentidadeService.bytesParaHex(outraPubKey.bytes);

      final ehValida = await IdentidadeService.verificarAssinatura(
        mensagem: mensagem,
        assinaturaHex: assinatura,
        publicKeyHex: outraPubKeyHex,
      );
      expect(ehValida, isFalse);
    });

    test('Gera impressão digital curta consistente', () {
      final bytes = List<int>.generate(32, (i) => i);
      final impressao1 = IdentidadeService.gerarImpressaoCurta(bytes);
      final impressao2 = IdentidadeService.gerarImpressaoCurta(bytes);
      expect(impressao1, equals(impressao2));
      expect(impressao1.length, equals(14)); // ED25-XXXX-YYYY = 14 chars
    });
  });
}
