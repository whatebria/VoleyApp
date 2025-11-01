// lib/models/phase.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para el catálogo de Fases de entrenamiento.
class Phase {
  final String id;
  final String name;
  final String description;
  final int sessionsPerWeek;
  
  // Rango de duración (basado en tu petición anterior)
  final int weeksMin;
  final int weeksMax;
  
  /// Nivel general de carga ("baja", "media", "alta")
  final String intensity;
  
  /// Tipo general de fase ("pretemporada", "temporada", etc.)
  final String phaseType;
  
  // --- IDs de la colección 'objectives' ---
  final List<String> targetObjectiveIds;  // ("targetTags")
  final List<String> excludeObjectiveIds; // ("excludeTags")
  final List<String> recommendObjectiveIds; // ("recommendTags")

  Phase({
    required this.id,
    required this.name,
    required this.description,
    required this.sessionsPerWeek,
    required this.weeksMin,
    required this.weeksMax,
    required this.intensity,
    required this.phaseType,
    required this.targetObjectiveIds,
    required this.excludeObjectiveIds,
    required this.recommendObjectiveIds,
  });

  /// Función auxiliar para parsear listas
  static List<String> _parseList(dynamic listData) {
    if (listData is List) return List<String>.from(listData);
    return [];
  }

  /// Convierte un DocumentSnapshot de Firebase a un objeto Phase.
  factory Phase.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Phase(
      id: doc.id,
      name: data['name'] ?? 'Sin nombre',
      description: data['description'] ?? '',
      sessionsPerWeek: data['sessionsPerWeek'] ?? 0,
      
      // Mapeo a los campos actualizados
      // Incluye un fallback por si el campo se llamaba 'durationWeeks'
      weeksMin: data['weeksMin'] ?? (data['durationWeeks'] ?? 0),
      weeksMax: data['weeksMax'] ?? (data['durationWeeks'] ?? 0), 
      intensity: data['intensity'] ?? 'media', // Valor por defecto
      phaseType: data['phaseType'] ?? 'temporada', // Valor por defecto
      
      // Mapeo a los IDs de objetivos
      targetObjectiveIds: _parseList(data['targetObjectiveIds']),
      excludeObjectiveIds: _parseList(data['excludeObjectiveIds']),
      recommendObjectiveIds: _parseList(data['recommendObjectiveIds']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'sessionsPerWeek': sessionsPerWeek,
      'weeksMin': weeksMin,
      'weeksMax': weeksMax,
      'intensity': intensity,
      'phaseType': phaseType,
      'targetObjectiveIds': targetObjectiveIds,
      'excludeObjectiveIds': excludeObjectiveIds,
      'recommendObjectiveIds': recommendObjectiveIds,
    };
  }
}