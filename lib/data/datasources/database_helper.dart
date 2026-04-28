import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:plantcare/domain/entities/enums.dart';
import 'package:plantcare/domain/entities/catalog_plant.dart';

/// Clase para gestionar la base de datos SQLite
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('plantcare.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabla de plantas del usuario
    await db.execute('''
      CREATE TABLE plants (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        species TEXT,
        imagePath TEXT,
        location TEXT,
        lightRequirement INTEGER NOT NULL,
        wateringFrequency INTEGER NOT NULL,
        wateringAmount INTEGER NOT NULL,
        minTemp REAL NOT NULL,
        maxTemp REAL NOT NULL,
        humidityLevel INTEGER NOT NULL,
        lastWatered INTEGER,
        nextWatering INTEGER,
        lastSunExposure INTEGER,
        notificationsEnabled INTEGER NOT NULL DEFAULT 1,
        createdAt INTEGER NOT NULL,
        notes TEXT,
        catalogPlantId TEXT
      )
    ''');

    // Tabla de catálogo de plantas
    await db.execute('''
      CREATE TABLE catalog_plants (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        scientificName TEXT NOT NULL,
        category INTEGER NOT NULL,
        description TEXT NOT NULL,
        lightRequirement INTEGER NOT NULL,
        wateringFrequency INTEGER NOT NULL,
        wateringAmount INTEGER NOT NULL,
        minTemp REAL NOT NULL,
        maxTemp REAL NOT NULL,
        humidityLevel INTEGER NOT NULL,
        careTips TEXT NOT NULL,
        imageUrl TEXT
      )
    ''');

    // Insertar plantas predefinidas en el catálogo
    await _insertDefaultCatalogPlants(db);
  }

  Future<void> _insertDefaultCatalogPlants(Database db) async {
    final defaultPlants = [
      CatalogPlant(
        id: 'cat_001',
        name: 'Monstera',
        scientificName: 'Monstera deliciosa',
        category: PlantCategory.indoor,
        description: 'Planta tropical de interior muy popular, conocida por sus hojas grandes con agujeros característicos.',
        lightRequirement: LightRequirement.medium,
        wateringFrequency: WateringFrequency.weekly,
        wateringAmount: WateringAmount.medium,
        minTemp: 15,
        maxTemp: 30,
        humidityLevel: HumidityLevel.high,
        careTips: 'Limpia las hojas regularmente. Necesita soporte para trepar. Riégala cuando la tierra esté seca.',
      ),
      CatalogPlant(
        id: 'cat_002',
        name: 'Sansevieria',
        scientificName: 'Sansevieria trifasciata',
        category: PlantCategory.indoor,
        description: 'Planta muy resistente, conocida como lengua de tigre o espada de San Jorge. Purifica el aire.',
        lightRequirement: LightRequirement.low,
        wateringFrequency: WateringFrequency.biweekly,
        wateringAmount: WateringAmount.low,
        minTemp: 10,
        maxTemp: 35,
        humidityLevel: HumidityLevel.low,
        careTips: 'Tolera neglecto. No regar en exceso. Perfecta para principiantes.',
      ),
      CatalogPlant(
        id: 'cat_003',
        name: 'Pothos',
        scientificName: 'Epipremnum aureum',
        category: PlantCategory.indoor,
        description: 'Planta colgante muy fácil de cuidar. Perfecta para principiantes y purifica el aire.',
        lightRequirement: LightRequirement.low,
        wateringFrequency: WateringFrequency.weekly,
        wateringAmount: WateringAmount.medium,
        minTemp: 15,
        maxTemp: 30,
        humidityLevel: HumidityLevel.medium,
        careTips: 'Pode las enredaderas largas. Tolera poca luz. Riégala cuando las hojas se vean ligeramente marchitas.',
      ),
      CatalogPlant(
        id: 'cat_004',
        name: 'Aloe Vera',
        scientificName: 'Aloe barbadensis miller',
        category: PlantCategory.succulent,
        description: 'Planta suculenta medicinal conocida por sus propiedades calmantes y regeneradoras.',
        lightRequirement: LightRequirement.high,
        wateringFrequency: WateringFrequency.biweekly,
        wateringAmount: WateringAmount.low,
        minTemp: 10,
        maxTemp: 30,
        humidityLevel: HumidityLevel.low,
        careTips: 'Necesita mucho sol. Dejar secar la tierra entre riegos. No regar en exceso.',
      ),
      CatalogPlant(
        id: 'cat_005',
        name: 'Ficus Lyrata',
        scientificName: 'Ficus lyrata',
        category: PlantCategory.indoor,
        description: 'Árbol de interior con grandes hojas en forma de violín. Muy decorativo.',
        lightRequirement: LightRequirement.high,
        wateringFrequency: WateringFrequency.weekly,
        wateringAmount: WateringAmount.medium,
        minTemp: 15,
        maxTemp: 25,
        humidityLevel: HumidityLevel.medium,
        careTips: 'No mover una vez ubicada. Pulverizar las hojas. Evitar corrientes de aire.',
      ),
      CatalogPlant(
        id: 'cat_006',
        name: 'Espatifilo',
        scientificName: 'Spathiphyllum',
        category: PlantCategory.indoor,
        description: 'Planta de interior con flores blancas. Excelente purificador de aire.',
        lightRequirement: LightRequirement.low,
        wateringFrequency: WateringFrequency.weekly,
        wateringAmount: WateringAmount.high,
        minTemp: 18,
        maxTemp: 28,
        humidityLevel: HumidityLevel.high,
        careTips: 'Mantener tierra húmeda. Pulverizar regularmente. Florece con luz indirecta.',
      ),
      CatalogPlant(
        id: 'cat_007',
        name: 'Cactus',
        scientificName: 'Cactaceae',
        category: PlantCategory.cactus,
        description: 'Plantas adaptadas a climas secos que almacenan agua en su tejido.',
        lightRequirement: LightRequirement.direct,
        wateringFrequency: WateringFrequency.monthly,
        wateringAmount: WateringAmount.low,
        minTemp: 5,
        maxTemp: 40,
        humidityLevel: HumidityLevel.low,
        careTips: 'Mucho sol, poco agua. Asegurar drenaje. No regar en invierno.',
      ),
      CatalogPlant(
        id: 'cat_008',
        name: 'Lavanda',
        scientificName: 'Lavandula',
        category: PlantCategory.herb,
        description: 'Planta aromática con flores moradas perfumadas. Ideal para exteriores.',
        lightRequirement: LightRequirement.direct,
        wateringFrequency: WateringFrequency.weekly,
        wateringAmount: WateringAmount.low,
        minTemp: -5,
        maxTemp: 35,
        humidityLevel: HumidityLevel.low,
        careTips: 'Necesita sol directo. Podar después de floración. Resistente a sequías.',
      ),
      CatalogPlant(
        id: 'cat_009',
        name: 'Rosa',
        scientificName: 'Rosa',
        category: PlantCategory.flower,
        description: 'Flor clásica conocida por su belleza y fragancia. Requiere cuidados específicos.',
        lightRequirement: LightRequirement.direct,
        wateringFrequency: WateringFrequency.everyTwoDays,
        wateringAmount: WateringAmount.medium,
        minTemp: 0,
        maxTemp: 30,
        humidityLevel: HumidityLevel.medium,
        careTips: 'Podar en invierno. Fertilizar en primavera. Controlar plagas.',
      ),
      CatalogPlant(
        id: 'cat_010',
        name: 'Hortensia',
        scientificName: 'Hydrangea',
        category: PlantCategory.flower,
        description: 'Planta con grandes flores en esferas. El color depende del pH del suelo.',
        lightRequirement: LightRequirement.medium,
        wateringFrequency: WateringFrequency.everyTwoDays,
        wateringAmount: WateringAmount.high,
        minTemp: 5,
        maxTemp: 25,
        humidityLevel: HumidityLevel.high,
        careTips: 'Mantener suelo húmedo. Cambiar color con sulfato de aluminio. sombra parcial.',
      ),
      CatalogPlant(
        id: 'cat_011',
        name: 'Bonsái',
        scientificName: 'Various',
        category: PlantCategory.tree,
        description: 'Árbol miniaturizado cultivado en maceta. Arte tradicional japonés.',
        lightRequirement: LightRequirement.medium,
        wateringFrequency: WateringFrequency.everyTwoDays,
        wateringAmount: WateringAmount.medium,
        minTemp: 5,
        maxTemp: 30,
        humidityLevel: HumidityLevel.medium,
        careTips: 'Regar cuando la superficie esté seca. Podar regularmente. Necesita luz.',
      ),
      CatalogPlant(
        id: 'cat_012',
        name: 'Romero',
        scientificName: 'Rosmarinus officinalis',
        category: PlantCategory.herb,
        description: 'Hierba aromática mediterránea muy usada en cocina.',
        lightRequirement: LightRequirement.direct,
        wateringFrequency: WateringFrequency.weekly,
        wateringAmount: WateringAmount.low,
        minTemp: -10,
        maxTemp: 35,
        humidityLevel: HumidityLevel.low,
        careTips: 'Sol directo obligatorio. Resistente a sequías. Podar para mantener forma.',
      ),
      CatalogPlant(
        id: 'cat_013',
        name: 'Calathea',
        scientificName: 'Calathea',
        category: PlantCategory.indoor,
        description: 'Planta de interior con hojas muy decorativas y patrones únicos.',
        lightRequirement: LightRequirement.medium,
        wateringFrequency: WateringFrequency.weekly,
        wateringAmount: WateringAmount.medium,
        minTemp: 18,
        maxTemp: 28,
        humidityLevel: HumidityLevel.high,
        careTips: 'Alta humedad esencial. No exponer al sol directo. Hojas sensibles al cloro.',
      ),
      CatalogPlant(
        id: 'cat_014',
        name: 'Suculenta',
        scientificName: 'Various',
        category: PlantCategory.succulent,
        description: 'Plantas que almacenan agua en sus hojas. Muy fáciles de cuidar.',
        lightRequirement: LightRequirement.high,
        wateringFrequency: WateringFrequency.biweekly,
        wateringAmount: WateringAmount.low,
        minTemp: 5,
        maxTemp: 35,
        humidityLevel: HumidityLevel.low,
        careTips: 'Mucha luz, poco agua. Tierra con drenaje. Evitar agua en las hojas.',
      ),
      CatalogPlant(
        id: 'cat_015',
        name: 'Orquídea',
        scientificName: 'Phalaenopsis',
        category: PlantCategory.flower,
        description: 'Flor exótica elegante. La orquídea más común para interior.',
        lightRequirement: LightRequirement.medium,
        wateringFrequency: WateringFrequency.weekly,
        wateringAmount: WateringAmount.low,
        minTemp: 15,
        maxTemp: 30,
        humidityLevel: HumidityLevel.medium,
        careTips: 'Luz indirecta. Regar por inmersión. No fertilizar en floración.',
      ),
    ];

    for (final plant in defaultPlants) {
      await db.insert('catalog_plants', plant.toMap());
    }
  }

  // ============ OPERACIONES DE PLANTAS DEL USUARIO ============

  Future<int> insertPlant(Map<String, dynamic> plant) async {
    final db = await database;
    return await db.insert('plants', plant);
  }

  Future<List<Map<String, dynamic>>> getAllPlants() async {
    final db = await database;
    return await db.query('plants', orderBy: 'createdAt DESC');
  }

  Future<Map<String, dynamic>?> getPlantById(String id) async {
    final db = await database;
    final result = await db.query(
      'plants',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updatePlant(Map<String, dynamic> plant) async {
    final db = await database;
    return await db.update(
      'plants',
      plant,
      where: 'id = ?',
      whereArgs: [plant['id']],
    );
  }

  Future<int> deletePlant(String id) async {
    final db = await database;
    return await db.delete(
      'plants',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ OPERACIONES DEL CATÁLOGO ============

  Future<List<Map<String, dynamic>>> getAllCatalogPlants() async {
    final db = await database;
    return await db.query('catalog_plants', orderBy: 'name ASC');
  }

  Future<List<Map<String, dynamic>>> getCatalogPlantsByCategory(int categoryIndex) async {
    final db = await database;
    return await db.query(
      'catalog_plants',
      where: 'category = ?',
      whereArgs: [categoryIndex],
      orderBy: 'name ASC',
    );
  }

  Future<List<Map<String, dynamic>>> searchCatalogPlants(String query) async {
    final db = await database;
    return await db.query(
      'catalog_plants',
      where: 'name LIKE ? OR scientificName LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
  }

  Future<Map<String, dynamic>?> getCatalogPlantById(String id) async {
    final db = await database;
    final result = await db.query(
      'catalog_plants',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // ============ BÚSQUEDA POR CRITERIOS (PARA QUIZ) ============

  Future<List<Map<String, dynamic>>> searchCatalogByCriteria({
    List<int>? lightRequirements,
    List<int>? wateringFrequencies,
    List<int>? humidityLevels,
    List<int>? categories,
  }) async {
    final db = await database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (lightRequirements != null && lightRequirements.isNotEmpty) {
      whereClause += ' AND lightRequirement IN (${lightRequirements.map((_) => '?').join(',')})';
      whereArgs.addAll(lightRequirements);
    }

    if (wateringFrequencies != null && wateringFrequencies.isNotEmpty) {
      whereClause += ' AND wateringFrequency IN (${wateringFrequencies.map((_) => '?').join(',')})';
      whereArgs.addAll(wateringFrequencies);
    }

    if (humidityLevels != null && humidityLevels.isNotEmpty) {
      whereClause += ' AND humidityLevel IN (${humidityLevels.map((_) => '?').join(',')})';
      whereArgs.addAll(humidityLevels);
    }

    if (categories != null && categories.isNotEmpty) {
      whereClause += ' AND category IN (${categories.map((_) => '?').join(',')})';
      whereArgs.addAll(categories);
    }

    return await db.query(
      'catalog_plants',
      where: whereClause,
      whereArgs: whereArgs,
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}