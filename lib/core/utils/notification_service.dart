import 'dart:developer' as developer;
import 'dart:ui' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:plantcare/domain/entities/plant.dart';

/// Servicio para gestionar las notificaciones locales
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Inicializa el servicio de notificaciones
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Inicializar timezone
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Solicitar permisos en Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _isInitialized = true;
  }

  /// Callback cuando se toca una notificación
  void _onNotificationTapped(NotificationResponse response) {
    // Aquí se puede navegar a la planta específica
    developer.log('Notificación tocada: ${response.payload}', name: 'PlantCare');
  }

  /// Programa una notificación de riego
  Future<void> scheduleWateringNotification(Plant plant) async {
    if (!plant.notificationsEnabled || plant.nextWatering == null) return;

    final scheduledDate = plant.nextWatering!;
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      plant.id.hashCode,
      '💧 Hora de regar ${plant.name}',
      'Tu ${plant.name} necesita agua hoy',
      _convertToTZDateTime(scheduledDate),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'watering_channel',
          'Recordatorios de Riego',
          channelDescription: 'Notificaciones para el riego de plantas',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF4CAF50),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: plant.id,
    );
  }

  /// Cancela las notificaciones de una planta
  Future<void> cancelPlantNotifications(String plantId) async {
    await _notifications.cancel(plantId.hashCode);
  }

  /// Cancela todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Muestra una notificación inmediata
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'general_channel',
          'Notificaciones Generales',
          channelDescription: 'Notificaciones generales de la app',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload,
    );
  }

  /// Convierte DateTime a TZDateTime
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }
}