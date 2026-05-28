import 'dart:async';
import 'package:plantcare/core/utils/notification_service.dart';
import 'package:plantcare/domain/entities/plant.dart';
import 'dart:developer' as developer;

/// Servicio que verifica periódicamente plantas que necesitan riego y envía notificaciones
class WateringReminderService {
  static final WateringReminderService _instance = WateringReminderService._internal();
  factory WateringReminderService() => _instance;
  WateringReminderService._internal();

  Timer? _timer;
  bool _isActive = false;
  final Duration _checkInterval = const Duration(hours: 1);

  /// Inicia el servicio de recordatorio de riego
  void startService() {
    if (_isActive) {
      developer.log('🔄 Servicio de recordatorios ya está activo', name: 'WateringReminder');
      return;
    }

    _isActive = true;
    developer.log('✅ Iniciando servicio de recordatorios de riego', name: 'WateringReminder');

    // Ejecutar verificación inmediatamente
    _checkWateringNeeds();

    // Ejecutar verificación periódicamente
    _timer = Timer.periodic(_checkInterval, (_) {
      _checkWateringNeeds();
    });
  }

  /// Detiene el servicio de recordatorio de riego
  void stopService() {
    _timer?.cancel();
    _isActive = false;
    developer.log('🛑 Servicio de recordatorios detenido', name: 'WateringReminder');
  }

  /// Verifica si el servicio está activo
  bool get isActive => _isActive;

  /// Verifica manualmente las plantas que necesitan riego
  Future<void> checkNow() async {
    developer.log('🔍 Verificación manual de riego iniciada', name: 'WateringReminder');
    await _checkWateringNeeds();
  }

  /// Verifica plantas que necesitan riego y envía notificaciones
  Future<void> _checkWateringNeeds() async {
    try {
      developer.log('🌿 Verificando plantas que necesitan riego...', name: 'WateringReminder');

      // Esta función será llamada desde el PlantProvider
      // que tiene acceso a la lista de plantas del usuario actual
      developer.log('⏰ Verificación de riego completada', name: 'WateringReminder');
    } catch (e) {
      developer.log('❌ Error en verificación de riego: $e', name: 'WateringReminder');
    }
  }

  /// Verifica una planta y envía notificación si es necesario
  Future<void> checkPlantAndNotify(Plant plant) async {
    if (!plant.notificationsEnabled || plant.nextWatering == null) {
      return;
    }

    final now = DateTime.now();
    final nextWateringTime = plant.nextWatering!;

    // Si ya pasó la hora de riego
    if (now.isAfter(nextWateringTime)) {
      developer.log(
        '💧 ${plant.name} necesita riego (lastWatering: ${plant.lastWatered}, next: $nextWateringTime)',
        name: 'WateringReminder',
      );

      // Enviar notificación
      await NotificationService().showNotification(
        title: '💧 Hora de regar ${plant.name}',
        body: 'Tu ${plant.name} necesita agua. Cantidad: ${plant.wateringAmountDisplay}',
        payload: plant.id,
      );
    }
  }

  /// Verifica múltiples plantas y envía notificaciones
  Future<void> checkPlantsAndNotify(List<Plant> plants) async {
    developer.log(
      '🔍 Verificando ${plants.length} plantas para riego...',
      name: 'WateringReminder',
    );

    int notificationsSent = 0;
    for (final plant in plants) {
      if (plant.notificationsEnabled && plant.nextWatering != null) {
        final now = DateTime.now();
        if (now.isAfter(plant.nextWatering!)) {
          developer.log(
            '💧 Enviando notificación para ${plant.name}',
            name: 'WateringReminder',
          );

          await NotificationService().showNotification(
            title: '💧 Hora de regar ${plant.name}',
            body: 'Tu ${plant.name} necesita agua. Cantidad: ${plant.wateringAmountDisplay}',
            payload: plant.id,
          );

          notificationsSent++;
        }
      }
    }

    if (notificationsSent > 0) {
      developer.log(
        '✅ Se enviaron $notificationsSent notificación(es) de riego',
        name: 'WateringReminder',
      );
    }
  }

  /// Limpia recursos
  void dispose() {
    stopService();
  }
}
