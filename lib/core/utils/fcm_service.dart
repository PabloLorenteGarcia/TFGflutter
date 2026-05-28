import 'dart:developer' as developer;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para gestionar Firebase Cloud Messaging (FCM)
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _isInitialized = false;

  /// Inicializa el servicio FCM
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      developer.log('📱 Inicializando Firebase Cloud Messaging...', name: 'FCMService');

      // Solicitar permisos de notificaciones
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      developer.log(
        '🔔 Permisos de notificaciones: ${settings.authorizationStatus}',
        name: 'FCMService',
      );

      // Obtener token inicial y guardarlo
      final token = await _messaging.getToken();
      if (token != null) {
        developer.log('✅ FCM Token obtenido: ${token.substring(0, 20)}...', name: 'FCMService');
        await _saveFCMToken(token);
      } else {
        developer.log('⚠️ No se pudo obtener FCM token', name: 'FCMService');
      }

      // Escuchar cambios de token (se regenera periódicamente)
      _messaging.onTokenRefresh.listen((newToken) {
        developer.log('🔄 Nuevo FCM Token: ${newToken.substring(0, 20)}...', name: 'FCMService');
        _saveFCMToken(newToken);
      });

      // Configurar handlers para mensajes
      _setupMessageHandlers();

      _isInitialized = true;
      developer.log('✅ Firebase Cloud Messaging inicializado correctamente', name: 'FCMService');
    } catch (e) {
      developer.log('❌ Error al inicializar FCM: $e', name: 'FCMService');
    }
  }

  /// Guarda el token FCM del usuario en Firestore
  Future<void> _saveFCMToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .update({
              'fcmToken': token,
              'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
            }).catchError((error) async {
              // Si el documento no existe, créalo
              if (error.code == 'not-found' || error.toString().contains('not-found')) {
                await FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(user.uid)
                    .set({
                      'fcmToken': token,
                      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));
                developer.log(
                  '✅ Documento de usuario creado con FCM token',
                  name: 'FCMService',
                );
              } else {
                throw error;
              }
            });

        developer.log(
          '💾 FCM Token guardado en Firestore para usuario: $user.uid}',
          name: 'FCMService',
        );
      }
    } catch (e) {
      developer.log('❌ Error al guardar FCM token: $e', name: 'FCMService');
    }
  }

  /// Configura los handlers para mensajes FCM
  void _setupMessageHandlers() {
    // Mensajes en foreground (app abierta)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log(
        '📬 Mensaje recibido en foreground: ${message.notification?.title}',
        name: 'FCMService',
      );

      if (message.notification != null) {
        _handleNotificationTap(message);
      }
    });

    // Mensajes cuando se toca la notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log(
        '📬 App abierta desde notificación: ${message.notification?.title}',
        name: 'FCMService',
      );
      _handleNotificationTap(message);
    });

    // Mensajes en background (procesados por el sistema)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Manejador para el tap en notificación
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    final plantId = message.data['plantId'];
    developer.log('🪴 Notificación de planta: $plantId', name: 'FCMService');
    
    // Aquí se puede agregar lógica para navegar a la planta específica
    // Por ejemplo, usar GoRouter para navegar a la pantalla de detalles de la planta
  }
}

/// Handler para mensajes en background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log(
    '📬 Mensaje recibido en background: ${message.notification?.title}',
    name: 'FCMService-Background',
  );
}
