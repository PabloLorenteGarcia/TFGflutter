import 'package:flutter_test/flutter_test.dart';
import 'package:plantcare/data/repositories/catalog_repository.dart';
import 'package:plantcare/domain/entities/catalog_plant.dart';
import 'package:plantcare/domain/entities/enums.dart';
import 'package:plantcare/presentation/providers/quiz_provider.dart';

class FakeCatalogRepository extends CatalogRepository {
  FakeCatalogRepository(this._plants);

  final List<CatalogPlant> _plants;

  @override
  Future<List<CatalogPlant>> searchByCriteria({
    List<LightRequirement>? lightRequirements,
    List<WateringFrequency>? wateringFrequencies,
    List<HumidityLevel>? humidityLevels,
    List<PlantCategory>? categories,
  }) async {
    return _plants;
  }

  @override
  Future<List<CatalogPlant>> getAllPlants() async => _plants;
}

class ThrowingCatalogRepository extends CatalogRepository {
  @override
  Future<List<CatalogPlant>> searchByCriteria({
    List<LightRequirement>? lightRequirements,
    List<WateringFrequency>? wateringFrequencies,
    List<HumidityLevel>? humidityLevels,
    List<PlantCategory>? categories,
  }) async {
    throw Exception('Fallo al consultar el catálogo');
  }

  @override
  Future<List<CatalogPlant>> getAllPlants() async {
    throw Exception('Fallo al cargar plantas');
  }
}

CatalogPlant _createPlant({
  required String id,
  required String name,
  required String scientificName,
  required PlantCategory category,
  required LightRequirement lightRequirement,
  required WateringFrequency wateringFrequency,
  required HumidityLevel humidityLevel,
  required WateringAmount wateringAmount,
}) {
  return CatalogPlant(
    id: id,
    name: name,
    scientificName: scientificName,
    category: category,
    description: 'Descripción de prueba',
    lightRequirement: lightRequirement,
    wateringFrequency: wateringFrequency,
    wateringAmount: wateringAmount,
    minTemp: 15,
    maxTemp: 30,
    humidityLevel: humidityLevel,
    careTips: 'Cuidados de prueba',
  );
}

void main() {
  test('suggestedPlant is the best match for the quiz answers', () async {
    final flowerPlant = _createPlant(
      id: 'flower_1',
      name: 'Rosa',
      scientificName: 'Rosa spp.',
      category: PlantCategory.flower,
      lightRequirement: LightRequirement.high,
      wateringFrequency: WateringFrequency.weekly,
      humidityLevel: HumidityLevel.medium,
      wateringAmount: WateringAmount.medium,
    );

    final treePlant = _createPlant(
      id: 'tree_1',
      name: 'Olivo',
      scientificName: 'Olea europaea',
      category: PlantCategory.tree,
      lightRequirement: LightRequirement.low,
      wateringFrequency: WateringFrequency.monthly,
      humidityLevel: HumidityLevel.low,
      wateringAmount: WateringAmount.low,
    );

    final provider = QuizProvider(
      catalogRepository: FakeCatalogRepository([flowerPlant, treePlant]),
    );

    provider.selectAnswer('high');
    provider.nextQuestion();
    provider.selectAnswer('weekly');
    provider.nextQuestion();
    provider.selectAnswer('medium');
    provider.nextQuestion();
    provider.selectAnswer('flower');
    provider.nextQuestion();
    provider.selectAnswer('medium');
    provider.nextQuestion();
    provider.selectAnswer('indoor');

    await provider.finishQuiz();

    expect(provider.suggestedPlant?.id, flowerPlant.id);
  });

  test('finishQuiz marca el quiz como completado incluso si falla el catálogo', () async {
    final provider = QuizProvider(
      catalogRepository: ThrowingCatalogRepository(),
    );

    provider.selectAnswer('high');
    provider.nextQuestion();
    provider.selectAnswer('weekly');
    provider.nextQuestion();
    provider.selectAnswer('medium');
    provider.nextQuestion();
    provider.selectAnswer('flower');
    provider.nextQuestion();
    provider.selectAnswer('medium');
    provider.nextQuestion();
    provider.selectAnswer('indoor');

    await provider.finishQuiz();

    expect(provider.isCompleted, isTrue);
    expect(provider.isLoading, isFalse);
    expect(provider.results, isNotEmpty);
    expect(provider.suggestedPlant, isNotNull);
  });
}
