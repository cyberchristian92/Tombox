/// Representa uma sugestão de categoria patrimonial emitida por inteligência visual
class SugestaoCategoria {
  final String categoria;
  final double confianca;
  final String rotuloOrigem;
  final bool isSimulacao;

  const SugestaoCategoria({
    required this.categoria,
    required this.confianca,
    required this.rotuloOrigem,
    this.isSimulacao = false,
  });
}

/// Mapeamento editável entre rótulos visuais (Image Labeling) e categorias oficiais do TJPA
class MapeamentoCategorias {
  static const Map<String, String> mapaRotulos = {
    // Informática
    'laptop': 'Informática',
    'computer': 'Informática',
    'computer monitor': 'Informática',
    'computer keyboard': 'Informática',
    'display': 'Informática',
    'screen': 'Informática',
    'mouse': 'Informática',
    'server': 'Informática',
    'electronic device': 'Informática',

    // Mobiliário
    'chair': 'Mobiliário em Geral',
    'office chair': 'Mobiliário em Geral',
    'desk': 'Mobiliário em Geral',
    'table': 'Mobiliário em Geral',
    'furniture': 'Mobiliário em Geral',
    'couch': 'Mobiliário em Geral',
    'drawer': 'Mobiliário em Geral',
    'cabinet': 'Mobiliário em Geral',
    'bookcase': 'Mobiliário em Geral',

    // Máquinas de Escritório
    'printer': 'Máquinas e Equipamentos de Escritório',
    'scanner': 'Máquinas e Equipamentos de Escritório',
    'photocopier': 'Máquinas e Equipamentos de Escritório',
    'paper shredder': 'Máquinas e Equipamentos de Escritório',

    // Climatização
    'air conditioner': 'Aparelhos de Climatização',
    'fan': 'Aparelhos de Climatização',
    'heater': 'Aparelhos de Climatização',

    // Áudio e Vídeo
    'television': 'Equipamentos de Áudio e Vídeo',
    'projector': 'Equipamentos de Áudio e Vídeo',
    'microphone': 'Equipamentos de Áudio e Vídeo',
    'loudspeaker': 'Equipamentos de Áudio e Vídeo',
    'camera': 'Equipamentos de Áudio e Vídeo',

    // Veículos
    'car': 'Veículos e Transporte',
    'vehicle': 'Veículos e Transporte',
    'motorcycle': 'Veículos e Transporte',
  };

  /// Sugere uma categoria oficial baseada na lista de rótulos detectados
  static SugestaoCategoria sugerir(List<Map<String, dynamic>> rotulosDetectados) {
    for (final item in rotulosDetectados) {
      final text = (item['text'] ?? '').toString().toLowerCase();
      final conf = (item['confidence'] as num?)?.toDouble() ?? 0.8;

      if (mapaRotulos.containsKey(text)) {
        return SugestaoCategoria(
          categoria: mapaRotulos[text]!,
          confianca: conf,
          rotuloOrigem: text,
        );
      }
    }

    // Fallback padrão
    return const SugestaoCategoria(
      categoria: 'Mobiliário em Geral',
      confianca: 0.70,
      rotuloOrigem: 'objeto geral',
    );
  }

  /// Retorna uma sugestão simulada explícita para o ambiente Web
  static SugestaoCategoria sugestaoSimuladaWeb() {
    return const SugestaoCategoria(
      categoria: 'Informática (simulação)',
      confianca: 0.95,
      rotuloOrigem: 'laptop (simulação)',
      isSimulacao: true,
    );
  }
}
