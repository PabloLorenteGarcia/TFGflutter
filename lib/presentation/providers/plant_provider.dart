import 'package:flutter/foundation.dart';
import 'package:plantcare/data/repositories/firebase_catalog_repository.dart';
import 'package:plantcare/domain/entities/plant.dart';

/// Provider para gestionar el estado de las plantas del usuario
class PlantProvider extends ChangeNotifier {
  final FirebaseCatalogRepository _repository = FirebaseCatalogRepository();
  String? _userId;
  
  List<Plant> _plants = [];
  bool _isLoading = false;
  String? _error;

  List<Plant> get plants => _plants;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Plantas que necesitan riego
  List<Plant> get plantsNeedingWater => 
      _plants.where((p) => p.needsWatering).toList();

  /// Total de plantas
  int get totalPlants => _plants.length;

  /// Establece el usuario actual y carga sus plantas
  void setUserId(String? userId) {
    _userId = userId;
    if (userId != null) {
      loadPlants();
    } else {
      _plants = [];
      notifyListeners();
    }
  }

  /// Carga todas las plantas desde la base de datos
  Future<void> loadPlants() async {
    if (_userId == null) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _plants = await _repository.getUserPlants(_userId!);
    } catch (e) {
      _error = 'Error al cargar las plantas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Añade una nueva planta
  Future<void> addPlant(Plant plant) async {
    if (_userId == null) return;
    
    try {
      await _repository.addUserPlant(_userId!, plant);
      _plants.insert(0, plant);
      notifyListeners();
    } catch (e) {
      _error = 'Error al añadir la planta: $e';
      notifyListeners();
    }
  }

  /// Actualiza una planta existente
  Future<void> updatePlant(Plant plant) async {
    if (_userId == null) return;
    
    try {
      await _repository.updateUserPlant(_userId!, plant);
      final index = _plants.indexWhere((p) => p.id == plant.id);
      if (index != -1) {
        _plants[index] = plant;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error al actualizar la planta: $e';
      notifyListeners();
    }
  }

  /// Elimina una planta
  Future<void> deletePlant(String id) async {
    if (_userId == null) return;
    
    try {
      await _repository.deleteUserPlant(_userId!, id);
      _plants.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Error al eliminar la planta: $e';
      notifyListeners();
    }
  }

  /// Marca una planta como regada
  Future<void> markAsWatered(String id) async {
    if (_userId == null) return;
    
    try {
      final index = _plants.indexWhere((p) => p.id == id);
      if (index != -1) {
        final plant = _plants[index];
        final now = DateTime.now();
        final updatedPlant = plant.copyWith(
          lastWatered: now,
          nextWatering: plant.calculateNextWatering(),
        );
        await _repository.updateUserPlant(_userId!, updatedPlant);
        _plants[index] = updatedPlant;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error al marcar como regada: $e';
      notifyListeners();
    }
  }

  /// Obtiene una planta por su ID
  Plant? getPlantById(String id) {
    try {
      return _plants.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Limpia el error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}