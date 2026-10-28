import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import '../../data/local/app_database.dart';
import '../eventos/evento_service.dart';
import '../eventos/evento_v2.dart';

/// Resultado do processamento e compressão de uma foto de patrimônio
class ResultadoFoto {
  final String hash; // SHA-256 dos bytes da foto principal
  final int tamanhoBytes;
  final int largura;
  final int altura;
  final Uint8List bytesComprimidos;
  final Uint8List bytesMiniatura;

  const ResultadoFoto({
    required this.hash,
    required this.tamanhoBytes,
    required this.largura,
    required this.altura,
    required this.bytesComprimidos,
    required this.bytesMiniatura,
  });
}

/// Serviço de captura, compressão e armazenamento de fotos por conteúdo (SHA-256)
class FotoService {
  static const int ladoMaiorMaximo = 1024;
  static const int ladoMiniaturaMaximo = 160;
  static const int qualidadeCompressao = 50;

  // Cache em memória para Web e testes (armazenamento endereçado por conteúdo)
  static final Map<String, Uint8List> _storageFotos = {};
  static final Map<String, Uint8List> _storageMiniaturas = {};

  /// Processa bytes brutos de imagem: redimensiona para até 1024px,
  /// remove metadados EXIF (LGPD), comprime e gera miniatura de 160px.
  static ResultadoFoto processarBytes(Uint8List bytesOriginais) {
    // 1. Decodificar imagem
    final imagem = img.decodeImage(bytesOriginais);
    if (imagem == null) {
      throw Exception('Não foi possível decodificar os bytes da imagem');
    }

    // 2. Redimensionar para no máximo 1024px no lado maior
    img.Image fotoPrincipal = imagem;
    final int maiorLado = imagem.width > imagem.height ? imagem.width : imagem.height;
    if (maiorLado > ladoMaiorMaximo) {
      if (imagem.width >= imagem.height) {
        fotoPrincipal = img.copyResize(imagem, width: ladoMaiorMaximo);
      } else {
        fotoPrincipal = img.copyResize(imagem, height: ladoMaiorMaximo);
      }
    }

    // 3. Comprimir com qualidade 60 (descarta EXIF e localização automaticamente)
    // Usamos encodeJpg com qualidade 60 que oferece compatibilidade universal e alta taxa de compressão
    final bytesFoto = Uint8List.fromList(img.encodeJpg(fotoPrincipal, quality: qualidadeCompressao));

    // 4. Gerar miniatura de 160px no maior lado
    img.Image miniatura;
    if (fotoPrincipal.width >= fotoPrincipal.height) {
      miniatura = img.copyResize(fotoPrincipal, width: ladoMiniaturaMaximo);
    } else {
      miniatura = img.copyResize(fotoPrincipal, height: ladoMiniaturaMaximo);
    }
    final bytesMini = Uint8List.fromList(img.encodeJpg(miniatura, quality: 65));

    // 5. Calcular SHA-256 da imagem comprimida (endereçamento por conteúdo)
    final hashSha256 = sha256.convert(bytesFoto).toString();

    // 6. Armazenar em cache/storage por conteúdo (sem duplicar)
    if (!_storageFotos.containsKey(hashSha256)) {
      _storageFotos[hashSha256] = bytesFoto;
      _storageMiniaturas[hashSha256] = bytesMini;
    }

    return ResultadoFoto(
      hash: hashSha256,
      tamanhoBytes: bytesFoto.length,
      largura: fotoPrincipal.width,
      altura: fotoPrincipal.height,
      bytesComprimidos: bytesFoto,
      bytesMiniatura: bytesMini,
    );
  }

  /// Recupera os bytes de uma foto pelo seu hash SHA-256
  static Uint8List? obterFoto(String hash) {
    return _storageFotos[hash];
  }

  /// Recupera os bytes da miniatura pelo hash SHA-256
  static Uint8List? obterMiniatura(String hash) {
    return _storageMiniaturas[hash];
  }

  /// Verifica se uma foto já existe no armazenamento
  static bool existeFoto(String hash) {
    return _storageFotos.containsKey(hash);
  }

  /// Registra a foto no patrimônio gerando o evento imutável FOTO assinado
  static Future<ResultadoFoto> registrarFotoBem({
    required AppDatabase db,
    required String tombamento,
    required String localId,
    required String aparelhoId,
    required String conferente,
    required Uint8List bytesFoto,
    String? observacao,
  }) async {
    final resultado = processarBytes(bytesFoto);

    // Registra evento FOTO assinado com Ed25519
    await EventoService.registrar(
      db: db,
      tipo: TiposEvento.foto,
      localId: localId,
      aparelhoId: aparelhoId,
      conferente: conferente,
      tombamento: tombamento,
      hashFoto: resultado.hash,
      payload: {
        'tombamento': tombamento,
        'hash_foto': resultado.hash,
        'tamanho_bytes': resultado.tamanhoBytes,
        'largura': resultado.largura,
        'altura': resultado.altura,
        'observacao': ?observacao,
      },
    );

    return resultado;
  }

  /// Limpa dados de teste
  static void limparStorageParaTestes() {
    _storageFotos.clear();
    _storageMiniaturas.clear();
  }
}
