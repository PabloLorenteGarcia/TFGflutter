import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plantcare/core/theme/app_theme.dart';
import 'package:plantcare/core/utils/plant_identification_service.dart';

/// Pantalla para mostrar los resultados de identificación de plantas
class PlantIdentificationResultScreen extends StatelessWidget {
  final PlantIdentificationResult result;

  const PlantIdentificationResultScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado de Identificación'),
      ),
      body: result.error != null
          ? _buildErrorView(context)
          : _buildResultsView(context),
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error en la identificación',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              result.error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Información general
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Identificación completada',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Peticiones restantes: ${result.remainingRequests}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Lista de especies identificadas
        Text(
          'Especies identificadas',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),

        ...result.species.map((species) => _buildSpeciesCard(context, species)),

        const SizedBox(height: 24),

        // Botones de acción
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Volver'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: result.species.isNotEmpty
                    ? () => _selectSpecies(context, result.species.first)
                    : null,
                child: const Text('Usar primera opción'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpeciesCard(BuildContext context, IdentifiedSpecies species) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/plant-identification-detail', extra: species),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre científico y probabilidad
              Row(
                children: [
                  Expanded(
                    child: Text(
                      species.scientificName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getProbabilityColor(species.probability),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${species.probability.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              // Autoría científica
              if (species.scientificNameAuthorship != null) ...[
                const SizedBox(height: 4),
                Text(
                  species.scientificNameAuthorship!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],

              // Familia y género
              if (species.genus != null || species.family != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (species.genus != null) ...[
                      Text(
                        'Género: ${species.genus}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (species.family != null)
                      Text(
                        'Familia: ${species.family}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ],

              // Nombres comunes
              if (species.commonNames.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Nombres comunes: ${species.commonNames.take(3).join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getProbabilityColor(double probability) {
    if (probability >= 80) return AppColors.success;
    if (probability >= 60) return AppColors.warning;
    return AppColors.error;
  }

  void _selectSpecies(BuildContext context, IdentifiedSpecies species) {
    context.push('/plant-identification-detail', extra: species);
  }
}