import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:plantcare/presentation/providers/auth_provider.dart';
import 'package:plantcare/presentation/screens/home/home_screen.dart';
import 'package:plantcare/presentation/screens/catalog/catalog_screen.dart';
import 'package:plantcare/presentation/screens/catalog/catalog_detail_screen.dart';
import 'package:plantcare/presentation/screens/quiz/quiz_screen.dart';
import 'package:plantcare/presentation/screens/quiz/quiz_result_screen.dart';
import 'package:plantcare/presentation/screens/my_plants/my_plants_screen.dart';
import 'package:plantcare/presentation/screens/my_plants/plant_detail_screen.dart';
import 'package:plantcare/presentation/screens/my_plants/add_plant_screen.dart';
import 'package:plantcare/presentation/screens/my_plants/edit_plant_screen.dart';
import 'package:plantcare/presentation/screens/settings/settings_screen.dart';
import 'package:plantcare/presentation/widgets/main_scaffold.dart';
import 'package:plantcare/presentation/widgets/auth_screen.dart';

/// Configuración del router de la aplicación
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      debugLogDiagnostics: true,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isAuthRoute = state.uri.path == '/auth';
        
        // Si no está autenticado y no está en la ruta de auth, redirigir a auth
        if (!isAuthenticated && !isAuthRoute) {
          return '/auth';
        }
        
        // Si está autenticado y está en la ruta de auth, redirigir a home
        if (isAuthenticated && isAuthRoute) {
          return '/';
        }
        
        return null;
      },
      refreshListenable: GoRouterRefreshStream(authProvider.authStateChanges),
      routes: [
        // Ruta de autenticación (fuera del shell)
        GoRoute(
          path: '/auth',
          name: 'auth',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const AuthScreen(),
        ),
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) => MainScaffold(child: child),
          routes: [
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/catalog',
            name: 'catalog',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CatalogScreen(),
            ),
          ),
          GoRoute(
            path: '/quiz',
            name: 'quiz',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: QuizScreen(),
            ),
          ),
          GoRoute(
            path: '/my-plants',
            name: 'myPlants',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MyPlantsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
      // Rutas fuera del shell (sin bottom navigation)
      GoRoute(
        path: '/catalog/:id',
        name: 'catalogDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CatalogDetailScreen(plantId: id);
        },
      ),
      GoRoute(
        path: '/quiz/result',
        name: 'quizResult',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const QuizResultScreen(),
      ),
      GoRoute(
        path: '/my-plants/:id',
        name: 'plantDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PlantDetailScreen(plantId: id);
        },
      ),
      GoRoute(
        path: '/my-plants/add',
        name: 'addPlant',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final catalogPlantId = state.uri.queryParameters['fromCatalog'];
          return AddPlantScreen(catalogPlantId: catalogPlantId);
        },
      ),
      GoRoute(
        path: '/my-plants/edit/:id',
        name: 'editPlant',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EditPlantScreen(plantId: id);
        },
      ),
    ],
  );
}

/// Stream que convierte cambios de estado en un Stream<void> para GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}