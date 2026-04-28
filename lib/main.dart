import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:plantcare/core/constants/firebase_options.dart';
import 'package:plantcare/core/theme/app_theme.dart';
import 'package:plantcare/core/utils/app_router.dart';
import 'package:plantcare/core/utils/notification_service.dart';
import 'package:plantcare/presentation/providers/auth_provider.dart';
import 'package:plantcare/presentation/providers/plant_provider.dart';
import 'package:plantcare/presentation/providers/catalog_provider.dart';
import 'package:plantcare/presentation/providers/quiz_provider.dart';
import 'package:plantcare/presentation/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Inicializar notificaciones
  await NotificationService().initialize();
  
  runApp(const PlantCareApp());
}

/// Widget principal de la aplicación
class PlantCareApp extends StatefulWidget {
  const PlantCareApp({super.key});

  @override
  State<PlantCareApp> createState() => _PlantCareAppState();
}

class _PlantCareAppState extends State<PlantCareApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = AppRouter.createRouter(_authProvider);
    
    // Sincronizar auth con plant provider
    _authProvider.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (_authProvider.isAuthenticated) {
      context.read<PlantProvider>().setUserId(_authProvider.userId);
    } else {
      context.read<PlantProvider>().setUserId(null);
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => PlantProvider()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()..loadPlants()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp.router(
            title: 'PlantCare',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}