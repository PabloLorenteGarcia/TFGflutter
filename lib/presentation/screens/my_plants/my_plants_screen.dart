import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:plantcare/core/theme/app_theme.dart';
import 'package:plantcare/core/utils/plant_identification_service.dart';
import 'package:plantcare/presentation/providers/plant_provider.dart';
import 'package:plantcare/presentation/widgets/plant_card.dart';
import 'package:plantcare/presentation/widgets/empty_state.dart';

/// Pantalla de mis plantas
class MyPlantsScreen extends StatefulWidget {
  const MyPlantsScreen({super.key});

  @override
  State<MyPlantsScreen> createState() => _MyPlantsScreenState();
}

class _MyPlantsScreenState extends State<MyPlantsScreen> {
  bool _isIdentifyingPlant = false;

  Future<void> _pickAndIdentifyPlant(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) return;

    setState(() => _isIdentifyingPlant = true);

    try {
      final service = PlantIdentificationService();
      dynamic imageData;
      String? imageName;

      // Manejar tanto mobile como web
      if (kIsWeb) {
        // Para web: usar Uint8List
        imageData = await pickedFile.readAsBytes();
        imageName = pickedFile.name;
      } else {
        // Para mobile: usar File
        imageData = File(pickedFile.path);
      }

      final result = await service.identifyPlant(
        images: [imageData],
        organs: ['auto'],
        imageNames: imageName != null ? [imageName] : null,
      );

      setState(() => _isIdentifyingPlant = false);

      if (result.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result.error}'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final selectedSpecies = await context.push<IdentifiedSpecies>(
        '/plant-identification-result',
        extra: result,
      );

      if (selectedSpecies != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Especie seleccionada: ${selectedSpecies.scientificName}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _isIdentifyingPlant = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al identificar la planta: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showIdentificationSourceDialog() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Seleccionar imagen'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: const Text('Tomar foto'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: const Text('Seleccionar de galería'),
            ),
          ],
        );
      },
    );

    if (source != null) {
      await _pickAndIdentifyPlant(source);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Plantas'),
        actions: [
          IconButton(
            icon: _isIdentifyingPlant
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.camera_alt_outlined),
            tooltip: 'Identificar planta',
            onPressed: _isIdentifyingPlant ? null : _showIdentificationSourceDialog,
          ),
        ],
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
