import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/bem/screens/bem_screen.dart';
import '../../features/bem/screens/bens_screen.dart';
import '../../features/conferencia/screens/conferencia_screen.dart';
import '../../features/configuracoes/screens/configuracoes_screen.dart';
import '../../features/divergencias/screens/divergencias_screen.dart';
import '../../features/exportacao/screens/exportacao_screen.dart';
import '../../features/homologacao/screens/homologacao_screen.dart';
import '../../features/importacao/screens/importacao_screen.dart';
import '../../features/inicio/screens/inicio_screen.dart';
import '../../features/mais/screens/mais_screen.dart';
import '../../features/membros/screens/membros_screen.dart';
import '../../features/salas/screens/fechamento_sala_screen.dart';
import '../../features/salas/screens/locais_screen.dart';
import '../../features/salas/screens/sala_detalhe_screen.dart';
import '../../features/sincronizacao/screens/sincronizacao_screen.dart';
import '../widgets/app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // Shell Principal com barra inferior de 5 posições e barra superior unificada
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(
          selectedIndex: navigationShell.currentIndex,
          child: navigationShell,
        );
      },
      branches: [
        // Ramo 0: Início (Painel)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const InicioScreen(),
            ),
          ],
        ),

        // Ramo 1: Locais (Árvore de Locais)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/locais',
              builder: (context, state) => const LocaisScreen(),
            ),
          ],
        ),

        // Ramo 2: Placeholder Conferir
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/conferir_nav',
              builder: (context, state) => const SizedBox.shrink(),
            ),
          ],
        ),

        // Ramo 3: Bens (Catálogo e Busca)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/bens',
              builder: (context, state) => const BensScreen(),
            ),
          ],
        ),

        // Ramo 4: Mais (Perfil, Dados e Configurações)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/mais',
              builder: (context, state) => const MaisScreen(),
            ),
          ],
        ),
      ],
    ),

    // Rotas de Tela Cheia (Empilhadas sobre o Shell)
    GoRoute(
      path: '/locais/:salaId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final salaId = state.pathParameters['salaId'] ?? '';
        return SalaDetalheScreen(salaId: salaId);
      },
    ),
    GoRoute(
      path: '/locais/:salaId/fechamento',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final salaId = state.pathParameters['salaId'] ?? '';
        return FechamentoSalaScreen(salaId: salaId);
      },
    ),
    GoRoute(
      path: '/conferencia/:salaId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final salaId = state.pathParameters['salaId'] ?? 'sem_sala';
        return ConferenciaScreen(salaId: salaId);
      },
    ),
    GoRoute(
      path: '/bem/:tombamento',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final tombamento = state.pathParameters['tombamento'] ?? '';
        return BemScreen(tombamento: tombamento);
      },
    ),
    GoRoute(
      path: '/bens/:tombamento',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final tombamento = state.pathParameters['tombamento'] ?? '';
        return BemScreen(tombamento: tombamento);
      },
    ),
    GoRoute(
      path: '/importacao',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ImportacaoScreen(),
    ),
    GoRoute(
      path: '/exportacao',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ExportacaoScreen(),
    ),
    GoRoute(
      path: '/configuracoes',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ConfiguracoesScreen(),
    ),
    GoRoute(
      path: '/sincronizacao',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SincronizacaoScreen(),
    ),
    GoRoute(
      path: '/divergencias',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DivergenciasScreen(),
    ),
    GoRoute(
      path: '/homologacao',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const HomologacaoScreen(),
    ),
    GoRoute(
      path: '/membros',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MembrosScreen(),
    ),
    // Redirecionamento de compatibilidade
    GoRoute(
      path: '/salas',
      redirect: (context, state) => '/locais',
    ),
  ],
);
