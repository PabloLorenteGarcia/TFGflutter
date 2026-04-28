import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:plantcare/core/theme/app_theme.dart';
import 'package:plantcare/domain/entities/enums.dart';
import 'package:plantcare/domain/entities/plant.dart';
import 'package:plantcare/presentation/providers/plant_provider.dart';
import 'package:plantcare/presentation/providers/catalog_provider.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.catalogPlantId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFromCatalog();
      });
    }
  }

  void _loadFromCatalog() {
    final catalogProvider = context.read<CatalogProvider>();
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
        title: const Text('Añadir Planta'),
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
              activeColor: AppColors.primary,
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

  void _savePlant() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final plant = Plant(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        species: _speciesController.text.trim().isNotEmpty 
            ? _speciesController.text.trim() 
            : null,
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

      context.read<PlantProvider>().addPlant(plant);
      context.pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${plant.name} añadida correctamente'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}