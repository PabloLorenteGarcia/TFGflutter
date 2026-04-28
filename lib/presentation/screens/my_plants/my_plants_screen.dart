import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:plantcare/presentation/providers/plant_provider.dart';
import 'package:plantcare/presentation/widgets/plant_card.dart';
import 'package:plantcare/presentation/widgets/empty_state.dart';

/// Pantalla de mis plantas
class MyPlantsScreen extends StatelessWidget {
  const MyPlantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Plantas'),
      ),
      body: Consumer<PlantProvider>(
        builder: (context, plantProvider, child) {
          if (plantProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (plantProvider.plants.isEmpty) {
            return EmptyState(
              icon: Icons.yard_outlined,
              title: 'Sin plantas aún',
              description: 'Añade tu primera planta para comenzar a cuidarla',
              actionLabel: 'Añadir planta',
              onAction: () => context.push('/my-plants/add'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => plantProvider.loadPlants(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: plantProvider.plants.length,
              itemBuilder: (context, index) {
                final plant = plantProvider.plants[index];
                return PlantCard(
                  plant: plant,
                  onTap: () => context.push('/my-plants/${plant.id}'),
                  onWater: () => plantProvider.markAsWatered(plant.id),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/my-plants/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}