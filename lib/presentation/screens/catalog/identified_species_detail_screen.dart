import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plantcare/core/theme/app_theme.dart';
import 'package:plantcare/core/utils/plant_identification_service.dart';

class IdentifiedSpeciesDetailScreen extends StatelessWidget {
  final IdentifiedSpecies species;

  const IdentifiedSpeciesDetailScreen({
    super.key,
    required this.species,
  });

  @override
  Widget build(BuildContext context) {
    final commonNames = species.commonNames;
    final primaryCommonName = commonNames.isNotEmpty ? commonNames.first : 'Sin nombre común';

    return Scaffold(
      appBar: AppBar(
        title: Text(species.scientificName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    species.scientificName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (species.scientificNameAuthorship != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      species.scientificNameAuthorship!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _infoRow(
                    context,
                    icon: Icons.local_florist,
                    label: 'Nombre común',
                    value: primaryCommonName,
                  ),
                  _infoRow(
                    context,
                    icon: Icons.label,
                    label: 'Probabilidad',
                    value: '${species.probability.toStringAsFixed(1)}%',
                  ),
                  _infoRow(
                    context,
                    icon: Icons.analytics,
                    label: 'Confianza',
                    value: species.score.toStringAsFixed(2),
                  ),
                  if (species.genus != null)
                    _infoRow(
                      context,
                      icon: Icons.category,
                      label: 'Género',
                      value: species.genus!,
                    ),
                  if (species.family != null)
                    _infoRow(
                      context,
                      icon: Icons.eco,
                      label: 'Familia',
                      value: species.family!,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (commonNames.length > 1)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Otros nombres comunes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: commonNames
                          .skip(1)
                          .map(
                            (name) => Chip(label: Text(name)),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push(
                '/my-plants/add',
                extra: species,
              ),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Añadir a mis plantas'),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
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
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
