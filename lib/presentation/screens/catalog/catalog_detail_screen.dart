import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:plantcare/core/theme/app_theme.dart';
import 'package:plantcare/domain/entities/enums.dart';
import 'package:plantcare/presentation/providers/catalog_provider.dart';

/// Pantalla de detalle de una planta del catálogo
class CatalogDetailScreen extends StatelessWidget {
  final String plantId;

  const CatalogDetailScreen({super.key, required this.plantId});

  @override
  Widget build(BuildContext context) {
    return Consumer<CatalogProvider>(
      builder: (context, catalogProvider, child) {
        final plant = catalogProvider.getPlantById(plantId);

        if (plant == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalles')),
            body: const Center(child: Text('Planta no encontrada')),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // App Bar con imagen
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    plant.name,
                    style: const TextStyle(
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _getCategoryColor(plant.category),
                          _getCategoryColor(plant.category).withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _getCategoryIcon(plant.category),
                        size: 80,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),

              // Contenido
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre científico
                      Text(
                        plant.scientificName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Categoría
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(plant.category).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          plant.category.label,
                          style: TextStyle(
                            color: _getCategoryColor(plant.category),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Descripción
                      Text(
                        'Descripción',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        plant.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),

                      // Requisitos
                      Text(
                        'Requisitos',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRequirementRow(
                        context,
                        Icons.wb_sunny,
                        'Luz',
                        plant.lightRequirement.label,
                        plant.lightRequirement.description,
                      ),
                      _buildRequirementRow(
                        context,
                        Icons.water_drop,
                        'Riego',
                        plant.wateringFrequency.label,
                        plant.wateringAmount.description,
                      ),
                      _buildRequirementRow(
                        context,
                        Icons.thermostat,
                        'Temperatura',
                        '${plant.minTemp.toInt()}°C - ${plant.maxTemp.toInt()}°C',
                        'Rango óptimo',
                      ),
                      _buildRequirementRow(
                        context,
                        Icons.opacity,
                        'Humedad',
                        plant.humidityLevel.label,
                        plant.humidityLevel.range,
                      ),
                      const SizedBox(height: 24),

                      // Consejos de cuidado
                      Text(
                        'Consejos de cuidado',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                plant.careTips,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Botón para añadir a colección
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/my-plants/add?fromCatalog=${plant.id}'),
                          icon: const Icon(Icons.add),
                          label: const Text('Añadir a mi colección'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequirementRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
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