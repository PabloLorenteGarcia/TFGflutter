import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:plantcare/core/theme/app_theme.dart';
import 'package:plantcare/domain/entities/enums.dart';
import 'package:plantcare/domain/entities/plant.dart';
import 'package:plantcare/presentation/providers/plant_provider.dart';
import 'package:plantcare/presentation/providers/catalog_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

/// Pantalla para añadir una nueva planta
class AddPlantScreen extends StatefulWidget {
  final String? catalogPlantId;

  const AddPlantScreen({super.key, this.catalogPlantId});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  LightRequirement _lightRequirement = LightRequirement.medium;
  WateringFrequency _wateringFrequency = WateringFrequency.weekly;
  WateringAmount _wateringAmount = WateringAmount.medium;
  HumidityLevel _humidityLevel = HumidityLevel.medium;
  double _minTemp = 15;
  double _maxTemp = 25;
  bool _notificationsEnabled = true;

  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.catalogPlantId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFromCatalog();
      });
    }
  }

  void _loadFromCatalog() async {
    final catalogProvider = context.read<CatalogProvider>();
    
    // Si el catálogo no está cargado, cargarlo
    if (catalogProvider.allPlants.isEmpty) {
      await catalogProvider.loadPlants();
    }
    
    final catalogPlant = catalogProvider.getPlantById(widget.catalogPlantId!);
    if (catalogPlant != null) {
      setState(() {
        _nameController.text = catalogPlant.name;
        _speciesController.text = catalogPlant.scientificName;
        _lightRequirement = catalogPlant.lightRequirement;
        _wateringFrequency = catalogPlant.wateringFrequency;
        _wateringAmount = catalogPlant.wateringAmount;
        _humidityLevel = catalogPlant.humidityLevel;
        _minTemp = catalogPlant.minTemp;
        _maxTemp = catalogPlant.maxTemp;
      });
    } else {
      // Mostrar mensaje si la planta del catálogo no se encuentra
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Planta no encontrada en el catálogo'),
            backgroundColor: AppColors.error,
          ),
        );
        context.pop(); // Volver atrás
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage(String plantId) async {
    if (_selectedImage == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('plant_images')
          .child('$plantId.jpg');

      await storageRef.putFile(_selectedImage!);
      final downloadUrl = await storageRef.getDownloadURL();

      setState(() {
        _uploadedImageUrl = downloadUrl;
        _isUploadingImage = false;
      });
    } catch (e) {
      setState(() => _isUploadingImage = false);
      // Error will be handled in _savePlant if needed
      rethrow;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.catalogPlantId != null ? 'Añadir Planta' : 'Crear Planta Personalizada'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nombre
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                hintText: 'Ej: Mi Monstera',
                prefixIcon: Icon(Icons.local_florist),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, introduce un nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Imagen
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Imagen (opcional)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Seleccionar imagen'),
                    ),
                    const SizedBox(width: 16),
                    if (_selectedImage != null)
                      Expanded(
                        child: Text(
                          'Imagen seleccionada',
                          style: TextStyle(color: AppColors.success),
                        ),
                      ),
                  ],
                ),
                if (_isUploadingImage)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Especie
            TextFormField(
              controller: _speciesController,
              decoration: const InputDecoration(
                labelText: 'Especie (opcional)',
                hintText: 'Ej: Monstera deliciosa',
                prefixIcon: Icon(Icons.science),
              ),
            ),
            const SizedBox(height: 16),

            // Ubicación
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Ubicación (opcional)',
                hintText: 'Ej: Sala, Ventana norte',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 24),

            // Requisitos de luz
            _buildDropdown<LightRequirement>(
              label: 'Requerimiento de luz',
              value: _lightRequirement,
              items: LightRequirement.values,
              getLabel: (item) => item.label,
              icon: Icons.wb_sunny,
              onChanged: (value) => setState(() => _lightRequirement = value!),
            ),
            const SizedBox(height: 16),

            // Frecuencia de riego
            _buildDropdown<WateringFrequency>(
              label: 'Frecuencia de riego',
              value: _wateringFrequency,
              items: WateringFrequency.values,
              getLabel: (item) => item.label,
              icon: Icons.water_drop,
              onChanged: (value) => setState(() => _wateringFrequency = value!),
            ),
            const SizedBox(height: 16),

            // Cantidad de agua
            _buildDropdown<WateringAmount>(
              label: 'Cantidad de agua',
              value: _wateringAmount,
              items: WateringAmount.values,
              getLabel: (item) => item.label,
              icon: Icons.opacity,
              onChanged: (value) => setState(() => _wateringAmount = value!),
            ),
            const SizedBox(height: 16),

            // Humedad
            _buildDropdown<HumidityLevel>(
              label: 'Nivel de humedad',
              value: _humidityLevel,
              items: HumidityLevel.values,
              getLabel: (item) => '${item.label} (${item.range})',
              icon: Icons.water,
              onChanged: (value) => setState(() => _humidityLevel = value!),
            ),
            const SizedBox(height: 24),

            // Temperatura
            Text(
              'Temperatura (°C)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mín: ${_minTemp.toInt()}°C'),
                      Slider(
                        value: _minTemp,
                        min: -10,
                        max: 40,
                        divisions: 50,
                        label: '${_minTemp.toInt()}°C',
                        onChanged: (value) => setState(() {
                          _minTemp = value;
                          if (_minTemp > _maxTemp) _maxTemp = _minTemp;
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Máx: ${_maxTemp.toInt()}°C'),
                      Slider(
                        value: _maxTemp,
                        min: -10,
                        max: 40,
                        divisions: 50,
                        label: '${_maxTemp.toInt()}°C',
                        onChanged: (value) => setState(() {
                          _maxTemp = value;
                          if (_maxTemp < _minTemp) _minTemp = _maxTemp;
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notas
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                hintText: 'Añade cualquier nota adicional...',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Notificaciones
            SwitchListTile(
              title: const Text('Activar notificaciones de riego'),
              subtitle: const Text('Recibe recordatorios cuando necesite agua'),
              value: _notificationsEnabled,
              onChanged: (value) => setState(() => _notificationsEnabled = value),
            ),
            const SizedBox(height: 32),

            // Botón de guardar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savePlant,
                child: const Text('Guardar Planta'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) getLabel,
    required IconData icon,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(getLabel(item)),
      )).toList(),
      onChanged: onChanged,
    );
  }

  void _savePlant() async {
    if (!_formKey.currentState!.validate()) return;

    // Mostrar indicador de carga
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Guardando planta...'),
        duration: Duration(seconds: 5),
      ),
    );

    final now = DateTime.now();
    final plantId = const Uuid().v4();

    // Upload image if selected
    if (_selectedImage != null) {
      try {
        await _uploadImage(plantId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al subir imagen: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    }

    final plant = Plant(
      id: plantId,
      name: _nameController.text.trim(),
      species: _speciesController.text.trim().isNotEmpty 
          ? _speciesController.text.trim() 
          : null,
      imagePath: _uploadedImageUrl, // Use uploaded URL
      location: _locationController.text.trim().isNotEmpty 
          ? _locationController.text.trim() 
          : null,
      lightRequirement: _lightRequirement,
      wateringFrequency: _wateringFrequency,
      wateringAmount: _wateringAmount,
      minTemp: _minTemp,
      maxTemp: _maxTemp,
      humidityLevel: _humidityLevel,
      notificationsEnabled: _notificationsEnabled,
      createdAt: now,
      nextWatering: now.add(Duration(days: _wateringFrequency.days)),
      notes: _notesController.text.trim().isNotEmpty 
          ? _notesController.text.trim() 
          : null,
      catalogPlantId: widget.catalogPlantId,
    );

    // Esperar a que se complete el guardado
    try {
      await context.read<PlantProvider>().addPlant(plant);
      
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${plant.name} añadida correctamente'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}