import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:plantcare/core/theme/app_theme.dart';
import 'package:plantcare/domain/entities/enums.dart';
import 'package:plantcare/presentation/providers/quiz_provider.dart';
import 'package:plantcare/presentation/widgets/empty_state.dart';

/// Pantalla de resultados del quiz
class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, quizProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Resultados'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                quizProvider.resetQuiz();
                context.go('/quiz');
              },
            ),
          ),
          body: quizProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : quizProvider.results.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off,
                      title: 'Sin resultados',
                      description: 'No se encontraron plantas que coincidan con tus respuestas',
                      actionLabel: 'Intentar de nuevo',
                      onAction: () {
                        quizProvider.resetQuiz();
                        context.go('/quiz');
                      },
                    )
                  : _buildResults(context, quizProvider),
        );
      },
    );
  }

  Widget _buildResults(BuildContext context, QuizProvider quizProvider) {
    return Column(
      children: [
        // Resumen
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          color: AppColors.primaryLight.withValues(alpha: 0.3),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                '¡Quiz completado!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Se encontraron ${quizProvider.results.length} plantas que pueden coincidir',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Lista de resultados
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: quizProvider.results.length,
            itemBuilder: (context, index) {
              final plant = quizProvider.results[index];
              return _buildResultCard(context, plant);
            },
          ),
        ),

        // Botón de acción
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                quizProvider.resetQuiz();
                context.go('/quiz');
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Hacer otro quiz'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(BuildContext context, dynamic plant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/catalog/${plant.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icono
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getCategoryColor(plant.category).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(plant.category),
                  color: _getCategoryColor(plant.category),
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plant.scientificName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.wb_sunny, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          plant.lightRequirement.label,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.water_drop, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          plant.wateringFrequency.label,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Acción rápida
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.primary,
                    onPressed: () => context.push('/my-plants/add?fromCatalog=${plant.id}'),
                    tooltip: 'Añadir a mi colección',
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(PlantCategory category) {
    switch (category) {
      case PlantCategory.indoor:
        return AppColors.categoryIndoor;
      case PlantCategory.outdoor:
        return AppColors.categoryOutdoor;
      case PlantCategory.succulent:
        return AppColors.categorySucculent;
      case PlantCategory.flower:
        return AppColors.categoryFlower;
      case PlantCategory.herb:
        return AppColors.categoryHerb;
      case PlantCategory.tree:
        return AppColors.categoryTree;
      case PlantCategory.cactus:
        return AppColors.categoryCactus;
    }
  }

  IconData _getCategoryIcon(PlantCategory category) {
    switch (category) {
      case PlantCategory.indoor:
        return Icons.home;
      case PlantCategory.outdoor:
        return Icons.park;
      case PlantCategory.succulent:
        return Icons.grass;
      case PlantCategory.flower:
        return Icons.local_florist;
      case PlantCategory.herb:
        return Icons.spa;
      case PlantCategory.tree:
        return Icons.park;
      case PlantCategory.cactus:
        return Icons.filter_vintage;
    }
  }
}