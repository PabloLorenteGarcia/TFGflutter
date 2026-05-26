import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:plantcare/data/repositories/catalog_repository.dart';
import 'package:plantcare/domain/entities/catalog_plant.dart';
import 'package:plantcare/domain/entities/enums.dart';
import 'package:plantcare/presentation/providers/quiz_provider.dart';
import 'package:plantcare/presentation/screens/quiz/quiz_screen.dart';

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

CatalogPlant _createPlant({
  required String id,
  required String name,
  required PlantCategory category,
  required LightRequirement lightRequirement,
  required WateringFrequency wateringFrequency,
  required HumidityLevel humidityLevel,
  required WateringAmount wateringAmount,
}) {
  return CatalogPlant(
    id: id,
    name: name,
    scientificName: '$name scientific',
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
  testWidgets('al pulsar Ver resultados navega a la pantalla de resultados', (tester) async {
    final provider = QuizProvider(
      catalogRepository: FakeCatalogRepository([
        _createPlant(
          id: 'plant_1',
          name: 'Rosa',
          category: PlantCategory.flower,
          lightRequirement: LightRequirement.high,
          wateringFrequency: WateringFrequency.weekly,
          humidityLevel: HumidityLevel.medium,
          wateringAmount: WateringAmount.medium,
        ),
      ]),
    );

    final router = GoRouter(
      initialLocation: '/quiz',
      routes: [
        GoRoute(
          path: '/quiz',
          builder: (context, state) => ChangeNotifierProvider.value(
            value: provider,
            child: const QuizScreen(),
          ),
        ),
        GoRoute(
          path: '/quiz/result',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Resultados')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

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

    await tester.pump();
    await tester.tap(find.text('Ver resultados'));

    await tester.pumpAndSettle();

    expect(find.text('Resultados'), findsOneWidget);
  });
}
