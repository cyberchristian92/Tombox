import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Representa a identidade criptográfica Ed25519 de um aparelho no Tombox
class IdentidadeAparelho {
  final String publicKeyHex;
  final String impressaoCurta;
  final SimpleKeyPair? keyPair;

  const IdentidadeAparelho({
    required this.publicKeyHex,
    required this.impressaoCurta,
    this.keyPair,
  });
}

/// Serviço responsável por gerar, armazenar com segurança e assinar
/// eventos usando pares de chaves Ed25519 por aparelho.
class IdentidadeService {
  static final _ed25519 = Ed25519();
  static const _storage = FlutterSecureStorage();
  static const _storageKeyPrivateKey = 'tombox_ed25519_private_key_v2';
  static const _storageKeyPublicKey = 'tombox_ed25519_public_key_v2';

  static IdentidadeAparelho? _instanciaLocal;

  /// Retorna o algoritmo Ed25519
  static Ed25519 get algorithm => _ed25519;

  /// Converte bytes para string hexadecimal
  static String bytesParaHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Converte string hexadecimal para lista de bytes
  static List<int> hexParaBytes(String hex) {
    final limpo = hex.replaceAll(' ', '').replaceAll(':', '');
    final bytes = <int>[];
    for (int i = 0; i < limpo.length; i += 2) {
      final chunk = limpo.substring(i, i + 2);
      bytes.add(int.parse(chunk, radix: 16));
    }
    return bytes;
  }

  /// Gera a impressão digital curta amigável (8 a 12 chars) a partir da chave pública
  /// Exemplo: "ED25-7F2A-9C4B"
  static String gerarImpressaoCurta(List<int> publicKeyBytes) {
    // SHA-256 da chave pública para impressão digital uniforme
    final digest = crypto.sha256.convert(publicKeyBytes).bytes;
    final b1 = digest[0].toRadixString(16).padLeft(2, '0').toUpperCase();
    final b2 = digest[1].toRadixString(16).padLeft(2, '0').toUpperCase();
    final b3 = digest[2].toRadixString(16).padLeft(2, '0').toUpperCase();
    final b4 = digest[3].toRadixString(16).padLeft(2, '0').toUpperCase();
    return 'ED25-$b1$b2-$b3$b4';
  }

  /// Inicializa ou recupera a identidade local do aparelho.
  /// Se não existir, gera um novo par Ed25519 e persiste a chave privada.
  static Future<IdentidadeAparelho> obterOuCriarIdentidade({
    FlutterSecureStorage? customStorage,
  }) async {
    if (_instanciaLocal != null) {
      return _instanciaLocal!;
    }

    final storage = customStorage ?? _storage;
    String? privHex;
    try {
      privHex = await storage.read(key: _storageKeyPrivateKey);
    } catch (_) {
      privHex = null;
    }

    SimpleKeyPair keyPair;
    if (privHex != null && privHex.isNotEmpty) {
      final seedOrPriv = hexParaBytes(privHex);
      keyPair = await _ed25519.newKeyPairFromSeed(seedOrPriv.sublist(0, 32));
    } else {
      keyPair = await _ed25519.newKeyPair();
      final privKeyData = await keyPair.extractPrivateKeyBytes();
      final privKeyHex = bytesParaHex(privKeyData);
      try {
        await storage.write(key: _storageKeyPrivateKey, value: privKeyHex);
      } catch (_) {}
    }

    final pubKey = await keyPair.extractPublicKey();
    final pubKeyHex = bytesParaHex(pubKey.bytes);
    final impressao = gerarImpressaoCurta(pubKey.bytes);

    try {
      await storage.write(key: _storageKeyPublicKey, value: pubKeyHex);
    } catch (_) {}

    _instanciaLocal = IdentidadeAparelho(
      publicKeyHex: pubKeyHex,
      impressaoCurta: impressao,
      keyPair: keyPair,
    );

    return _instanciaLocal!;
  }

  /// Assina uma mensagem (string ou hash) usando o par de chaves local do aparelho
  static Future<String> assinar(String mensagem, {SimpleKeyPair? keyPair}) async {
    final par = keyPair ?? (await obterOuCriarIdentidade()).keyPair!;
    final dados = utf8.encode(mensagem);
    final signature = await _ed25519.sign(dados, keyPair: par);
    return bytesParaHex(signature.bytes);
  }

  /// Verifica se a assinatura Ed25519 é válida para o dado e a chave pública fornecidos
  static Future<bool> verificarAssinatura({
    required String mensagem,
    required String assinaturaHex,
    required String publicKeyHex,
  }) async {
    try {
      final mensagemBytes = utf8.encode(mensagem);
      final assinaturaBytes = hexParaBytes(assinaturaHex);
      final pubKeyBytes = hexParaBytes(publicKeyHex);

      final signature = Signature(
        assinaturaBytes,
        publicKey: SimplePublicKey(pubKeyBytes, type: KeyPairType.ed25519),
      );

      return await _ed25519.verify(mensagemBytes, signature: signature);
    } catch (_) {
      return false;
    }
  }

  /// Reseta a instância em memória (útil para testes unitários)
  static void resetarInstanciaParaTestes() {
    _instanciaLocal = null;
  }
}
