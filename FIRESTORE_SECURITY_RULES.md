# Reglas de Seguridad de Firestore para PlantCare

Estas son las reglas recomendadas para asegurar que los datos están protegidos correctamente en Firestore.

## Estructura de datos

```
users/
  {userId}/
    plants/
      {plantId}: {name, species, ..., userId: userId}

plants/
  {plantId}: {name, species, ..., userId: userId}

catalog_plants/
  {catalogPlantId}: {name, scientificName, ...}
```

## Reglas de Firestore

Copia y pega estas reglas en la consola de Firebase → Firestore Database → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Colección de usuarios
    match /users/{userId} {
      // Solo el propietario puede leer su documento
      allow read: if request.auth.uid == userId;
      // Solo el propietario puede escribir
      allow write: if request.auth.uid == userId;
      
      // Subcollección de plantas del usuario
      match /plantas/{plantId} {
        allow read: if request.auth.uid == userId;
        allow write: if request.auth.uid == userId;
      }
    }
    
    // Colección global de plantas
    match /plants/{plantId} {
      // Cualquier usuario autenticado puede leer plantas
      allow read: if request.auth != null;
      // Solo el propietario (userId en el documento) puede escribir
      allow write: if request.auth.uid == resource.data.userId || request.auth.uid == request.resource.data.userId;
    }
    
    // Catálogo de plantas (público, solo lectura)
    match /catalog_plants/{catalogPlantId} {
      allow read: if true; // Público
      allow write: if false; // Solo administradores (cambiar manualmente)
    }
  }
}
```

## Cómo implementar las reglas

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto (plantcare)
3. Ve a Firestore Database → Rules
4. Reemplaza el contenido con las reglas anteriores
5. Haz clic en "Publicar"

## Cambios realizados en el código

✅ **firebase_service.dart:**
- `addUserPlant()` guarda en ambas colecciones: `users/{userId}/plantas/` y `plants/`
- `updateUserPlant()` actualiza ambas colecciones
- `deleteUserPlant()` elimina de ambas colecciones

✅ **add_plant_screen.dart:**
- Obtiene el `userId` del usuario actual
- Asigna explícitamente el `userId` al crear una planta

## Beneficios de esta estructura

1. **Acceso rápido:** Las plantas de un usuario se acceden desde `users/{userId}/plantas/`
2. **Análisis global:** La colección `plants/` permite análisis y consultas globales
3. **Seguridad:** Las reglas aseguran que solo los usuarios autenticados accedan a sus datos
4. **Escalabilidad:** Estructura preparada para crecer sin límites de subcollecciones
