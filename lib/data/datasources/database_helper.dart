import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:plantcare/core/constants/plant_catalog_data.dart';
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

    final db = await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );

    await _ensureDefaultCatalogPlants(db);
    return db;
  }

  Future<void> _ensureDefaultCatalogPlants(Database db) async {
    final defaultPlants = PlantCatalogData.getDefaultPlants();
    final existingRows = await db.query('catalog_plants', columns: ['id']);
    final existingIds = existingRows.map((row) => row['id'] as String).toSet();

    final missingPlants = defaultPlants.where((plant) => !existingIds.contains(plant.id)).toList();
    if (missingPlants.isNotEmpty) {
      for (final plant in missingPlants) {
        await db.insert('catalog_plants', plant.toMap());
      }
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE plants ADD COLUMN userId TEXT');
    }

    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE plants ADD COLUMN wateringAmountLiters REAL NOT NULL DEFAULT 1.0',
      );
      await db.execute('''
        UPDATE plants
        SET wateringAmountLiters = CASE wateringAmount
          WHEN 0 THEN 0.5
          WHEN 1 THEN 1.0
          ELSE 2.0
        END
      ''');
    }
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
        wateringAmountLiters REAL NOT NULL DEFAULT 1.0,
        minTemp REAL NOT NULL,
        maxTemp REAL NOT NULL,
        humidityLevel INTEGER NOT NULL,
        lastWatered INTEGER,
        nextWatering INTEGER,
        lastSunExposure INTEGER,
        notificationsEnabled INTEGER NOT NULL DEFAULT 1,
        createdAt INTEGER NOT NULL,
        notes TEXT,
        catalogPlantId TEXT,
      userId TEXT
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
    final List<CatalogPlant> defaultPlants = PlantCatalogData.getDefaultPlants();

    for (final plant in defaultPlants) {
      await db.insert('catalog_plants', plant.toMap());
    }
  }

  // ============ OPERACIONES DE PLANTAS DEL USUARIO ============

  Future<int> insertPlant(Map<String, dynamic> plant) async {
    final db = await database;
    return await db.insert(
      'plants',
      plant,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllPlants({String? userId}) async {
    final db = await database;

    if (userId == null) {
      return await db.query(
        'plants',
        where: 'userId IS NULL',
        orderBy: 'createdAt DESC',
      );
    }

    return await db.query(
      'plants',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
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