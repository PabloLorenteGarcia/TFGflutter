import 'package:flutter/foundation.dart';
import 'package:plantcare/core/constants/plant_catalog_data.dart';
import 'package:plantcare/data/repositories/catalog_repository.dart';
import 'package:plantcare/data/repositories/firebase_catalog_repository.dart';
import 'package:plantcare/domain/entities/catalog_plant.dart';
import 'package:plantcare/domain/entities/enums.dart';

/// Provider para gestionar el estado del catálogo de plantas
class CatalogProvider extends ChangeNotifier {
  final FirebaseCatalogRepository _repository;
  final CatalogRepository _localRepository;

  CatalogProvider({
    FirebaseCatalogRepository? repository,
    CatalogRepository? localRepository,
  })  : _repository = repository ?? FirebaseCatalogRepository(),
        _localRepository = localRepository ?? CatalogRepository();

  List<CatalogPlant> _plants = [];
  List<CatalogPlant> _filteredPlants = [];
  PlantCategory? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  List<CatalogPlant> get plants => _filteredPlants.isEmpty && _searchQuery.isEmpty && _selectedCategory == null 
      ? _plants 
      : _filteredPlants;
  List<CatalogPlant> get allPlants => _plants;
  PlantCategory? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Carga todas las plantas del catálogo
  Future<void> loadPlants() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final defaultPlants = PlantCatalogData.getDefaultPlants();

    try {
      var remotePlants = await _repository.getAllPlants();

      if (remotePlants.isEmpty) {
        try {
          remotePlants = await _localRepository.getAllPlants();
        } catch (_) {
          remotePlants = [];
        }
      }

      if (remotePlants.isEmpty) {
        _plants = defaultPlants;
        try {
          await _repository.addPlants(defaultPlants);
        } catch (_) {
          // Se mantiene el fallback local por defecto si Firestore no responde.
        }
      } else {
        _plants = remotePlants;

        final existingIds = _plants.map((plant) => plant.id).toSet();
        final missingDefaultPlants = defaultPlants
            .where((plant) => !existingIds.contains(plant.id))
            .toList();

        if (missingDefaultPlants.isNotEmpty) {
          _plants = [..._plants, ...missingDefaultPlants];
          try {
            await _repository.addPlants(missingDefaultPlants);
          } catch (_) {
            // Si no se puede sincronizar con Firestore, se conserva el catálogo cargado.
          }
        }
      }

      _filteredPlants = _plants;
    } catch (e) {
      try {
        _plants = await _localRepository.getAllPlants();
      } catch (_) {
        _plants = defaultPlants;
      }

      if (_plants.isEmpty) {
        _plants = defaultPlants;
      }

      _filteredPlants = _plants;
      _error = 'Se cargó una copia local del catálogo por un problema con Firestore.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filtra plantas por categoría
  void filterByCategory(PlantCategory? category) {
    _selectedCategory = category;
    _applyFilters();
  }

  /// Busca plantas por nombre
  void search(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  /// Aplica los filtros actuales
  void _applyFilters() {
    if (_selectedCategory == null && _searchQuery.isEmpty) {
      _filteredPlants = _plants;
    } else {
      _filteredPlants = _plants.where((plant) {
        bool matchesCategory = _selectedCategory == null || plant.category == _selectedCategory;
        bool matchesSearch = _searchQuery.isEmpty || 
            plant.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            plant.scientificName.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    }
    notifyListeners();
  }

  /// Limpia los filtros
  void clearFilters() {
    _selectedCategory = null;
    _searchQuery = '';
    _filteredPlants = _plants;
    notifyListeners();
  }

  /// Obtiene una planta del catálogo por su ID
  CatalogPlant? getPlantById(String id) {
    try {
      return _plants.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Busca plantas que coincidan con los criterios del quiz
  Future<List<CatalogPlant>> searchByCriteria({
    List<LightRequirement>? lightRequirements,
    List<WateringFrequency>? wateringFrequencies,
    List<HumidityLevel>? humidityLevels,
    List<PlantCategory>? categories,
  }) async {
    return await _repository.searchByCriteria(
      lightRequirements: lightRequirements,
      wateringFrequencies: wateringFrequencies,
      humidityLevels: humidityLevels,
      categories: categories,
    );
  }

  /// Limpia el error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}