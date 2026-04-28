/// Constantes de la aplicación
class AppConstants {
  // Nombre de la aplicación
  static const String appName = 'PlantCare';
  static const String appVersion = '1.0.0';
  
  // Rutas de navegación
  static const String homeRoute = '/';
  static const String catalogRoute = '/catalog';
  static const String catalogDetailRoute = '/catalog/:id';
  static const String quizRoute = '/quiz';
  static const String quizResultRoute = '/quiz/result';
  static const String myPlantsRoute = '/my-plants';
  static const String plantDetailRoute = '/my-plants/:id';
  static const String addPlantRoute = '/my-plants/add';
  static const String editPlantRoute = '/my-plants/edit/:id';
  static const String settingsRoute = '/settings';
  
  // Tiempos de espera
  static const int defaultTimeout = 30000;
  static const int animationDuration = 300;
  
  // Valores por defecto
  static const double defaultMinTemp = 15.0;
  static const double defaultMaxTemp = 25.0;
  
  // Mensajes
  static const String noPlantsMessage = 'No tienes plantas registradas';
  static const String noPlantsDescription = 'Añade tu primera planta para comenzar a cuidarla';
  static const String noResultsMessage = 'No se encontraron resultados';
  static const String errorMessage = 'Ha ocurrido un error. Por favor, inténtalo de nuevo';
  
  // Nombres de tablas en la base de datos
  static const String plantsTable = 'plants';
  static const String catalogTable = 'catalog_plants';
}

/// Claves para argumentos de navegación
class NavArgs {
  static const String plantId = 'plantId';
  static const String catalogPlantId = 'catalogPlantId';
}