import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'brand_config.dart';

enum BrandPreset {
  padrao('assets/brand/brand.json', 'Padrão (TJPA)'),
  neutro('assets/brand/presets/neutro.json', 'Neutro (Sem Instituição)');

  final String assetPath;
  final String label;
  const BrandPreset(this.assetPath, this.label);
}

class BrandState {
  final BrandConfig config;
  final BrandPreset currentPreset;
  final bool isLoading;

  const BrandState({
    required this.config,
    required this.currentPreset,
    this.isLoading = false,
  });

  BrandState copyWith({
    BrandConfig? config,
    BrandPreset? currentPreset,
    bool? isLoading,
  }) {
    return BrandState(
      config: config ?? this.config,
      currentPreset: currentPreset ?? this.currentPreset,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class BrandNotifier extends Notifier<BrandState> {
  @override
  BrandState build() {
    Future.microtask(() => loadPreset(BrandPreset.padrao));
    return BrandState(
      config: BrandConfig.fallback(),
      currentPreset: BrandPreset.padrao,
      isLoading: false,
    );
  }

  Future<void> loadPreset(BrandPreset preset) async {
    state = state.copyWith(isLoading: true);
    try {
      final jsonString = await rootBundle.loadString(preset.assetPath);
      final newConfig = BrandConfig.fromJsonString(jsonString);
      state = state.copyWith(
        config: newConfig,
        currentPreset: preset,
        isLoading: false,
      );
    } catch (_) {
      // Se falhar o carregamento do arquivo, mantém o fallback seguro
      state = state.copyWith(
        config: BrandConfig.fallback(),
        currentPreset: preset,
        isLoading: false,
      );
    }
  }

  Future<void> setConfigDirectly(BrandConfig config, BrandPreset preset) async {
    state = state.copyWith(
      config: config,
      currentPreset: preset,
      isLoading: false,
    );
  }
}

final brandNotifierProvider =
    NotifierProvider<BrandNotifier, BrandState>(BrandNotifier.new);
