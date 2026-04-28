import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:plantcare/core/theme/app_theme.dart';
import 'package:plantcare/presentation/providers/plant_provider.dart';
import 'package:plantcare/presentation/widgets/plant_card.dart';
import 'package:plantcare/presentation/widgets/empty_state.dart';

/// Pantalla principal - Dashboard
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PlantCare'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/my-plants/add'),
          ),
        ],
      ),
      body: Consumer<PlantProvider>(
        builder: (context, plantProvider, child) {
          if (plantProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => plantProvider.loadPlants(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Saludo
                  _buildGreeting(context),
                  const SizedBox(height: 24),
                  
                  // Estadísticas
                  _buildStats(context, plantProvider),
                  const SizedBox(height: 24),
                  
                  // Plantas que necesitan riego
                  if (plantProvider.plantsNeedingWater.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      '💧 Plantas que necesitan riego',
                      onSeeAll: () => context.go('/my-plants'),
                    ),
                    const SizedBox(height: 12),
                    _buildWateringList(context, plantProvider),
                    const SizedBox(height: 24),
                  ],
                  
                  // Mis plantas recientes
                  _buildSectionHeader(
                    context,
                    '🌱 Mis plantas',
                    onSeeAll: () => context.go('/my-plants'),
                  ),
                  const SizedBox(height: 12),
                  if (plantProvider.plants.isEmpty)
                    _buildEmptyPlants(context)
                  else
                    _buildRecentPlants(context, plantProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = '🌅 Buenos días';
    } else if (hour < 18) {
      greeting = '☀️ Buenas tardes';
    } else {
      greeting = '🌙 Buenas noches';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '¿Cómo están tus plantas hoy?',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStats(BuildContext context, PlantProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.yard,
            label: 'Total plantas',
            value: provider.totalPlants.toString(),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.water_drop,
            label: 'Necesitan riego',
            value: provider.plantsNeedingWater.length.toString(),
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onSeeAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('Ver todas'),
          ),
      ],
    );
  }

  Widget _buildWateringList(BuildContext context, PlantProvider provider) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: provider.plantsNeedingWater.length,
        itemBuilder: (context, index) {
          final plant = provider.plantsNeedingWater[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              child: InkWell(
                onTap: () => context.push('/my-plants/${plant.id}'),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.water_drop,
                        color: AppColors.warning,
                        size: 24,
                      ),
                      const Spacer(),
                      Text(
                        plant.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Necesita agua',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyPlants(BuildContext context) {
    return EmptyState(
      icon: Icons.yard_outlined,
      title: 'Sin plantas aún',
      description: 'Añade tu primera planta para comenzar',
      actionLabel: 'Añadir planta',
      onAction: () => context.push('/my-plants/add'),
    );
  }

  Widget _buildRecentPlants(BuildContext context, PlantProvider provider) {
    final recentPlants = provider.plants.take(5).toList();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentPlants.length,
      itemBuilder: (context, index) {
        return PlantCard(
          plant: recentPlants[index],
          onTap: () => context.push('/my-plants/${recentPlants[index].id}'),
        );
      },
    );
  }
}