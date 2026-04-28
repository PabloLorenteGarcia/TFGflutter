import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:plantcare/core/constants/firebase_options.dart';
import 'package:plantcare/domain/entities/catalog_plant.dart';
import 'package:plantcare/domain/entities/enums.dart';

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
    final snapshot = await db.collection('plants').get();
    return snapshot.docs.map((doc) => _catalogPlantFromFirestore(doc)).toList();
  }

  /// Obtiene plantas por categoría
  Future<List<CatalogPlant>> getPlantsByCategory(PlantCategory category) async {
    final db = await firestore;
    final snapshot = await db
        .collection('plants')
        .where('category', isEqualTo: category.index)
        .get();
    return snapshot.docs.map((doc) => _catalogPlantFromFirestore(doc)).toList();
  }

  /// Busca plantas por nombre
  Future<List<CatalogPlant>> searchPlants(String query) async {
    final db = await firestore;
    final snapshot = await db
        .collection('plants')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .get();
    return snapshot.docs.map((doc) => _catalogPlantFromFirestore(doc)).toList();
  }

  /// Obtiene una planta por su ID
  Future<CatalogPlant?> getPlantById(String id) async {
    final db = await firestore;
    final doc = await db.collection('plants').doc(id).get();
    if (!doc.exists) return null;
    return _catalogPlantFromFirestore(doc);
  }

  /// Agrega una planta al catálogo
  Future<void> addPlant(CatalogPlant plant) async {
    final db = await firestore;
    await db.collection('plants').doc(plant.id).set(plant.toMap());
  }

  /// Agrega múltiples plantas al catálogo
  Future<void> addPlants(List<CatalogPlant> plants) async {
    final db = await firestore;
    final batch = db.batch();
    for (final plant in plants) {
      final docRef = db.collection('plants').doc(plant.id);
      batch.set(docRef, plant.toMap());
    }
    await batch.commit();
  }

  /// Actualiza una planta del catálogo
  Future<void> updatePlant(CatalogPlant plant) async {
    final db = await firestore;
    await db.collection('plants').doc(plant.id).update(plant.toMap());
  }

  /// Elimina una planta del catálogo
  Future<void> deletePlant(String id) async {
    final db = await firestore;
    await db.collection('plants').doc(id).delete();
  }

  // ==================== PLANTAS DEL USUARIO ====================

  /// Obtiene la colección de plantas de un usuario específico
  CollectionReference _getUserPlantsCollection(String userId) {
    return _firestore!.collection('users').doc(userId).collection('plants');
  }

  /// Obtiene todas las plantas de un usuario
  Future<List<Plant>> getUserPlants(String userId) async {
    final snapshot = await _getUserPlantsCollection(userId).get();
    return snapshot.docs.map((doc) => _plantFromFirestore(doc)).toList();
  }

  /// Agrega una planta al usuario
  Future<void> addUserPlant(String userId, Plant plant) async {
    await _getUserPlantsCollection(userId).doc(plant.id).set(plant.toMap());
  }

  /// Actualiza una planta del usuario
  Future<void> updateUserPlant(String userId, Plant plant) async {
    await _getUserPlantsCollection(userId).doc(plant.id).update(plant.toMap());
  }

  /// Elimina una planta del usuario
  Future<void> deleteUserPlant(String userId, String plantId) async {
    await _getUserPlantsCollection(userId).doc(plantId).delete();
  }

  /// Obtiene una planta específica del usuario
  Future<Plant?> getUserPlantById(String userId, String plantId) async {
    final doc = await _getUserPlantsCollection(userId).doc(plantId).get();
    if (!doc.exists) return null;
    return _plantFromFirestore(doc);
  }

  // ==================== HELPERS ====================

  /// Convierte un documento de Firestore a Plant del usuario
  Plant _plantFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Plant(
      id: data['id'] as String,
      name: data['name'] as String,
      species: data['species'] as String?,
      imagePath: data['imagePath'] as String?,
      location: data['location'] as String?,
      lightRequirement: LightRequirement.values[data['lightRequirement'] as int],
      wateringFrequency: WateringFrequency.values[data['wateringFrequency'] as int],
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
      lightRequirement: LightRequirement.values[data['lightRequirement'] as int],
      wateringFrequency: WateringFrequency.values[data['wateringFrequency'] as int],
      wateringAmount: WateringAmount.values[data['wateringAmount'] as int],
      minTemp: (data['minTemp'] as num).toDouble(),
      maxTemp: (data['maxTemp'] as num).toDouble(),
      humidityLevel: HumidityLevel.values[data['humidityLevel'] as int],
      careTips: data['careTips'] as String,
      imageUrl: data['imageUrl'] as String?,
    );
  }
}