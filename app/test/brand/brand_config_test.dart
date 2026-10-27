import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tombox/brand/brand_config.dart';
import 'package:tombox/brand/brand_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BrandConfig e Marca Trocável', () {
    test('Carrega e faz parse correto do brand.json (TJPA)', () {
      const rawJson = '''
      {
        "appName": "Tombox",
        "instituicao": "Tribunal de Justiça do Estado do Pará",
        "siglaInstituicao": "TJPA",
        "logo": "assets/brand/logo.png",
        "cores": {
          "primaria": "#0B3D6E",
          "secundaria": "#C9A227",
          "fundo": "#F7F8FA",
          "texto": "#1A1A1A"
        }
      }
      ''';

      final config = BrandConfig.fromJson(
        jsonDecode(rawJson) as Map<String, dynamic>,
      );

      expect(config.appName, 'Tombox');
      expect(config.siglaInstituicao, 'TJPA');
      expect(config.instituicao, 'Tribunal de Justiça do Estado do Pará');
      expect(config.cores.primaria, const Color(0xFF0B3D6E));
      expect(config.cores.secundaria, const Color(0xFFC9A227));
      expect(config.displayName, 'Tombox • TJPA');
    });

    test('Carrega e faz parse correto do preset neutro (sem instituição)', () {
      const rawNeutroJson = '''
      {
        "appName": "Tombox",
        "instituicao": "",
        "siglaInstituicao": "",
        "logo": "assets/brand/logo.png",
        "cores": {
          "primaria": "#1E3A8A",
          "secundaria": "#3B82F6",
          "fundo": "#F8FAFC",
          "texto": "#0F172A"
        }
      }
      ''';

      final config = BrandConfig.fromJson(
        jsonDecode(rawNeutroJson) as Map<String, dynamic>,
      );

      expect(config.appName, 'Tombox');
      expect(config.siglaInstituicao, '');
      expect(config.instituicao, '');
      expect(config.cores.primaria, const Color(0xFF1E3A8A));
      expect(config.cores.secundaria, const Color(0xFF3B82F6));
      expect(config.displayName, 'Tombox');
    });

    test('Fallback seguro quando JSON for vazio ou incompleto', () {
      final config = BrandConfig.fromJson(const {});
      expect(config.appName, 'Tombox');
      expect(config.cores.primaria, const Color(0xFF0B3D6E));
    });

    test('BrandTheme gera temas claro e escuro respeitando acessibilidade (48 dp)', () {
      const config = BrandConfig(
        appName: 'Tombox',
        instituicao: 'TJPA',
        siglaInstituicao: 'TJPA',
        logo: 'assets/brand/logo.png',
        cores: BrandColors(
          primaria: Color(0xFF0B3D6E),
          secundaria: Color(0xFFC9A227),
          fundo: Color(0xFFF7F8FA),
          texto: Color(0xFF1A1A1A),
        ),
      );

      final lightTheme = BrandTheme.buildLightTheme(config);
      final darkTheme = BrandTheme.buildDarkTheme(config);

      expect(lightTheme.useMaterial3, isTrue);
      expect(darkTheme.useMaterial3, isTrue);
      expect(lightTheme.colorScheme.primary, const Color(0xFF0B3D6E));

      // Verifica acessibilidade de alvo de toque mínimo de 48 dp
      final elevatedButtonStyle = lightTheme.elevatedButtonTheme.style;
      final minSize = elevatedButtonStyle?.minimumSize?.resolve({});
      expect(minSize?.height, greaterThanOrEqualTo(48.0));
      expect(minSize?.width, greaterThanOrEqualTo(48.0));
    });
  });
}
