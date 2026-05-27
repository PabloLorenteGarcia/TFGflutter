import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Modelo para representar una especie identificada
class IdentifiedSpecies {
  final String scientificName;
  final String? scientificNameAuthorship;
  final String? genus;
  final String? family;
  final List<String> commonNames;
  final double score;
  final double probability;

  IdentifiedSpecies({
    required this.scientificName,
    this.scientificNameAuthorship,
    this.genus,
    this.family,
    required this.commonNames,
    required this.score,
    required this.probability,
  });

  String get displayName {
    if (commonNames.isNotEmpty) {
      return commonNames.first;
    }
    return scientificName;
  }

  factory IdentifiedSpecies.fromJson(Map<String, dynamic> json) {
    final speciesRaw = json['species'];
    final speciesData = speciesRaw is Map ? Map<String, dynamic>.from(speciesRaw) : <String, dynamic>{};

    final genusRaw = speciesData['genus'];
    final familyRaw = speciesData['family'];
    final commonNamesRaw = speciesData['commonNames'];

    final commonNames = <String>[];
    if (commonNamesRaw is List) {
      commonNames.addAll(commonNamesRaw.whereType<String>());
    }

    return IdentifiedSpecies(
      scientificName: speciesData['scientificNameWithoutAuthor']?.toString() ?? '',
      scientificNameAuthorship: speciesData['scientificNameAuthorship']?.toString(),
      genus: genusRaw is Map ? genusRaw['scientificNameWithoutAuthor']?.toString() : null,
      family: familyRaw is Map ? familyRaw['scientificNameWithoutAuthor']?.toString() : null,
      commonNames: commonNames,
      score: json['score'] is num ? (json['score'] as num).toDouble() : 0.0,
      probability: json['score'] is num ? (json['score'] as num).toDouble() * 100 : 0.0,
    );
  }
}

/// Modelo para la respuesta de identificación
class PlantIdentificationResult {
  final List<IdentifiedSpecies> species;
  final int remainingRequests;
  final String? error;

  PlantIdentificationResult({
    required this.species,
    required this.remainingRequests,
    this.error,
  });

  factory PlantIdentificationResult.fromJson(Map<String, dynamic> json) {
    final resultsRaw = json['results'];
    final species = <IdentifiedSpecies>[];

    if (resultsRaw is List) {
      for (final result in resultsRaw) {
        if (result is Map) {
          species.add(IdentifiedSpecies.fromJson(Map<String, dynamic>.from(result)));
        }
      }
    }

    return PlantIdentificationResult(
      species: species,
      remainingRequests: json['remainingIdentificationRequests'] is int
          ? json['remainingIdentificationRequests'] as int
          : 0,
    );
  }

  factory PlantIdentificationResult.error(String errorMessage) {
    return PlantIdentificationResult(
      species: [],
      remainingRequests: 0,
      error: errorMessage,
    );
  }
}

/// Servicio para identificar plantas usando Cloud Functions
class PlantIdentificationService {
  // Cloud Functions maneja la comunicación con Pl@ntNet
  // Esto evita problemas de CORS en la web

  /// Identifica una planta a partir de una o más imágenes usando Cloud Functions
  ///
  /// [images]: Lista de archivos de imagen (File para mobile, Uint8List para web)
  /// [organs]: Lista de órganos correspondientes a cada imagen
  /// [project]: Proyecto/flora a usar (por defecto 'all')
  /// [imageNames]: Nombres opcionales para las imágenes (requerido para web)
  Future<PlantIdentificationResult> identifyPlant({
    required List<dynamic> images,
    required List<String> organs,
    String project = 'all',
    List<String>? imageNames,
  }) async {
    try {
      if (images.isEmpty || images.length > 5) {
        return PlantIdentificationResult.error('Debes proporcionar entre 1 y 5 imágenes');
      }

      if (images.length != organs.length) {
        return PlantIdentificationResult.error('El número de imágenes debe coincidir con el número de órganos');
      }

      // Convertir imágenes a base64
      final List<String> imagesBase64 = [];
      for (final image in images) {
        String base64String;
        
        if (image is File) {
          // Para mobile
          final bytes = await image.readAsBytes();
          base64String = base64Encode(bytes);
        } else if (image is Uint8List) {
          // Para web
          base64String = base64Encode(image);
        } else {
          return PlantIdentificationResult.error('Tipo de imagen no soportado');
        }
        
        imagesBase64.add(base64String);
      }

      // Llamar a Cloud Function
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('identifyPlant');
      
      final response = await callable.call({
        'images': imagesBase64,
        'organs': organs,
        'project': project,
      });

      final responseData = response.data;
      if (responseData is Map && responseData['data'] != null) {
        final data = responseData['data'];
        if (data is Map) {
          return PlantIdentificationResult.fromJson(Map<String, dynamic>.from(data));
        }
      }

      return PlantIdentificationResult.error('Respuesta inválida del servidor');
    } catch (e) {
      return PlantIdentificationResult.error('Error de conexión: $e');
    }
  }

  /// Obtiene sugerencias de órganos para las imágenes
  List<String> getOrganSuggestions() {
    return [
      'auto', // Detección automática
      'leaf',
      'flower',
      'fruit',
      'bark',
      'branch',
      'entire',
    ];
  }

  /// Obtiene proyectos/floras disponibles
  List<String> getAvailableProjects() {
    return [
      'all', // Todas las floras
      'weurope', // Europa Occidental
      'canada',
      'usda',
      'k-world-flora',
      'k-southwestern-europe',
      'k-northern-europe',
      'k-eastern-mediterranean',
      'k-central-europe',
      'k-california',
      'k-central-america',
      'k-africa',
      'k-arctic',
      'k-asia-temperate',
      'k-asia-tropical',
      'k-australia',
      'k-caribbean',
      'k-europe',
      'k-indian-ocean',
      'k-mediterranean',
      'k-middle-asia',
      'k-north-america',
      'k-pacific',
      'k-south-america',
      'k-southwestern-europe',
    ];
  }
}