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

  factory IdentifiedSpecies.fromJson(Map<String, dynamic> json) {
    return IdentifiedSpecies(
      scientificName: json['species']['scientificNameWithoutAuthor'] ?? '',
      scientificNameAuthorship: json['species']['scientificNameAuthorship'],
      genus: json['species']['genus']?['scientificNameWithoutAuthor'],
      family: json['species']['family']?['scientificNameWithoutAuthor'],
      commonNames: List<String>.from(json['species']['commonNames'] ?? []),
      score: json['score']?.toDouble() ?? 0.0,
      probability: (json['score']?.toDouble() ?? 0.0) * 100,
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
    return PlantIdentificationResult(
      species: (json['results'] as List<dynamic>?)
          ?.map((result) => IdentifiedSpecies.fromJson(result))
          .toList() ?? [],
      remainingRequests: json['remainingIdentificationRequests'] ?? 0,
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

      if (response.data != null && response.data['data'] != null) {
        return PlantIdentificationResult.fromJson(response.data['data']);
      } else {
        return PlantIdentificationResult.error('Respuesta inválida del servidor');
      }
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