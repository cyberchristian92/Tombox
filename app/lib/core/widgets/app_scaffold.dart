import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../brand/brand_provider.dart';
import 'brand_logo.dart';

class AppScaffold extends ConsumerWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool? showLogo;

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showLogo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandState = ref.watch(brandNotifierProvider);
    final brand = brandState.config;
    final canPop = GoRouter.of(context).canPop();
    final displayLogo = showLogo ?? (title == null);

    return Scaffold(
      appBar: AppBar(
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Voltar',
                onPressed: () => context.pop(),
              )
            : null,
        title: displayLogo
            ? BrandLogo(brand: brand)
            : Text(title ?? brand.appName),
        actions: [
          ...?actions,
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurações',
            onPressed: () => context.push('/configuracoes'),
          ),
        ],
      ),
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
