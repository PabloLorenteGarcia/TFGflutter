import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:plantcare/core/theme/app_theme.dart';
import 'package:plantcare/domain/entities/enums.dart';
import 'package:plantcare/presentation/providers/plant_provider.dart';

/// Pantalla de detalle de una planta del usuario
class PlantDetailScreen extends StatelessWidget {
  final String plantId;

  const PlantDetailScreen({super.key, required this.plantId});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlantProvider>(
      builder: (context, plantProvider, child) {
        final plant = plantProvider.getPlantById(plantId);

        if (plant == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalles')),
            body: const Center(child: Text('Planta no encontrada')),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => context.push('/my-plants/edit/${plant.id}'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _showDeleteDialog(context, plantProvider),
                  ),
                ],
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
                          AppColors.primary,
                          AppColors.primaryDark,
                        ],
                      ),
                    ),
                    child: Center(
                      child: plant.imagePath != null
                          ? Image.asset(
                              plant.imagePath!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholder(),
                            )
                          : _buildPlaceholder(),
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
                      // Nombre y especie
                      if (plant.species != null) ...[
                        Text(
                          plant.species!,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Ubicación
                      if (plant.location != null)
                        _buildInfoRow(
                          context,
                          Icons.location_on,
                          'Ubicación',
                          plant.location!,
                        ),

                      // Estado de riego
                      _buildWateringStatus(context, plant),
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

                      // Notas
                      if (plant.notes != null && plant.notes!.isNotEmpty) ...[
                        Text(
                          'Notas',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(plant.notes!),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Notificaciones
                      _buildNotificationToggle(context, plant),
                      const SizedBox(height: 32),

                      // Botón de regar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => plantProvider.markAsWatered(plant.id),
                          icon: const Icon(Icons.water_drop),
                          label: const Text('Marcar como regada'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.info,
                          ),
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

  Widget _buildPlaceholder() {
    return const Icon(
      Icons.local_florist,
      size: 80,
      color: Colors.white54,
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWateringStatus(BuildContext context, dynamic plant) {
    final needsWater = plant.needsWatering;
    final nextWatering = plant.nextWatering;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: needsWater
            ? AppColors.warning.withValues(alpha: 0.1)
            : AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: needsWater ? AppColors.warning : AppColors.success,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.water_drop,
            color: needsWater ? AppColors.warning : AppColors.success,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  needsWater ? '¡Necesita agua!' : 'Regada',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: needsWater ? AppColors.warning : AppColors.success,
                  ),
                ),
                if (nextWatering != null)
                  Text(
                    'Próximo riego: ${_formatDate(nextWatering)}',
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

  Widget _buildNotificationToggle(BuildContext context, dynamic plant) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.notifications, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              'Notificaciones de riego',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        Switch(
          value: plant.notificationsEnabled,
          onChanged: (value) {
            context.read<PlantProvider>().updatePlant(
              plant.copyWith(notificationsEnabled: value),
            );
          },
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    if (diff < 7) return 'En $diff días';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDeleteDialog(BuildContext context, PlantProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar planta'),
        content: const Text('¿Estás seguro de que quieres eliminar esta planta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              provider.deletePlant(plantId);
              Navigator.pop(context);
              context.go('/my-plants');
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}