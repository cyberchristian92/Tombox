import '../identidade/identidade_service.dart';
import '../membros/membro_models.dart';
import '../membros/membro_service.dart';
import 'evento_v2.dart';

/// Motivos de rejeição de um evento
enum MotivoRejeicao {
  hashInvalido,
  assinaturaInvalida,
  seqDescontinuo,
  hashAnteriorInvalido,
  autorRevogado,
  papelNaoAutorizado,
  formatoInvalido,
}

/// Resultado detalhado da validação criptográfica e causal de um evento
class ResultadoValidacao {
  final bool valido;
  final MotivoRejeicao? motivo;
  final String? mensagem;

  const ResultadoValidacao._({
    required this.valido,
    this.motivo,
    this.mensagem,
  });

  factory ResultadoValidacao.sucesso() =>
      const ResultadoValidacao._(valido: true);

  factory ResultadoValidacao.falha(MotivoRejeicao motivo, String mensagem) =>
      ResultadoValidacao._(
        valido: false,
        motivo: motivo,
        mensagem: mensagem,
      );
}

/// Validador estrito de eventos recebidos ou lidos do armazenamento
class EventoValidador {
  /// Valida todas as regras de integridade de um EventoV2
  static Future<ResultadoValidacao> validar({
    required EventoV2 evento,
    EventoV2? ultimoEventoDoAutor,
    Set<String>? autoresRevogados,
    PapelUsuario? papelDoAutor,
  }) async {
    // 1. Verificar se o autor foi revogado
    if (autoresRevogados != null && autoresRevogados.contains(evento.autor)) {
      return ResultadoValidacao.falha(
        MotivoRejeicao.autorRevogado,
        'O autor ${evento.autor.substring(0, 8)}... foi revogado da unidade.',
      );
    }

    // 1b. Verificar se o papel do autor autoriza o tipo de evento
    if (papelDoAutor != null && !MembroService.verificarPermissao(papelDoAutor, evento.tipo)) {
      return ResultadoValidacao.falha(
        MotivoRejeicao.papelNaoAutorizado,
        'O papel ${papelDoAutor.rotulo} não possui autorização para emitir evento do tipo ${evento.tipo}.',
      );
    }

    // 2. Verificar integridade do Hash SHA-256 do JSON canônico
    final hashRecalculado = EventoV2.calcularHash(
      id: evento.id,
      unidadeId: evento.unidadeId,
      tipo: evento.tipo,
      autor: evento.autor,
      seq: evento.seq,
      hashAnterior: evento.hashAnterior,
      conhecidos: evento.conhecidos,
      timestamp: evento.timestamp,
      payload: evento.payload,
    );

    if (hashRecalculado != evento.hash) {
      return ResultadoValidacao.falha(
        MotivoRejeicao.hashInvalido,
        'Hash corrompido ou adulterado. Esperado: $hashRecalculado, recebido: ${evento.hash}',
      );
    }

    // 3. Verificar assinatura Ed25519
    final assinaturaValida = await IdentidadeService.verificarAssinatura(
      mensagem: evento.hash,
      assinaturaHex: evento.assinatura,
      publicKeyHex: evento.autor,
    );

    if (!assinaturaValida) {
      return ResultadoValidacao.falha(
        MotivoRejeicao.assinaturaInvalida,
        'Assinatura Ed25519 inválida ou chave pública inconsistente.',
      );
    }

    // 4. Verificar continuidade causal do autor (seq e hashAnterior)
    if (ultimoEventoDoAutor != null) {
      if (evento.seq != ultimoEventoDoAutor.seq + 1) {
        return ResultadoValidacao.falha(
          MotivoRejeicao.seqDescontinuo,
          'Sequência desrespeitada para o autor. Anterior: ${ultimoEventoDoAutor.seq}, atual: ${evento.seq}',
        );
      }

      if (evento.hashAnterior != ultimoEventoDoAutor.hash) {
        return ResultadoValidacao.falha(
          MotivoRejeicao.hashAnteriorInvalido,
          'Cadeia de hash rompida. Esperado hash_anterior: ${ultimoEventoDoAutor.hash}, recebido: ${evento.hashAnterior}',
        );
      }
    } else {
      // Primeiro evento do autor deve ter seq = 1 e hashAnterior = zeros
      if (evento.seq != 1) {
        return ResultadoValidacao.falha(
          MotivoRejeicao.seqDescontinuo,
          'Primeiro evento do autor deve possuir seq = 1. Recebido: ${evento.seq}',
        );
      }
      if (evento.hashAnterior != EventoV2.hashInicial) {
        return ResultadoValidacao.falha(
          MotivoRejeicao.hashAnteriorInvalido,
          'Primeiro evento do autor deve apontar para o hashInicial com zeros.',
        );
      }
    }

    return ResultadoValidacao.sucesso();
  }
}
