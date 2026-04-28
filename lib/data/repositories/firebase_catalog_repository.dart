import 'package:plantcare/core/constants/firebase_service.dart';
import 'package:plantcare/domain/entities/catalog_plant.dart';
import 'package:plantcare/domain/entities/enums.dart';
import 'package:plantcare/domain/entities/plant.dart';

/// Repositorio para gestionar el catálogo de plantas y las plantas del usuario usando Firebase Firestore
class FirebaseCatalogRepository {
  final FirebaseService _firebaseService = FirebaseService.instance;

  /// Obtiene todas las plantas del catálogo
  Future<List<CatalogPlant>> getAllPlants() async {
    return await _firebaseService.getAllPlants();
  }

  /// Obtiene plantas del catálogo por categoría
  Future<List<CatalogPlant>> getPlantsByCategory(PlantCategory category) async {
    return await _firebaseService.getPlantsByCategory(category);
  }

  /// Busca plantas en el catálogo por nombre
  Future<List<CatalogPlant>> searchPlants(String query) async {
    return await _firebaseService.searchPlants(query);
  }

  /// Obtiene una planta del catálogo por su ID
  Future<CatalogPlant?> getPlantById(String id) async {
    return await _firebaseService.getPlantById(id);
  }

  /// Agrega una planta al catálogo
  Future<void> addPlant(CatalogPlant plant) async {
    await _firebaseService.addPlant(plant);
  }

  /// Agrega múltiples plantas al catálogo
  Future<void> addPlants(List<CatalogPlant> plants) async {
    await _firebaseService.addPlants(plants);
  }

  /// Actualiza una planta del catálogo
  Future<void> updatePlant(CatalogPlant plant) async {
    await _firebaseService.updatePlant(plant);
  }

  /// Elimina una planta del catálogo
  Future<void> deletePlant(String id) async {
    await _firebaseService.deletePlant(id);
  }

  /// Busca plantas que coincidan con los criterios del quiz
  Future<List<CatalogPlant>> searchByCriteria({
    List<LightRequirement>? lightRequirements,
    List<WateringFrequency>? wateringFrequencies,
    List<HumidityLevel>? humidityLevels,
    List<PlantCategory>? categories,
  }) async {
    final allPlants = await _firebaseService.getAllPlants();
    return allPlants.where((plant) {
      bool matchesLight = lightRequirements == null || 
          lightRequirements.isEmpty || 
          lightRequirements.contains(plant.lightRequirement);
      bool matchesWater = wateringFrequencies == null || 
          wateringFrequencies.isEmpty || 
          wateringFrequencies.contains(plant.wateringFrequency);
      bool matchesHumidity = humidityLevels == null || 
          humidityLevels.isEmpty || 
          humidityLevels.contains(plant.humidityLevel);
      bool matchesCategory = categories == null || 
          categories.isEmpty || 
          categories.contains(plant.category);
      return matchesLight && matchesWater && matchesHumidity && matchesCategory;
    }).toList();
  }

  // ==================== PLANTAS DEL USUARIO ====================

  /// Obtiene todas las plantas de un usuario
  Future<List<Plant>> getUserPlants(String userId) async {
    return await _firebaseService.getUserPlants(userId);
  }

  /// Agrega una planta al usuario
  Future<void> addUserPlant(String userId, Plant plant) async {
    await _firebaseService.addUserPlant(userId, plant);
  }

  /// Actualiza una planta del usuario
  Future<void> updateUserPlant(String userId, Plant plant) async {
    await _firebaseService.updateUserPlant(userId, plant);
  }

  /// Elimina una planta del usuario
  Future<void> deleteUserPlant(String userId, String plantId) async {
    await _firebaseService.deleteUserPlant(userId, plantId);
  }

  /// Obtiene una planta específica del usuario
  Future<Plant?> getUserPlantById(String userId, String plantId) async {
    return await _firebaseService.getUserPlantById(userId, plantId);
  }
}