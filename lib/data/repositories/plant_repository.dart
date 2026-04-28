import 'package:plantcare/data/datasources/database_helper.dart';
import 'package:plantcare/domain/entities/plant.dart';

/// Repositorio para gestionar las plantas del usuario
class PlantRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Inserta una nueva planta
  Future<void> addPlant(Plant plant) async {
    await _db.insertPlant(plant.toMap());
  }

  /// Obtiene todas las plantas del usuario
  Future<List<Plant>> getAllPlants() async {
    final maps = await _db.getAllPlants();
    return maps.map((map) => Plant.fromMap(map)).toList();
  }

  /// Obtiene una planta por su ID
  Future<Plant?> getPlantById(String id) async {
    final map = await _db.getPlantById(id);
    return map != null ? Plant.fromMap(map) : null;
  }

  /// Actualiza una planta existente
  Future<void> updatePlant(Plant plant) async {
    await _db.updatePlant(plant.toMap());
  }

  /// Elimina una planta
  Future<void> deletePlant(String id) async {
    await _db.deletePlant(id);
  }

  /// Marca una planta como regada
  Future<void> markAsWatered(String id) async {
    final plant = await getPlantById(id);
    if (plant != null) {
      final now = DateTime.now();
      final nextWatering = plant.calculateNextWatering();
      final updatedPlant = plant.copyWith(
        lastWatered: now,
        nextWatering: nextWatering,
      );
      await updatePlant(updatedPlant);
    }
  }

  /// Obtiene las plantas que necesitan riego
  Future<List<Plant>> getPlantsNeedingWater() async {
    final plants = await getAllPlants();
    return plants.where((p) => p.needsWatering).toList();
  }

  /// Obtiene las plantas con notificaciones habilitadas
  Future<List<Plant>> getPlantsWithNotifications() async {
    final plants = await getAllPlants();
    return plants.where((p) => p.notificationsEnabled).toList();
  }
}