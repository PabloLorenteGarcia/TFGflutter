import 'package:flutter/foundation.dart';
import 'package:plantcare/core/constants/plant_catalog_data.dart';
import 'package:plantcare/domain/entities/quiz.dart';
import 'package:plantcare/domain/entities/catalog_plant.dart';
import 'package:plantcare/domain/entities/enums.dart';
import 'package:plantcare/data/repositories/catalog_repository.dart';

/// Provider para gestionar el estado del quiz de identificación
class QuizProvider extends ChangeNotifier {
  final CatalogRepository _catalogRepository;

  QuizProvider({CatalogRepository? catalogRepository})
      : _catalogRepository = catalogRepository ?? CatalogRepository();

  int _currentQuestionIndex = 0;
  Map<String, String> _answers = {};
  List<CatalogPlant> _results = [];
  bool _isLoading = false;
  bool _isCompleted = false;

  int get currentQuestionIndex => _currentQuestionIndex;
  Map<String, String> get answers => _answers;
  List<CatalogPlant> get results => _results;
  bool get isLoading => _isLoading;
  bool get isCompleted => _isCompleted;
  
  QuizQuestion? get currentQuestion => 
      _currentQuestionIndex < QuizData.questions.length 
          ? QuizData.questions[_currentQuestionIndex] 
          : null;
  
  int get totalQuestions => QuizData.questions.length;
  
  double get progress => (_currentQuestionIndex + 1) / totalQuestions;

  /// Selecciona una respuesta para la pregunta actual
  void selectAnswer(String optionId) {
    if (currentQuestion != null) {
      _answers[currentQuestion!.id] = optionId;
      notifyListeners();
    }
  }

  /// Obtiene la respuesta seleccionada para la pregunta actual
  String? get currentAnswer => 
      currentQuestion != null ? _answers[currentQuestion!.id] : null;

  /// Avanza a la siguiente pregunta
  void nextQuestion() {
    if (_currentQuestionIndex < QuizData.questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  /// Retrocede a la pregunta anterior
  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  /// Puede ir a la siguiente pregunta
  bool get canGoNext => currentAnswer != null && _currentQuestionIndex < totalQuestions - 1;

  /// Puede ir a la pregunta anterior
  bool get canGoPrevious => _currentQuestionIndex > 0;

  /// Puede finalizar el quiz
  bool get canFinish => currentAnswer != null && _currentQuestionIndex == totalQuestions - 1;

  /// Finaliza el quiz y sugiere plantas basadas en similitud
  Future<void> finishQuiz() async {
    _isLoading = true;
    notifyListeners();

    try {
      final allPlants = await _catalogRepository.getAllPlants();
      final fallbackPlants = PlantCatalogData.getDefaultPlants();
      final plantsToRank = allPlants.isNotEmpty ? allPlants : fallbackPlants;

      _results = _rankPlants(plantsToRank);
    } catch (e) {
      debugPrint('Error en el quiz: $e');
      _results = PlantCatalogData.getDefaultPlants();
    } finally {
      _isCompleted = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  List<CatalogPlant> _rankPlants(List<CatalogPlant> plants) {
    final rankedResults = [...plants]
      ..sort((a, b) {
        final scoreA = _scorePlant(a);
        final scoreB = _scorePlant(b);

        if (scoreA != scoreB) {
          return scoreB.compareTo(scoreA);
        }

        return a.name.compareTo(b.name);
      });

    return rankedResults.take(5).toList();
  }

  /// Calcula la mejor planta sugerida según las respuestas del quiz
  CatalogPlant? get suggestedPlant {
    if (_results.isEmpty) return null;

    final rankedResults = [..._results]
      ..sort((a, b) {
        final scoreA = _scorePlant(a);
        final scoreB = _scorePlant(b);

        if (scoreA != scoreB) {
          return scoreB.compareTo(scoreA);
        }

        return a.name.compareTo(b.name);
      });

    return rankedResults.first;
  }

  int _scorePlant(CatalogPlant plant) {
    int score = 0;

    for (final question in QuizData.questions) {
      final answerId = _answers[question.id];
      if (answerId == null) continue;

      final option = question.options.firstWhere(
        (option) => option.id == answerId,
        orElse: () => question.options.first,
      );

      if (question.id == 'light') {
        if (option.matchingLight != null &&
            option.matchingLight!.contains(plant.lightRequirement)) {
          score += 6;
        } else {
          score += _lightSimilarity(plant.lightRequirement, option.matchingLight);
        }
      }

      if (question.id == 'watering') {
        if (option.matchingWatering != null &&
            option.matchingWatering!.contains(plant.wateringFrequency)) {
          score += 6;
        } else {
          score += _wateringSimilarity(plant.wateringFrequency, option.matchingWatering);
        }
      }

      if (question.id == 'humidity') {
        if (option.matchingHumidity != null &&
            option.matchingHumidity!.contains(plant.humidityLevel)) {
          score += 5;
        } else {
          score += _humiditySimilarity(plant.humidityLevel, option.matchingHumidity);
        }
      }

      if (question.id == 'type') {
        if (option.matchingCategory != null &&
            option.matchingCategory!.contains(plant.category)) {
          score += 7;
        } else {
          score += _categorySimilarity(plant.category, option.matchingCategory);
        }
      }

      if (question.id == 'maintenance') {
        if (option.id == 'easy' &&
            [WateringFrequency.biweekly, WateringFrequency.monthly].contains(plant.wateringFrequency)) {
          score += 3;
        }
        if (option.id == 'medium' &&
            [WateringFrequency.weekly, WateringFrequency.biweekly].contains(plant.wateringFrequency)) {
          score += 3;
        }
        if (option.id == 'careful' &&
            [WateringFrequency.daily, WateringFrequency.everyTwoDays, WateringFrequency.weekly]
                .contains(plant.wateringFrequency)) {
          score += 3;
        }
      }

      if (question.id == 'space') {
        if (option.id == 'indoor' && plant.category == PlantCategory.indoor) {
          score += 4;
        }
        if (option.id == 'balcony' &&
            [PlantCategory.outdoor, PlantCategory.herb, PlantCategory.flower].contains(plant.category)) {
          score += 4;
        }
        if (option.id == 'garden' &&
            [PlantCategory.outdoor, PlantCategory.tree, PlantCategory.cactus].contains(plant.category)) {
          score += 4;
        }
        if (option.id == 'bathroom' && plant.humidityLevel == HumidityLevel.high) {
          score += 4;
        }
      }
    }

    return score;
  }

  int _lightSimilarity(LightRequirement plantLight, List<LightRequirement>? preferred) {
    if (preferred == null || preferred.isEmpty) return 0;

    final preferredLight = preferred.first;
    if (preferredLight == plantLight) return 2;

    const order = [
      LightRequirement.low,
      LightRequirement.medium,
      LightRequirement.high,
      LightRequirement.direct,
    ];

    final plantIndex = order.indexOf(plantLight);
    final preferredIndex = order.indexOf(preferredLight);
    final distance = (plantIndex - preferredIndex).abs();
    return distance == 1 ? 1 : 0;
  }

  int _wateringSimilarity(WateringFrequency plantWatering, List<WateringFrequency>? preferred) {
    if (preferred == null || preferred.isEmpty) return 0;

    final preferredWatering = preferred.first;
    if (preferredWatering == plantWatering) return 2;

    const order = [
      WateringFrequency.daily,
      WateringFrequency.everyTwoDays,
      WateringFrequency.weekly,
      WateringFrequency.biweekly,
      WateringFrequency.monthly,
    ];

    final plantIndex = order.indexOf(plantWatering);
    final preferredIndex = order.indexOf(preferredWatering);
    final distance = (plantIndex - preferredIndex).abs();
    return distance == 1 ? 1 : 0;
  }

  int _humiditySimilarity(HumidityLevel plantHumidity, List<HumidityLevel>? preferred) {
    if (preferred == null || preferred.isEmpty) return 0;

    final preferredHumidity = preferred.first;
    if (preferredHumidity == plantHumidity) return 2;

    const order = [HumidityLevel.low, HumidityLevel.medium, HumidityLevel.high];
    final plantIndex = order.indexOf(plantHumidity);
    final preferredIndex = order.indexOf(preferredHumidity);
    final distance = (plantIndex - preferredIndex).abs();
    return distance == 1 ? 1 : 0;
  }

  int _categorySimilarity(PlantCategory plantCategory, List<PlantCategory>? preferred) {
    if (preferred == null || preferred.isEmpty) return 0;

    if (preferred.contains(plantCategory)) return 2;

    return 0;
  }

  /// Reinicia el quiz
  void resetQuiz() {
    _currentQuestionIndex = 0;
    _answers = {};
    _results = [];
    _isLoading = false;
    _isCompleted = false;
    notifyListeners();
  }

  /// Va a una pregunta específica
  void goToQuestion(int index) {
    if (index >= 0 && index < totalQuestions) {
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }
}