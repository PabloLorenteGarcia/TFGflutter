import 'package:plantcare/domain/entities/enums.dart';

/// Entidad que representa una planta registrada por el usuario
class Plant {
  final String id;
  final String name;
  final String? species;
  final String? imagePath;
  final String? location;
  final LightRequirement lightRequirement;
  final WateringFrequency wateringFrequency;
  final WateringAmount wateringAmount;
  final double minTemp;
  final double maxTemp;
  final HumidityLevel humidityLevel;
  final DateTime? lastWatered;
  final DateTime? nextWatering;
  final DateTime? lastSunExposure;
  final bool notificationsEnabled;
  final DateTime createdAt;
  final String? notes;
  final String? catalogPlantId; // Referencia a planta del catálogo

  Plant({
    required this.id,
    required this.name,
    this.species,
    this.imagePath,
    this.location,
    required this.lightRequirement,
    required this.wateringFrequency,
    required this.wateringAmount,
    required this.minTemp,
    required this.maxTemp,
    required this.humidityLevel,
    this.lastWatered,
    this.nextWatering,
    this.lastSunExposure,
    this.notificationsEnabled = true,
    required this.createdAt,
    this.notes,
    this.catalogPlantId,
  });

  /// Crea una copia con los campos actualizados
  Plant copyWith({
    String? id,
    String? name,
    String? species,
    String? imagePath,
    String? location,
    LightRequirement? lightRequirement,
    WateringFrequency? wateringFrequency,
    WateringAmount? wateringAmount,
    double? minTemp,
    double? maxTemp,
    HumidityLevel? humidityLevel,
    DateTime? lastWatered,
    DateTime? nextWatering,
    DateTime? lastSunExposure,
    bool? notificationsEnabled,
    DateTime? createdAt,
    String? notes,
    String? catalogPlantId,
  }) {
    return Plant(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      imagePath: imagePath ?? this.imagePath,
      location: location ?? this.location,
      lightRequirement: lightRequirement ?? this.lightRequirement,
      wateringFrequency: wateringFrequency ?? this.wateringFrequency,
      wateringAmount: wateringAmount ?? this.wateringAmount,
      minTemp: minTemp ?? this.minTemp,
      maxTemp: maxTemp ?? this.maxTemp,
      humidityLevel: humidityLevel ?? this.humidityLevel,
      lastWatered: lastWatered ?? this.lastWatered,
      nextWatering: nextWatering ?? this.nextWatering,
      lastSunExposure: lastSunExposure ?? this.lastSunExposure,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      catalogPlantId: catalogPlantId ?? this.catalogPlantId,
    );
  }

  /// Convierte a mapa para guardar en la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'imagePath': imagePath,
      'location': location,
      'lightRequirement': lightRequirement.index,
      'wateringFrequency': wateringFrequency.index,
      'wateringAmount': wateringAmount.index,
      'minTemp': minTemp,
      'maxTemp': maxTemp,
      'humidityLevel': humidityLevel.index,
      'lastWatered': lastWatered?.millisecondsSinceEpoch,
      'nextWatering': nextWatering?.millisecondsSinceEpoch,
      'lastSunExposure': lastSunExposure?.millisecondsSinceEpoch,
      'notificationsEnabled': notificationsEnabled ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'notes': notes,
      'catalogPlantId': catalogPlantId,
    };
  }

  /// Crea una planta desde un mapa de la base de datos
  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      id: map['id'] as String,
      name: map['name'] as String,
      species: map['species'] as String?,
      imagePath: map['imagePath'] as String?,
      location: map['location'] as String?,
      lightRequirement: LightRequirement.values[map['lightRequirement'] as int],
      wateringFrequency: WateringFrequency.values[map['wateringFrequency'] as int],
      wateringAmount: WateringAmount.values[map['wateringAmount'] as int],
      minTemp: (map['minTemp'] as num).toDouble(),
      maxTemp: (map['maxTemp'] as num).toDouble(),
      humidityLevel: HumidityLevel.values[map['humidityLevel'] as int],
      lastWatered: map['lastWatered'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastWatered'] as int)
          : null,
      nextWatering: map['nextWatering'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['nextWatering'] as int)
          : null,
      lastSunExposure: map['lastSunExposure'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSunExposure'] as int)
          : null,
      notificationsEnabled: (map['notificationsEnabled'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      notes: map['notes'] as String?,
      catalogPlantId: map['catalogPlantId'] as String?,
    );
  }

  /// Calcula la próxima fecha de riego
  DateTime calculateNextWatering() {
    final now = DateTime.now();
    return now.add(Duration(days: wateringFrequency.days));
  }

  /// Verifica si necesita riego
  bool get needsWatering {
    if (nextWatering == null) return true;
    return DateTime.now().isAfter(nextWatering!);
  }

  /// Días hasta el próximo riego
  int get daysUntilWatering {
    if (nextWatering == null) return 0;
    final diff = nextWatering!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }
}