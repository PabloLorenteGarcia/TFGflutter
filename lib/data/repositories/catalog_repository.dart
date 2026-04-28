import 'package:plantcare/data/datasources/database_helper.dart';
import 'package:plantcare/domain/entities/catalog_plant.dart';
import 'package:plantcare/domain/entities/enums.dart';

/// Repositorio para gestionar el catálogo de plantas
class CatalogRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Obtiene todas las plantas del catálogo
  Future<List<CatalogPlant>> getAllPlants() async {
    final maps = await _db.getAllCatalogPlants();
    return maps.map((map) => CatalogPlant.fromMap(map)).toList();
  }

  /// Obtiene plantas del catálogo por categoría
  Future<List<CatalogPlant>> getPlantsByCategory(PlantCategory category) async {
    final maps = await _db.getCatalogPlantsByCategory(category.index);
    return maps.map((map) => CatalogPlant.fromMap(map)).toList();
  }

  /// Busca plantas en el catálogo por nombre
  Future<List<CatalogPlant>> searchPlants(String query) async {
    final maps = await _db.searchCatalogPlants(query);
    return maps.map((map) => CatalogPlant.fromMap(map)).toList();
  }

  /// Obtiene una planta del catálogo por su ID
  Future<CatalogPlant?> getPlantById(String id) async {
    final map = await _db.getCatalogPlantById(id);
    return map != null ? CatalogPlant.fromMap(map) : null;
  }

  /// Busca plantas que coincidan con los criterios del quiz
  Future<List<CatalogPlant>> searchByCriteria({
    List<LightRequirement>? lightRequirements,
    List<WateringFrequency>? wateringFrequencies,
    List<HumidityLevel>? humidityLevels,
    List<PlantCategory>? categories,
  }) async {
    final maps = await _db.searchCatalogByCriteria(
      lightRequirements: lightRequirements?.map((e) => e.index).toList(),
      wateringFrequencies: wateringFrequencies?.map((e) => e.index).toList(),
      humidityLevels: humidityLevels?.map((e) => e.index).toList(),
      categories: categories?.map((e) => e.index).toList(),
    );
    return maps.map((map) => CatalogPlant.fromMap(map)).toList();
  }
}