import 'package:go_router/go_router.dart';
import '../../features/unidades/screens/unidades_screen.dart';
import '../../features/importacao/screens/importacao_screen.dart';
import '../../features/salas/screens/salas_screen.dart';
import '../../features/conferencia/screens/conferencia_screen.dart';
import '../../features/bem/screens/bem_screen.dart';
import '../../features/exportacao/screens/exportacao_screen.dart';
import '../../features/configuracoes/screens/configuracoes_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const UnidadesScreen(),
    ),
    GoRoute(
      path: '/importacao',
      builder: (context, state) => const ImportacaoScreen(),
    ),
    GoRoute(
      path: '/salas',
      builder: (context, state) => const SalasScreen(),
    ),
    GoRoute(
      path: '/conferencia/:salaId',
      builder: (context, state) {
        final salaId = state.pathParameters['salaId'] ?? 'sala-01';
        return ConferenciaScreen(salaId: salaId);
      },
    ),
    GoRoute(
      path: '/bem/:tombamento',
      builder: (context, state) {
        final tombamento = state.pathParameters['tombamento'] ?? '00000';
        return BemScreen(tombamento: tombamento);
      },
    ),
    GoRoute(
      path: '/exportacao',
      builder: (context, state) => const ExportacaoScreen(),
    ),
    GoRoute(
      path: '/configuracoes',
      builder: (context, state) => const ConfiguracoesScreen(),
    ),
  ],
);
