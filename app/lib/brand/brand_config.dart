import 'dart:convert';
import 'package:flutter/material.dart';

Color parseHexColor(String hexString, {Color fallback = const Color(0xFF0B3D6E)}) {
  try {
    final clean = hexString.replaceAll('#', '').trim();
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    } else if (clean.length == 8) {
      return Color(int.parse(clean, radix: 16));
    }
    return fallback;
  } catch (_) {
    return fallback;
  }
}

class BrandColors {
  final Color primaria;
  final Color secundaria;
  final Color fundo;
  final Color texto;

  const BrandColors({
    required this.primaria,
    required this.secundaria,
    required this.fundo,
    required this.texto,
  });

  factory BrandColors.fromJson(Map<String, dynamic> json) {
    return BrandColors(
      primaria: parseHexColor(json['primaria'] as String? ?? '#0B3D6E'),
      secundaria: parseHexColor(
        json['secundaria'] as String? ?? '#C9A227',
        fallback: const Color(0xFFC9A227),
      ),
      fundo: parseHexColor(
        json['fundo'] as String? ?? '#F7F8FA',
        fallback: const Color(0xFFF7F8FA),
      ),
      texto: parseHexColor(
        json['texto'] as String? ?? '#1A1A1A',
        fallback: const Color(0xFF1A1A1A),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'primaria': '#${primaria.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
    'secundaria': '#${secundaria.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
    'fundo': '#${fundo.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
    'texto': '#${texto.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
  };
}

class BrandConfig {
  final String appName;
  final String instituicao;
  final String siglaInstituicao;
  final String logo;
  final BrandColors cores;

  const BrandConfig({
    required this.appName,
    required this.instituicao,
    required this.siglaInstituicao,
    required this.logo,
    required this.cores,
  });

  factory BrandConfig.fromJson(Map<String, dynamic> json) {
    return BrandConfig(
      appName: json['appName'] as String? ?? 'Tombox',
      instituicao: json['instituicao'] as String? ?? '',
      siglaInstituicao: json['siglaInstituicao'] as String? ?? '',
      logo: json['logo'] as String? ?? 'assets/brand/logo.png',
      cores: BrandColors.fromJson(
        json['cores'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  factory BrandConfig.fromJsonString(String rawJson) {
    final Map<String, dynamic> data = jsonDecode(rawJson) as Map<String, dynamic>;
    return BrandConfig.fromJson(data);
  }

  factory BrandConfig.fallback() {
    return const BrandConfig(
      appName: 'Tombox',
      instituicao: '',
      siglaInstituicao: '',
      logo: 'assets/brand/logo.png',
      cores: BrandColors(
        primaria: Color(0xFF0B3D6E),
        secundaria: Color(0xFFC9A227),
        fundo: Color(0xFFF7F8FA),
        texto: Color(0xFF1A1A1A),
      ),
    );
  }

  String get displayName {
    if (siglaInstituicao.trim().isNotEmpty) {
      return '$appName • $siglaInstituicao';
    }
    return appName;
  }
}
