# 🔔 Sistema de Notificaciones de Riego - Guía de Configuración

## Cambios Realizados

### 1. ✅ Eliminación de Opción de Foto
- **Archivo modificado**: `lib/presentation/screens/my_plants/add_plant_screen.dart`
- **Cambios**:
  - Removidos imports: `image_picker`, `firebase_storage`, `plant_identification_service`, `dart:io`
  - Eliminadas variables: `_selectedImage`, `_uploadedImageUrl`, `_isUploadingImage`, `_isIdentifyingPlant`
  - Eliminados métodos: `_pickImage()`, `_uploadImage()`, `_identifyPlant()`
  - Removida la sección UI de "Imagen (opcional)"
  - Ahora `imagePath` se establece a `null` al crear plantas

### 2. ✅ Sistema de Notificaciones Automático Creado

#### Flutter Side:
- **Archivo nuevo**: `lib/core/utils/watering_reminder_service.dart`
  - Servicio que verifica periódicamente (cada hora) si hay plantas que necesitan riego
  - Envía notificaciones locales cuando una planta necesita agua
  - Se inicia automáticamente cuando el usuario inicia sesión

- **Cambios en**: `lib/main.dart`
  - Importación de `WateringReminderService`
  - Se inicia el servicio cuando el usuario está autenticado
  - Se limpia el servicio al cerrar la app

- **Cambios en**: `lib/presentation/providers/plant_provider.dart`
  - Importación de `WateringReminderService`
  - Al cargar las plantas, se verifica automáticamente cuáles necesitan riego
  - Se envían notificaciones locales para plantas que necesitan agua

#### Cloud Functions:
- **Archivo nuevo**: `functions/src/watering-reminders.js`
  - **`sendWateringReminders`**: Función scheduled que se ejecuta cada hora
    - Verifica todas las plantas de todos los usuarios
    - Envía notificaciones push (Firebase Cloud Messaging) a usuarios
    - Requiere que los usuarios tengan FCM tokens guardados
  
  - **`checkUserPlants`**: Función callable para verificación manual
    - Permite a los usuarios verificar manualmente qué plantas necesitan riego
    - Retorna lista de plantas que necesitan agua

- **Cambios en**: `functions/src/index.js`
  - Exporta las nuevas funciones de watering reminders

## ⚙️ Pasos para Completar la Configuración

### Paso 1: Configurar Firebase Cloud Messaging (FCM)

#### Para Android:
1. En Firebase Console > Proyecto > Project Settings
2. Ve a "Cloud Messaging" tab
3. Copia el "Server API Key"
4. En `android/app/build.gradle`, asegúrate de tener:
   ```gradle
   dependencies {
     implementation 'com.google.firebase:firebase-messaging'
   }
   ```

#### Para Web (si necesitas):
1. Ve a Firebase Console > Proyecto > Project Settings
2. En "Service Accounts" tab, genera una nueva clave privada
3. Guárdala de forma segura

### Paso 2: Agregar FCM Token a Firestore

Necesitas crear un servicio que guarde el FCM token del usuario en Firestore cuando se autentica.

**Archivo a crear**: `lib/core/utils/fcm_service.dart`

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Solicitar permisos
    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Obtener token y guardarlo
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveFCMToken(token);
    }

    // Escuchar cambios de token
    _messaging.onTokenRefresh.listen((token) {
      _saveFCMToken(token);
    });
  }

  Future<void> _saveFCMToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .update({
            'fcmToken': token,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          })
          .catchError((e) {
            // Si el documento no existe, crear uno
            if (e.code == 'not-found') {
              return FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(user.uid)
                  .set({
                    'fcmToken': token,
                    'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));
            }
            throw e;
          });
    }
  }
}
```

**Luego en `main.dart`, agregaFCMService()**:
```dart
void main() async {
  // ... código existente ...
  
  // Inicializar FCM
  await FCMService().initialize();
  print('✅ FCM inicializado');
  
  runApp(const PlantCareApp());
}
```

### Paso 3: Desplegar Cloud Functions

1. Asegúrate de estar en el directorio `functions/`
2. Ejecuta:
   ```bash
   firebase deploy --only functions
   ```

3. La función `sendWateringReminders` se ejecutará automáticamente cada hora

### Paso 4: Configurar Cloud Scheduler (Opcional pero Recomendado)

Si Firebase no crea automáticamente el Cloud Scheduler:

1. Ve a Google Cloud Console > Cloud Scheduler
2. Crea un nuevo job:
   - **Frequency**: `0 * * * *` (cada hora)
   - **Timezone**: Tu zona horaria preferida
   - **Execution type**: HTTP
   - **URL**: `https://us-central1-{your-project-id}.cloudfunctions.net/sendWateringReminders`
   - **Auth header**: Add OIDC token
   - **Service account email**: `{project-id}@appspot.gserviceaccount.com`

### Paso 5: Actualizar pubspec.yaml

Asegúrate de tener estas dependencias:

```yaml
dependencies:
  flutter_local_notifications: ^17.0.0
  firebase_messaging: ^14.0.0  # Para push notifications
  timezone: ^0.9.0
```

Ejecuta: `flutter pub get`

### Paso 6: Actualizar Reglas de Seguridad de Firestore

Asegúrate de que las Cloud Functions pueden acceder a los documentos de usuarios:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /usuarios/{userId} {
      allow read, write: if request.auth.uid == userId || request.auth.token.firebase.service_account == true;
      
      match /plantas/{plantId} {
        allow read, write: if request.auth.uid == userId || request.auth.token.firebase.service_account == true;
      }
    }
  }
}
```

## 🧪 Pruebas

### Prueba Local:
1. Ejecuta la app: `flutter run`
2. Crea una planta con fecha de riego en el pasado
3. Abre/recarga la app
4. Deberías recibir una notificación local

### Prueba de Cloud Function (Manual):
```bash
firebase functions:call checkUserPlants --region us-central1
```

## 📋 Características del Sistema

### Notificaciones Locales (Flutter):
- ✅ Se verifica cada hora cuando la app está abierta
- ✅ Se verifica al cargar las plantas
- ✅ Mostrada en el dispositivo localmenteDuration automática (1 hora)

### Notificaciones Push (Cloud Messaging):
- ✅ Se ejecuta cada hora en el servidor
- ✅ Funciona incluso si la app está cerrada
- ✅ Enviada a través de Firebase Cloud Messaging

## ⚠️ Importante

1. **Permisos de Notificaciones**: En Android 13+, los usuarios deben dar permiso para notificaciones
2. **FCM Token**: Es crítico que el token FCM se guarde en Firestore
3. **Testing**: Prueba primero en dispositivo antes de desplegar a producción
4. **Zona Horaria**: La Cloud Function usa la zona horaria de US-Eastern por defecto - cámbiala según tus necesidades

## 🐛 Troubleshooting

### No recibo notificaciones:
1. Verifica que `notificationsEnabled` es `true` en la planta
2. Verifica que el FCM token está guardado en Firestore
3. Revisa los logs de Cloud Functions: `firebase functions:log`
4. Verifica permisos de notificaciones en el dispositivo

### Las notificaciones no se envían en la hora correcta:
1. Verifica la zona horaria en Cloud Scheduler
2. Verifica que `nextWatering` está almacenado correctamente en Firestore
3. Comprueba los logs de Cloud Functions

## 📱 Resultado Final

- ❌ Los usuarios NO pueden agregar fotos al crear plantas
- ✅ Reciben notificaciones automáticas cuando sus plantas necesitan riego
- ✅ Notificaciones locales se envían al abrir la app
- ✅ Notificaciones push se envían cada hora del servidor
