import 'package:plantcare/domain/entities/enums.dart';
import 'package:plantcare/domain/entities/catalog_plant.dart';

/// Representa una pregunta en el quiz de identificación
class QuizQuestion {
  final String id;
  final String question;
  final List<QuizOption> options;
  final String? imageUrl;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    this.imageUrl,
  });
}

/// Opción de respuesta para una pregunta del quiz
class QuizOption {
  final String id;
  final String text;
  final List<LightRequirement>? matchingLight;
  final List<WateringFrequency>? matchingWatering;
  final List<HumidityLevel>? matchingHumidity;
  final List<PlantCategory>? matchingCategory;

  const QuizOption({
    required this.id,
    required this.text,
    this.matchingLight,
    this.matchingWatering,
    this.matchingHumidity,
    this.matchingCategory,
  });
}

/// Resultado del quiz de identificación
class QuizResult {
  final List<CatalogPlant> matchingPlants;
  final Map<String, int> matchedCriteria;

  const QuizResult({
    required this.matchingPlants,
    required this.matchedCriteria,
  });
}

/// Preguntas predefinidas para el quiz
class QuizData {
  static const List<QuizQuestion> questions = [
    QuizQuestion(
      id: 'light',
      question: '¿Qué nivel de luz tiene el lugar donde está la planta?',
      options: [
        QuizOption(
          id: 'low',
          text: 'Sombra / Poca luz',
          matchingLight: [LightRequirement.low],
        ),
        QuizOption(
          id: 'medium',
          text: 'Luz indirecta brillante',
          matchingLight: [LightRequirement.medium],
        ),
        QuizOption(
          id: 'high',
          text: 'Mucha luz pero sin sol directo',
          matchingLight: [LightRequirement.high],
        ),
        QuizOption(
          id: 'direct',
          text: 'Sol directo varias horas',
          matchingLight: [LightRequirement.direct],
        ),
      ],
    ),
    QuizQuestion(
      id: 'watering',
      question: '¿Con qué frecuencia sueles regar la planta?',
      options: [
        QuizOption(
          id: 'daily',
          text: 'Diario',
          matchingWatering: [WateringFrequency.daily],
        ),
        QuizOption(
          id: 'every_two_days',
          text: 'Cada 2-3 días',
          matchingWatering: [WateringFrequency.everyTwoDays],
        ),
        QuizOption(
          id: 'weekly',
          text: 'Una vez por semana',
          matchingWatering: [WateringFrequency.weekly],
        ),
        QuizOption(
          id: 'biweekly',
          text: 'Cada dos semanas',
          matchingWatering: [WateringFrequency.biweekly],
        ),
        QuizOption(
          id: 'monthly',
          text: 'Una vez al mes o menos',
          matchingWatering: [WateringFrequency.monthly],
        ),
      ],
    ),
    QuizQuestion(
      id: 'humidity',
      question: '¿El ambiente donde está la planta es?',
      options: [
        QuizOption(
          id: 'low',
          text: 'Seco (aire acondicionado / calefacción)',
          matchingHumidity: [HumidityLevel.low],
        ),
        QuizOption(
          id: 'medium',
          text: 'Normal / Moderado',
          matchingHumidity: [HumidityLevel.medium],
        ),
        QuizOption(
          id: 'high',
          text: 'Húmedo (baño / cocina)',
          matchingHumidity: [HumidityLevel.high],
        ),
      ],
    ),
    QuizQuestion(
      id: 'type',
      question: '¿Qué tipo de planta es?',
      options: [
        QuizOption(
          id: 'succulent',
          text: 'Suculenta / Cactus',
          matchingCategory: [PlantCategory.succulent, PlantCategory.cactus],
        ),
        QuizOption(
          id: 'flower',
          text: 'Planta con flores',
          matchingCategory: [PlantCategory.flower],
        ),
        QuizOption(
          id: 'herb',
          text: 'Hierba / Aromática',
          matchingCategory: [PlantCategory.herb],
        ),
        QuizOption(
          id: 'tree',
          text: 'Árbol / Arbusto',
          matchingCategory: [PlantCategory.tree],
        ),
        QuizOption(
          id: 'foliage',
          text: 'Planta de hoja (interior)',
          matchingCategory: [PlantCategory.indoor],
        ),
      ],
    ),
    QuizQuestion(
      id: 'size',
      question: '¿Qué tamaño tiene la planta?',
      options: [
        QuizOption(
          id: 'small',
          text: 'Pequeña (menos de 30cm)',
        ),
        QuizOption(
          id: 'medium',
          text: 'Mediana (30cm - 1m)',
        ),
        QuizOption(
          id: 'large',
          text: 'Grande (más de 1m)',
        ),
      ],
    ),
    QuizQuestion(
      id: 'location',
      question: '¿Dónde está ubicada principalmente?',
      options: [
        QuizOption(
          id: 'indoor',
          text: 'Interior de casa',
          matchingCategory: [PlantCategory.indoor],
        ),
        QuizOption(
          id: 'outdoor',
          text: 'Exterior (balcón / jardín)',
          matchingCategory: [PlantCategory.outdoor, PlantCategory.tree],
        ),
        QuizOption(
          id: 'window',
          text: 'Cerca de una ventana',
        ),
      ],
    ),
  ];
}