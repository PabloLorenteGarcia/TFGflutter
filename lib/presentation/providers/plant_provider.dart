import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:plantcare/data/repositories/firebase_catalog_repository.dart';
import 'package:plantcare/data/repositories/plant_repository.dart';
import 'package:plantcare/domain/entities/plant.dart';

/// Provider para gestionar el estado de las plantas del usuario
class PlantProvider extends ChangeNotifier {
  final FirebaseCatalogRepository _remoteRepository = FirebaseCatalogRepository();
  final PlantRepository _localRepository = PlantRepository();
  String? _userId;

  String? get _effectiveUserId =>
      _userId ?? FirebaseAuth.instance.currentUser?.uid;
  
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final Map<String, Plant> mergedPlants = {};
      final currentUserId = _effectiveUserId;

      if (currentUserId != null) {
        final localPlants = await _localRepository.getAllPlants(userId: currentUserId);
        final anonymousPlants = await _localRepository.getAllPlants(userId: null);

        for (final plant in [...localPlants, ...anonymousPlants]) {
          mergedPlants[plant.id] = plant;
        }

        _plants = mergedPlants.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();

        final remotePlants = await _remoteRepository.getUserPlants(currentUserId);
        for (final remotePlant in remotePlants) {
          final plantWithUserId = remotePlant.userId == _userId
              ? remotePlant
              : remotePlant.copyWith(userId: _userId);
          mergedPlants[plantWithUserId.id] = plantWithUserId;
          await _localRepository.addPlant(plantWithUserId);
        }

        for (final localPlant in [...localPlants, ...anonymousPlants]) {
          final existsRemotely = remotePlants.any((p) => p.id == localPlant.id);
          if (!existsRemotely) {
            final labeledPlant = localPlant.userId == currentUserId
                ? localPlant
                : localPlant.copyWith(userId: currentUserId);
            await _remoteRepository.addUserPlant(currentUserId, labeledPlant);
            if (localPlant.userId != currentUserId) {
              await _localRepository.updatePlant(labeledPlant);
              mergedPlants[labeledPlant.id] = labeledPlant;
            }
          }
        }
      } else {
        final localPlants = await _localRepository.getAllPlants(userId: null);
        for (final plant in localPlants) {
          mergedPlants[plant.id] = plant;
        }
      }

      _plants = mergedPlants.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _error = 'Error al cargar las plantas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Añade una nueva planta
  Future<void> addPlant(Plant plant) async {
    final currentUserId = _effectiveUserId;
    final plantToSave = currentUserId != null ? plant.copyWith(userId: currentUserId) : plant;

    try {
      await _localRepository.addPlant(plantToSave);
      _plants.insert(0, plantToSave);
      notifyListeners();
    } catch (e) {
      _error = 'Error al añadir la planta localmente: $e';
      notifyListeners();
      return;
    }

    if (currentUserId != null) {
      try {
        await _remoteRepository.addUserPlant(currentUserId, plantToSave);
      } catch (e) {
        _error = 'Planta guardada localmente, pero no se pudo sincronizar: $e';
        notifyListeners();
        rethrow;
      }
    }
  }

  /// Actualiza una planta existente
  Future<void> updatePlant(Plant plant) async {
    try {
      await _localRepository.updatePlant(plant);
      final currentUserId = _effectiveUserId;
      if (currentUserId != null) {
        await _remoteRepository.updateUserPlant(currentUserId, plant);
      }
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
    try {
      await _localRepository.deletePlant(id);
      final currentUserId = _effectiveUserId;
      if (currentUserId != null) {
        await _remoteRepository.deleteUserPlant(currentUserId, id);
      }
      _plants.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Error al eliminar la planta: $e';
      notifyListeners();
    }
  }

  /// Marca una planta como regada
  Future<void> markAsWatered(String id) async {
    try {
      final index = _plants.indexWhere((p) => p.id == id);
      if (index != -1) {
        final plant = _plants[index];
        final now = DateTime.now();
        final updatedPlant = plant.copyWith(
          lastWatered: now,
          nextWatering: plant.calculateNextWatering(),
        );
        await _localRepository.updatePlant(updatedPlant);
        final currentUserId = _effectiveUserId;
        if (currentUserId != null) {
          await _remoteRepository.updateUserPlant(currentUserId, updatedPlant);
        }
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