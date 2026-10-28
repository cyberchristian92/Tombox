import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tombox/domain/fotos/foto_service.dart';

void main() {
  setUp(() {
    FotoService.limparStorageParaTestes();
  });

  group('FotoService (Compressão e Armazenamento por Conteúdo)', () {
    test('Imagem grande (2000x1500) é redimensionada para até 1024 px e menos de 120 KB', () {
      // 1. Criar imagem grande de teste de 2000x1500 px
      final imagemGrande = img.Image(width: 2000, height: 1500);
      img.fill(imagemGrande, color: img.ColorRgb8(200, 200, 200));

      // Desenhar padrão complexo para ter dados reais
      for (int i = 0; i < 2000; i += 20) {
        img.drawLine(
          imagemGrande,
          x1: i,
          y1: 0,
          x2: 2000 - i,
          y2: 1500,
          color: img.ColorRgb8((i % 255), ((i * 2) % 255), 100),
        );
      }

      final bytesOriginais = Uint8List.fromList(img.encodeJpg(imagemGrande, quality: 95));
      expect(bytesOriginais.length, greaterThan(150000)); // Arquivo original bem maior

      // 2. Processar pelo FotoService
      final resultado = FotoService.processarBytes(bytesOriginais);

      // 3. Validações estritas
      expect(resultado.largura, lessThanOrEqualTo(FotoService.ladoMaiorMaximo));
      expect(resultado.altura, lessThanOrEqualTo(FotoService.ladoMaiorMaximo));
      expect(resultado.largura, equals(1024)); // Maior lado reduzido para 1024
      expect(resultado.altura, equals(768)); // Proporção 4:3 mantida exatamente

      // Tamanho menor que 120 KB
      expect(resultado.tamanhoBytes, lessThan(120 * 1024));

      // Miniatura com no máximo 160 px
      final imgMini = img.decodeImage(resultado.bytesMiniatura);
      expect(imgMini, isNotNull);
      expect(imgMini!.width, lessThanOrEqualTo(FotoService.ladoMiniaturaMaximo));
      expect(imgMini.height, lessThanOrEqualTo(FotoService.ladoMiniaturaMaximo));
      expect(imgMini.width, equals(160));

      // Hash SHA-256 válido (64 caracteres hexadecimais)
      expect(resultado.hash.length, equals(64));
    });

    test('Mesma foto processada duas vezes gera o mesmo SHA-256 e não é duplicada', () {
      final imgTeste = img.Image(width: 800, height: 600);
      img.fill(imgTeste, color: img.ColorRgb8(10, 50, 100));
      final bytes = Uint8List.fromList(img.encodeJpg(imgTeste, quality: 80));

      final res1 = FotoService.processarBytes(bytes);
      final res2 = FotoService.processarBytes(bytes);

      expect(res1.hash, equals(res2.hash));
      expect(res1.tamanhoBytes, equals(res2.tamanhoBytes));
      expect(FotoService.existeFoto(res1.hash), isTrue);

      // Verificação de conteúdo íntegro
      final recuperado = FotoService.obterFoto(res1.hash);
      expect(recuperado, isNotNull);
      expect(recuperado!.length, equals(res1.tamanhoBytes));
    });

    test('Imagem menor que 1024 px preserva dimensões originais sem upscale', () {
      final imgPequena = img.Image(width: 640, height: 480);
      img.fill(imgPequena, color: img.ColorRgb8(50, 120, 80));
      final bytes = Uint8List.fromList(img.encodeJpg(imgPequena, quality: 80));

      final res = FotoService.processarBytes(bytes);
      expect(res.largura, equals(640));
      expect(res.altura, equals(480));
    });
  });
}
