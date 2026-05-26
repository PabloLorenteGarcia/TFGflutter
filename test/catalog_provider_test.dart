import 'package:flutter_test/flutter_test.dart';
import 'package:plantcare/core/constants/plant_catalog_data.dart';
import 'package:plantcare/data/repositories/catalog_repository.dart';
import 'package:plantcare/data/repositories/firebase_catalog_repository.dart';
import 'package:plantcare/domain/entities/catalog_plant.dart';
import 'package:plantcare/domain/entities/enums.dart';
import 'package:plantcare/presentation/providers/catalog_provider.dart';

class FakeFirebaseCatalogRepository extends FirebaseCatalogRepository {
  FakeFirebaseCatalogRepository({required this.remotePlants});

  final List<CatalogPlant> remotePlants;
  final List<CatalogPlant> addedPlants = [];

  @override
  Future<List<CatalogPlant>> getAllPlants() async => remotePlants;

  @override
  Future<void> addPlants(List<CatalogPlant> plants) async {
    addedPlants.addAll(plants);
    remotePlants.addAll(plants);
  }
}

class FakeCatalogRepository extends CatalogRepository {
  FakeCatalogRepository({required this.localPlants});

  final List<CatalogPlant> localPlants;

  @override
  Future<List<CatalogPlant>> getAllPlants() async => localPlants;
}

void main() {
  test('loadPlants uses the local catalog when Firestore is empty', () async {
    final fallbackPlant = CatalogPlant(
      id: 'fallback_001',
      name: 'Local fallback',
      scientificName: 'Local fallback',
      category: PlantCategory.indoor,
      description: 'Planta de respaldo local',
      lightRequirement: LightRequirement.low,
      wateringFrequency: WateringFrequency.weekly,
      wateringAmount: WateringAmount.low,
      minTemp: 18,
      maxTemp: 24,
      humidityLevel: HumidityLevel.medium,
      careTips: 'Usada como respaldo si Firestore no responde.',
    );

    final provider = CatalogProvider(
      repository: FakeFirebaseCatalogRepository(remotePlants: []),
      localRepository: FakeCatalogRepository(localPlants: [fallbackPlant]),
    );

    await provider.loadPlants();

    expect(provider.plants, isNotEmpty);
    expect(provider.plants.any((plant) => plant.id == fallbackPlant.id), isTrue);
    expect(provider.error, isNull);
  });

  test('loadPlants falls back to default plants when local data is unavailable', () async {
    final provider = CatalogProvider(
      repository: FakeFirebaseCatalogRepository(remotePlants: []),
      localRepository: FakeCatalogRepository(localPlants: []),
    );

    await provider.loadPlants();

    expect(provider.plants, isNotEmpty);
    expect(provider.plants.first.id, PlantCatalogData.getDefaultPlants().first.id);
  });
}
