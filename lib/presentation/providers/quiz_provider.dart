import 'package:flutter/foundation.dart';
import 'package:plantcare/domain/entities/quiz.dart';
import 'package:plantcare/domain/entities/catalog_plant.dart';
import 'package:plantcare/domain/entities/enums.dart';
import 'package:plantcare/data/repositories/catalog_repository.dart';

/// Provider para gestionar el estado del quiz de identificación
class QuizProvider extends ChangeNotifier {
  final CatalogRepository _catalogRepository = CatalogRepository();
  
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

  /// Finaliza el quiz y busca plantas coincidentes
  Future<void> finishQuiz() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Recopilar criterios de búsqueda
      List<LightRequirement> lightRequirements = [];
      List<WateringFrequency> wateringFrequencies = [];
      List<HumidityLevel> humidityLevels = [];
      List<PlantCategory> categories = [];

      for (final question in QuizData.questions) {
        final answerId = _answers[question.id];
        if (answerId == null) continue;

        final option = question.options.firstWhere(
          (o) => o.id == answerId,
          orElse: () => question.options.first,
        );

        if (option.matchingLight != null) {
          lightRequirements.addAll(option.matchingLight!);
        }
        if (option.matchingWatering != null) {
          wateringFrequencies.addAll(option.matchingWatering!);
        }
        if (option.matchingHumidity != null) {
          humidityLevels.addAll(option.matchingHumidity!);
        }
        if (option.matchingCategory != null) {
          categories.addAll(option.matchingCategory!);
        }
      }

      // Buscar plantas que coincidan
      _results = await _catalogRepository.searchByCriteria(
        lightRequirements: lightRequirements.isNotEmpty ? lightRequirements : null,
        wateringFrequencies: wateringFrequencies.isNotEmpty ? wateringFrequencies : null,
        humidityLevels: humidityLevels.isNotEmpty ? humidityLevels : null,
        categories: categories.isNotEmpty ? categories : null,
      );

      // Si no hay resultados exactos, devolver todas las plantas
      if (_results.isEmpty) {
        _results = await _catalogRepository.getAllPlants();
      }

      _isCompleted = true;
    } catch (e) {
      debugPrint('Error en el quiz: $e');
      _results = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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