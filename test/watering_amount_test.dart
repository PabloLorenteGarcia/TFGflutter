import 'package:flutter_test/flutter_test.dart';
import 'package:plantcare/domain/entities/enums.dart';
import 'package:plantcare/domain/entities/plant.dart';

void main() {
  test('WateringAmount.fromLiters normaliza el valor y clampa correctamente', () {
    expect(WateringAmount.fromLiters(0.2), WateringAmount.low);
    expect(WateringAmount.fromLiters(1.4), WateringAmount.medium);
    expect(WateringAmount.fromLiters(3.0), WateringAmount.high);
  });

  test('Plant presenta la cantidad de agua en litros', () {
    final plant = Plant(
      id: '1',
      name: 'Test',
      lightRequirement: LightRequirement.medium,
      wateringFrequency: WateringFrequency.weekly,
      wateringAmount: WateringAmount.low,
      wateringAmountLiters: 1.5,
      minTemp: 15,
      maxTemp: 25,
      humidityLevel: HumidityLevel.medium,
      createdAt: DateTime(2024, 1, 1),
    );

    expect(plant.wateringAmountDisplay, '1.5 L');
  });

  test('El formato de litros conserva valores como 0.5', () {
    expect(WateringAmount.low.litersLabel, '0.5 L');
  });
}
