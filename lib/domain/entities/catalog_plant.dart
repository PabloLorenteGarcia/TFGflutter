import 'package:plantcare/domain/entities/enums.dart';

/// Entidad que representa una planta del catálogo
class CatalogPlant {
  final String id;
  final String name;
  final String scientificName;
  final PlantCategory category;
  final String description;
  final LightRequirement lightRequirement;
  final WateringFrequency wateringFrequency;
  final WateringAmount wateringAmount;
  final double minTemp;
  final double maxTemp;
  final HumidityLevel humidityLevel;
  final String careTips;
  final String? imageUrl;

  CatalogPlant({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.category,
    required this.description,
    required this.lightRequirement,
    required this.wateringFrequency,
    required this.wateringAmount,
    required this.minTemp,
    required this.maxTemp,
    required this.humidityLevel,
    required this.careTips,
    this.imageUrl,
  });

  /// Convierte a mapa para guardar en la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'scientificName': scientificName,
      'category': category.index,
      'description': description,
      'lightRequirement': lightRequirement.index,
      'wateringFrequency': wateringFrequency.index,
      'wateringAmount': wateringAmount.index,
      'minTemp': minTemp,
      'maxTemp': maxTemp,
      'humidityLevel': humidityLevel.index,
      'careTips': careTips,
      'imageUrl': imageUrl,
    };
  }

  /// Crea una planta del catálogo desde un mapa
  factory CatalogPlant.fromMap(Map<String, dynamic> map) {
    return CatalogPlant(
      id: map['id'] as String,
      name: map['name'] as String,
      scientificName: map['scientificName'] as String,
      category: PlantCategory.values[map['category'] as int],
      description: map['description'] as String,
      lightRequirement: LightRequirement.values[map['lightRequirement'] as int],
      wateringFrequency: WateringFrequency.values[map['wateringFrequency'] as int],
      wateringAmount: WateringAmount.values[map['wateringAmount'] as int],
      minTemp: (map['minTemp'] as num).toDouble(),
      maxTemp: (map['maxTemp'] as num).toDouble(),
      humidityLevel: HumidityLevel.values[map['humidityLevel'] as int],
      careTips: map['careTips'] as String,
      imageUrl: map['imageUrl'] as String?,
    );
  }
}