import 'package:flutter/material.dart';
import 'package:plantcare/core/theme/app_theme.dart';
import 'package:plantcare/domain/entities/plant.dart';

/// Widget de tarjeta para mostrar una planta
class PlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback? onTap;
  final VoidCallback? onWater;

  const PlantCard({
    super.key,
    required this.plant,
    this.onTap,
    this.onWater,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Imagen o icono
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: plant.imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          plant.imagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        ),
                      )
                    : _buildPlaceholder(),
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
                    if (plant.species != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        plant.species!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildInfoChip(
                          Icons.wb_sunny_outlined,
                          plant.lightRequirement.label,
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          Icons.water_drop_outlined,
                          plant.wateringFrequency.label,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Estado de riego
              if (plant.needsWatering && onWater != null)
                IconButton(
                  onPressed: onWater,
                  icon: const Icon(Icons.water_drop),
                  color: AppColors.warning,
                  tooltip: 'Marcar como regada',
                )
              else if (!plant.needsWatering)
                Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(
        Icons.local_florist,
        color: AppColors.primary,
        size: 30,
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}