import 'package:flutter/foundation.dart';
import 'package:plantcare/data/repositories/firebase_catalog_repository.dart';
import 'package:plantcare/core/constants/plant_catalog_data.dart';
import 'package:plantcare/domain/entities/catalog_plant.dart';
import 'package:plantcare/domain/entities/enums.dart';

/// Provider para gestionar el estado del catálogo de plantas
class CatalogProvider extends ChangeNotifier {
  final FirebaseCatalogRepository _repository = FirebaseCatalogRepository();
  
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

    try {
      _plants = await _repository.getAllPlants();
      
      // Si no hay plantas en Firestore, agregar las plantas iniciales
      if (_plants.isEmpty) {
        await _initializeDefaultPlants();
        _plants = await _repository.getAllPlants();
      }
      
      _filteredPlants = _plants;
    } catch (e) {
      _error = 'Error al cargar el catálogo: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inicializa las plantas por defecto en Firestore
  Future<void> _initializeDefaultPlants() async {
    try {
      final defaultPlants = PlantCatalogData.getDefaultPlants();
      await _repository.addPlants(defaultPlants);
    } catch (e) {
      _error = 'Error al inicializar plantas: $e';
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