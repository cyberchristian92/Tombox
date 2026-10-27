import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../brand/brand_provider.dart';
import '../../../core/widgets/app_scaffold.dart';

class ConfiguracoesScreen extends ConsumerWidget {
  const ConfiguracoesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brandState = ref.watch(brandNotifierProvider);
    final currentPreset = brandState.currentPreset;

    return AppScaffold(
      title: 'Configurações',
      showLogo: false,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Seção: Conferente
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dados do Conferente',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Nome do Conferente',
                      hintText: 'Ex: Rosilene Silva',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Matrícula',
                      hintText: 'Ex: 92837',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Seção: Identificação do Dispositivo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dispositivo Local',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Identificador Único (Aparelho ID):'),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const SelectableText(
                      'dev-8f3a9c2b-e14d-4b92-971c-4b53ef12039a',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Utilizado para assinar e encadear os eventos no modelo offline-first.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Seção: Marca Ativa (Desacoplamento de Marca)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.palette_outlined),
                      const SizedBox(width: 8),
                      Text(
                        'Identidade Visual Trocável',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Permite alternar a identidade visual do app instantaneamente, comprovando o isolamento completo da marca.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  RadioGroup<BrandPreset>(
                    groupValue: currentPreset,
                    onChanged: (newPreset) {
                      if (newPreset != null) {
                        ref
                            .read(brandNotifierProvider.notifier)
                            .loadPreset(newPreset);
                      }
                    },
                    child: Column(
                      children: BrandPreset.values.map((preset) {
                        return RadioListTile<BrandPreset>(
                          title: Text(preset.label),
                          subtitle: Text(preset.assetPath),
                          value: preset,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Seção: Informações da Aplicação
          Center(
            child: Column(
              children: [
                Text(
                  'Tombox v1.0.0+1 (Etapa 0)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Licença Apache-2.0 • Funcionamento 100% Offline',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
