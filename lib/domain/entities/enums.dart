/// Enum para los requisitos de luz de una planta
enum LightRequirement {
  low('Bajo', 'Tolera sombra parcial'),
  medium('Medio', 'Luz indirecta brillante'),
  high('Alto', 'Mucha luz, sin sol directo'),
  direct('Directo', 'Sol directo varias horas');

  final String label;
  final String description;
  const LightRequirement(this.label, this.description);
}

/// Enum para la frecuencia de riego
enum WateringFrequency {
  daily('Diario', 1),
  everyTwoDays('Cada 2 días', 2),
  weekly('Semanal', 7),
  biweekly('Quincenal', 14),
  monthly('Mensual', 30);

  final String label;
  final int days;
  const WateringFrequency(this.label, this.days);
}

/// Enum para el nivel de humedad requerido
enum HumidityLevel {
  low('Bajo', '30-40%'),
  medium('Medio', '40-60%'),
  high('Alto', '60-80%');

  final String label;
  final String range;
  const HumidityLevel(this.label, this.range);
}

/// Enum para la cantidad de agua
enum WateringAmount {
  low('Poco', 'Pequeñas cantidades'),
  medium('Medio', 'Cantidad moderada'),
  high('Mucho', 'Riego abundante');

  final String label;
  final String description;
  const WateringAmount(this.label, this.description);
}

/// Enum para categorías de plantas
enum PlantCategory {
  indoor('Interior'),
  outdoor('Exterior'),
  succulent('Suculenta'),
  flower('Flor'),
  herb('Hierba'),
  tree('Árbol'),
  cactus('Cactus');

  final String label;
  const PlantCategory(this.label);
}