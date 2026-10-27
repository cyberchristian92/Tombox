import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'brand/brand_provider.dart';
import 'brand/brand_theme.dart';
import 'core/routes/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: TomboxApp(),
    ),
  );
}

class TomboxApp extends ConsumerWidget {
  const TomboxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandState = ref.watch(brandNotifierProvider);
    final brandConfig = brandState.config;

    return MaterialApp.router(
      title: brandConfig.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: BrandTheme.buildLightTheme(brandConfig),
      darkTheme: BrandTheme.buildDarkTheme(brandConfig),
      themeMode: ThemeMode.system,
    );
  }
}
