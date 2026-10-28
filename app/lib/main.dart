import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'brand/brand_provider.dart';
import 'brand/brand_theme.dart';
import 'core/routes/app_router.dart';
import 'data/importacao/importacao_service.dart';
import 'data/local/database_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: TomboxApp(),
    ),
  );
}

class TomboxApp extends ConsumerStatefulWidget {
  const TomboxApp({super.key});

  @override
  ConsumerState<TomboxApp> createState() => _TomboxAppState();
}

class _TomboxAppState extends ConsumerState<TomboxApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        final db = ref.read(databaseProvider);
        final unidades = await db.select(db.unidades).get();
        if (unidades.isEmpty) {
          await ref.read(importacaoProvider.notifier).importarDadosDemonstracao();
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final brandState = ref.watch(brandNotifierProvider);
    final brandConfig = brandState.config;
    final uriStr = Uri.base.toString();
    final isDarkFromUrl = uriStr.contains('dark=true') || uriStr.contains('tema=escuro');
    final themeMode = isDarkFromUrl ? ThemeMode.dark : ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: brandConfig.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: BrandTheme.buildLightTheme(brandConfig),
      darkTheme: BrandTheme.buildDarkTheme(brandConfig),
      themeMode: themeMode,
    );
  }
}
