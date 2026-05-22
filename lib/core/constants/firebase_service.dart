import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plantcare/domain/entities/catalog_plant.dart';
import 'package:plantcare/domain/entities/enums.dart';
import 'package:plantcare/domain/entities/plant.dart';

/// Servicio para gestionar Firebase Firestore
class FirebaseService {
  static final FirebaseService instance = FirebaseService._init();
  static FirebaseFirestore? _firestore;

  FirebaseService._init();

  /// Inicializa Firebase y retorna la instancia de Firestore
  Future<FirebaseFirestore> get firestore async {
    if (_firestore != null) return _firestore!;
    _firestore = FirebaseFirestore.instance;
    return _firestore!;
  }

  /// Inicializa Firebase Core
  static Future<void> initialize() async {
    // ignore: invalid_use_of_visible_for_testing_member
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  /// Obtiene todas las plantas del catálogo desde Firestore
  Future<List<CatalogPlant>> getAllPlants() async {
    final db = await firestore;
    final snapshot = await db.collection('catalog_plants').get();
    return snapshot.docs.map((doc) => _catalogPlantFromFirestore(doc)).toList();
  }

  /// Obtiene plantas por categoría
  Future<List<CatalogPlant>> getPlantsByCategory(PlantCategory category) async {
    final db = await firestore;
    final snapshot = await db
        .collection('catalog_plants')
        .where('category', isEqualTo: category.index)
        .get();
    return snapshot.docs.map((doc) => _catalogPlantFromFirestore(doc)).toList();
  }

  /// Busca plantas por nombre
  Future<List<CatalogPlant>> searchPlants(String query) async {
    final db = await firestore;
    final snapshot = await db
        .collection('catalog_plants')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .get();
    return snapshot.docs.map((doc) => _catalogPlantFromFirestore(doc)).toList();
  }

  /// Obtiene una planta por su ID
  Future<CatalogPlant?> getPlantById(String id) async {
    final db = await firestore;
    final doc = await db.collection('catalog_plants').doc(id).get();
    if (!doc.exists) return null;
    return _catalogPlantFromFirestore(doc);
  }

  /// Agrega una planta al catálogo
  Future<void> addPlant(CatalogPlant plant) async {
    final db = await firestore;
    await db.collection('catalog_plants').doc(plant.id).set(plant.toMap());
  }

  /// Agrega múltiples plantas al catálogo
  Future<void> addPlants(List<CatalogPlant> plants) async {
    final db = await firestore;
    final batch = db.batch();
    for (final plant in plants) {
      final docRef = db.collection('catalog_plants').doc(plant.id);
      batch.set(docRef, plant.toMap());
    }
    await batch.commit();
  }

  /// Actualiza una planta del catálogo
  Future<void> updatePlant(CatalogPlant plant) async {
    final db = await firestore;
    await db.collection('catalog_plants').doc(plant.id).update(plant.toMap());
  }

  /// Elimina una planta del catálogo
  Future<void> deletePlant(String id) async {
    final db = await firestore;
    await db.collection('catalog_plants').doc(id).delete();
  }

  /// Crea o actualiza el documento del usuario en Firestore usando su UID
  Future<void> createUserDocument(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final db = await firestore;
    await db.collection('users').doc(userId).set(data, SetOptions(merge: true));
  }

  /// Asegura que el documento de usuario existe en Firestore
  Future<void> ensureUserDocument(String userId, {String? email}) async {
    final db = await firestore;
    await db.collection('usuarios').doc(userId).set({
      if (email != null) 'email': email,
    }, SetOptions(merge: true));
  }

  // ==================== PLANTAS DEL USUARIO ====================

  /// Obtiene todas las plantas de un usuario desde la subcolección `plantas`
  Future<List<Plant>> getUserPlants(String userId) async {
    try {
      final db = await firestore;
      final snapshot = await db
          .collection('usuarios')
          .doc(userId)
          .collection('plantas')
          .get();

      final plants = snapshot.docs
          .map((doc) => _plantFromFirestore(doc, userId))
          .toList();

      if (plants.isNotEmpty) return plants;

      // Si no hay plantas en la subcolección, intentar migrar desde el campo antiguo `plantas`.
      final userDoc = await db.collection('usuarios').doc(userId).get();
      if (!userDoc.exists) return [];
      final data = userDoc.data() as Map<String, dynamic>?;
      final oldPlantas = data?['plantas'] as Map<String, dynamic>?;
      if (oldPlantas == null) return [];

      return oldPlantas.entries
          .map(
            (entry) => _plantFromMap(
              Map<String, dynamic>.from(entry.value as Map),
              userId,
            ),
          )
          .toList();
    } catch (e) {
      print('Error al obtener plantas del usuario: $e');
      rethrow;
    }
  }

  /// Agrega una planta al usuario usando la subcolección `plantas`
  Future<void> addUserPlant(String userId, Plant plant) async {
    print('🌱 INICIANDO: Guardar planta - userId: $userId, plantId: ${plant.id}');
    
    if (userId.isEmpty) {
      throw Exception('❌ Error: userId está vacío. Usuario no autenticado.');
    }

    final db = await firestore;
    final plantData = plant.toFirestoreMap()..['userId'] = userId;
    
    print('📦 Datos a guardar: ${plantData.keys.toList()}');

    // Asegurar que el documento de usuario existe
    try {
      print('👤 Creando/verificando documento de usuario...');
      await ensureUserDocument(userId);
      print('✅ Documento de usuario verificado');
    } catch (e) {
      print('❌ Error al verificar documento de usuario: $e');
      rethrow;
    }

    // Guardar en la subcolección del usuario
    try {
      print('💾 Guardando en: usuarios/$userId/plantas/${plant.id}');
      await db
          .collection('usuarios')
          .doc(userId)
          .collection('plantas')
          .doc(plant.id)
          .set(plantData, SetOptions(merge: true));
      print('✅ Planta guardada en subcolección exitosamente');
    } catch (e) {
      print('❌ Error al guardar planta en subcolección: $e');
      rethrow;
    }

    // Guardar también en la colección global de plantas (opcional)
    try {
      print('💾 Guardando en colección global: plants/${plant.id}');
      await db
          .collection('plants')
          .doc(plant.id)
          .set(plantData, SetOptions(merge: true));
      print('✅ Planta guardada en colección global');
    } catch (e) {
      print('⚠️ Advertencia: Error al guardar en colección global: $e');
      // No relanzar aquí para no bloquear si falla la colección global
    }
  }

  /// Actualiza una planta del usuario en la subcolección `plantas`
  Future<void> updateUserPlant(String userId, Plant plant) async {
    final db = await firestore;
    final plantData = plant.toFirestoreMap()..['userId'] = userId;

    try {
      await db
          .collection('usuarios')
          .doc(userId)
          .collection('plantas')
          .doc(plant.id)
          .set(plantData, SetOptions(merge: true));
    } catch (e) {
      print('Error al actualizar planta en la subcolección del usuario: $e');
    }

    try {
      await db
          .collection('plants')
          .doc(plant.id)
          .set(plantData, SetOptions(merge: true));
    } catch (e) {
      print('Error al actualizar planta en la colección global: $e');
      rethrow;
    }
  }

  /// Elimina una planta del usuario de la subcolección `plantas`
  Future<void> deleteUserPlant(String userId, String plantId) async {
    final db = await firestore;

    try {
      await db
          .collection('usuarios')
          .doc(userId)
          .collection('plantas')
          .doc(plantId)
          .delete();
    } catch (e) {
      print('Error al eliminar planta de la subcolección del usuario: $e');
    }

    try {
      await db.collection('plants').doc(plantId).delete();
    } catch (e) {
      print('Error al eliminar planta de la colección global: $e');
      rethrow;
    }
  }

  /// Obtiene una planta específica del usuario desde la subcolección `plantas`
  Future<Plant?> getUserPlantById(String userId, String plantId) async {
    try {
      final db = await firestore;
      final doc = await db
          .collection('usuarios')
          .doc(userId)
          .collection('plantas')
          .doc(plantId)
          .get();
      if (!doc.exists) return null;
      return _plantFromFirestore(doc, userId);
    } catch (e) {
      print('Error al obtener planta: $e');
      rethrow;
    }
  }

  // ==================== HELPERS ====================

  /// Convierte un documento de Firestore a Plant del usuario
  Plant _plantFromFirestore(DocumentSnapshot doc, [String? userId]) {
    final data = doc.data() as Map<String, dynamic>;
    return _plantFromMap(data, userId);
  }

  Plant _plantFromMap(Map<String, dynamic> data, [String? userId]) {
    return Plant(
      id: data['id'] as String,
      name: data['name'] as String,
      species: data['species'] as String?,
      imagePath: data['imagePath'] as String?,
      location: data['location'] as String?,
      lightRequirement:
          LightRequirement.values[data['lightRequirement'] as int],
      wateringFrequency:
          WateringFrequency.values[data['wateringFrequency'] as int],
      wateringAmount: WateringAmount.values[data['wateringAmount'] as int],
      minTemp: (data['minTemp'] as num).toDouble(),
      maxTemp: (data['maxTemp'] as num).toDouble(),
      humidityLevel: HumidityLevel.values[data['humidityLevel'] as int],
      lastWatered: data['lastWatered'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastWatered'] as int)
          : null,
      nextWatering: data['nextWatering'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['nextWatering'] as int)
          : null,
      lastSunExposure: data['lastSunExposure'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastSunExposure'] as int)
          : null,
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
      notes: data['notes'] as String?,
      catalogPlantId: data['catalogPlantId'] as String?,
      userId: userId ?? data['userId'] as String?,
    );
  }

  /// Convierte un documento de Firestore a CatalogPlant
  CatalogPlant _catalogPlantFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CatalogPlant(
      id: data['id'] as String,
      name: data['name'] as String,
      scientificName: data['scientificName'] as String,
      category: PlantCategory.values[data['category'] as int],
      description: data['description'] as String,
      lightRequirement:
          LightRequirement.values[data['lightRequirement'] as int],
      wateringFrequency:
          WateringFrequency.values[data['wateringFrequency'] as int],
      wateringAmount: WateringAmount.values[data['wateringAmount'] as int],
      minTemp: (data['minTemp'] as num).toDouble(),
      maxTemp: (data['maxTemp'] as num).toDouble(),
      humidityLevel: HumidityLevel.values[data['humidityLevel'] as int],
      careTips: data['careTips'] as String,
      imageUrl: data['imageUrl'] as String?,
    );
  }
}
