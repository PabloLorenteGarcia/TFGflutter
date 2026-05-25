import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:plantcare/core/theme/app_theme.dart';
import 'package:plantcare/domain/entities/enums.dart';
import 'package:plantcare/domain/entities/plant.dart';
import 'package:plantcare/presentation/providers/plant_provider.dart';
import 'package:plantcare/presentation/providers/catalog_provider.dart';
import 'package:plantcare/core/utils/plant_identification_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

/// Pantalla para añadir una nueva planta
class AddPlantScreen extends StatefulWidget {
  final String? catalogPlantId;
  final IdentifiedSpecies? identifiedSpecies;

  const AddPlantScreen({
    super.key,
    this.catalogPlantId,
    this.identifiedSpecies,
  });

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _wateringAmountController = TextEditingController();

  LightRequirement _lightRequirement = LightRequirement.medium;
  WateringFrequency _wateringFrequency = WateringFrequency.weekly;
  double _wateringAmountLiters = 1.0;
  HumidityLevel _humidityLevel = HumidityLevel.medium;
  double _minTemp = 15;
  double _maxTemp = 25;
  bool _notificationsEnabled = true;

  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;
  bool _isIdentifyingPlant = false;

  @override
  void initState() {
    super.initState();
    _wateringAmountController.text = _formatWateringAmount(_wateringAmountLiters);

    if (widget.identifiedSpecies != null) {
      _applyIdentifiedSpecies(widget.identifiedSpecies!);
      return;
    }

    if (widget.catalogPlantId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFromCatalog();
      });
    }
  }

  void _applyIdentifiedSpecies(IdentifiedSpecies species) {
    setState(() {
      _nameController.text = species.commonNames.isNotEmpty
          ? species.commonNames.first
          : species.scientificName;
      _speciesController.text = species.scientificName;
    });
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
        _wateringAmountLiters = catalogPlant.wateringAmount.liters;
        _wateringAmountController.text = _formatWateringAmount(_wateringAmountLiters);
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

  Future<void> _identifyPlant() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una imagen primero'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isIdentifyingPlant = true);

    try {
      final service = PlantIdentificationService();
      final result = await service.identifyPlant(
        images: [_selectedImage!],
        organs: ['auto'], // Detección automática del órgano
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

      // Navegar a la pantalla de resultados
      final selectedSpecies = await context.push<IdentifiedSpecies>(
        '/plant-identification-result',
        extra: result,
      );

      // Si el usuario seleccionó una especie, rellenar los campos
      if (selectedSpecies != null && mounted) {
        setState(() {
          _nameController.text = selectedSpecies.commonNames.isNotEmpty
              ? selectedSpecies.commonNames.first
              : selectedSpecies.scientificName;
          _speciesController.text = selectedSpecies.scientificName;
        });
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

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _wateringAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.identifiedSpecies != null
              ? 'Añadir Planta Sugerida'
              : widget.catalogPlantId != null
                  ? 'Añadir Planta'
                  : 'Crear Planta Personalizada',
        ),
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
                    const SizedBox(width: 12),
                    if (_selectedImage != null)
                      ElevatedButton.icon(
                        onPressed: _isIdentifyingPlant ? null : _identifyPlant,
                        icon: _isIdentifyingPlant
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        label: const Text('Identificar planta'),
                      ),
                  ],
                ),
                if (_selectedImage != null && !_isIdentifyingPlant)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Imagen seleccionada - puedes identificar la planta',
                      style: TextStyle(color: AppColors.success),
                    ),
                  ),
                if (_isIdentifyingPlant)
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
            TextFormField(
              controller: _wateringAmountController,
              decoration: const InputDecoration(
                labelText: 'Cantidad de agua (L)',
                hintText: 'Ej: 1.5',
                prefixIcon: Icon(Icons.opacity),
                suffixText: 'L',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                final liters = _parseWateringAmount(value);
                if (liters == null || liters <= 0) {
                  return 'Introduce una cantidad mayor que 0';
                }
                return null;
              },
              onChanged: (value) {
                final liters = _parseWateringAmount(value);
                if (liters != null) {
                  setState(() => _wateringAmountLiters = liters);
                }
              },
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

  String _formatWateringAmount(double liters) {
    return liters == liters.toInt()
        ? liters.toInt().toString()
        : liters.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  double? _parseWateringAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null) {
      return null;
    }

    return parsed;
  }

  void _savePlant() async {
    if (!_formKey.currentState!.validate()) return;

    final liters = _parseWateringAmount(_wateringAmountController.text);
    if (liters == null || liters <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introduce una cantidad de agua válida en litros'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    _wateringAmountLiters = liters;

    // Verificar que el usuario está autenticado
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error: Debes iniciar sesión primero'),
          backgroundColor: AppColors.error,
        ),
      );
      print('❌ Error: Usuario no autenticado');
      return;
    }

    final userId = currentUser.uid;
    print('👤 Usuario autenticado: $userId');

    // Mostrar indicador de carga
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Guardando planta...'),
        duration: Duration(seconds: 5),
      ),
    );

    final now = DateTime.now();
    final plantId = const Uuid().v4();
    print('🌱 Creando planta: $plantId');

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
      wateringAmount: WateringAmount.fromLiters(_wateringAmountLiters),
      wateringAmountLiters: _wateringAmountLiters,
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
      userId: userId, // Asignar explícitamente el ID del usuario
    );

    // Esperar a que se complete el guardado
    try {
      print('💾 Iniciando guardado de planta...');
      await context.read<PlantProvider>().addPlant(plant);
      print('✅ Planta guardada en provider');
      
      // Asegurar que la lista se recargue desde el repositorio/local+remoto
      print('🔄 Recargando lista de plantas...');
      await context.read<PlantProvider>().loadPlants();
      print('✅ Lista de plantas recargada');

      if (mounted) {
        if (widget.identifiedSpecies != null) {
          context.go('/my-plants');
        } else {
          context.pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${plant.name} añadida correctamente'),
            backgroundColor: AppColors.success,
          ),
        );
        print('✅ Planta guardada exitosamente: ${plant.name}');
      }
    } catch (e) {
      print('❌ ERROR AL GUARDAR PLANTA: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }
}