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
  low('Poco', 'Pequeñas cantidades', 0.5),
  medium('Medio', 'Cantidad moderada', 1.0),
  high('Mucho', 'Riego abundante', 2.0);

  final String label;
  final String description;
  final double liters;
  const WateringAmount(this.label, this.description, this.liters);

  static WateringAmount fromLiters(double liters) {
    final normalized = liters.clamp(0.5, 2.0);
    WateringAmount best = low;
    double bestDiff = double.infinity;

    for (final amount in WateringAmount.values) {
      final diff = (amount.liters - normalized).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = amount;
      }
    }

    return best;
  }

  String get litersLabel => liters == liters.toInt()
      ? '${liters.toInt()} L'
      : liters.toStringAsFixed(2)
              .replaceFirst(RegExp(r'0+$'), '')
              .replaceFirst(RegExp(r'\.$'), '') +
          ' L';
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