import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:plantcare/core/theme/app_theme.dart';
import 'package:plantcare/presentation/providers/quiz_provider.dart';

/// Pantalla del quiz de identificación de plantas
class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, child) {
        // Si el quiz está completado, mostrar resultados
        if (quizProvider.isCompleted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/quiz/result');
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Identifica tu planta'),
            actions: [
              if (quizProvider.currentQuestionIndex > 0)
                TextButton(
                  onPressed: () => quizProvider.resetQuiz(),
                  child: const Text('Reiniciar', style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
          body: quizProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildQuizContent(context, quizProvider),
        );
      },
    );
  }

  Widget _buildQuizContent(BuildContext context, QuizProvider quizProvider) {
    final question = quizProvider.currentQuestion;
    if (question == null) {
      return const Center(child: Text('Error al cargar las preguntas'));
    }

    return Column(
      children: [
        // Progress indicator
        LinearProgressIndicator(
          value: quizProvider.progress,
          backgroundColor: AppColors.surfaceVariant,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
        
        // Pregunta
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Número de pregunta
                Text(
                  'Pregunta ${quizProvider.currentQuestionIndex + 1} de ${quizProvider.totalQuestions}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // Pregunta
                Text(
                  question.question,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Opciones
                ...question.options.map((option) => _buildOption(
                  context,
                  quizProvider,
                  option.id,
                  option.text,
                  quizProvider.currentAnswer == option.id,
                )),
              ],
            ),
          ),
        ),

        // Botones de navegación
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (quizProvider.canGoPrevious)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => quizProvider.previousQuestion(),
                    child: const Text('Anterior'),
                  ),
                ),
              if (quizProvider.canGoPrevious) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: quizProvider.currentAnswer == null
                      ? null
                      : () {
                          if (quizProvider.canFinish) {
                            quizProvider.finishQuiz();
                          } else {
                            quizProvider.nextQuestion();
                          }
                        },
                  child: Text(
                    quizProvider.canFinish ? 'Ver resultados' : 'Siguiente',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOption(
    BuildContext context,
    QuizProvider quizProvider,
    String optionId,
    String text,
    bool isSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => quizProvider.selectAnswer(optionId),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}