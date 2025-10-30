// lib/models/injury.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de datos para el CATÁLOGO de Lesiones.
class Injury {
  final String id;
  final String name;
  final int duration; // en semanas
  final String notes; // "leve", "moderada", "grave"
  final List<String> excludeTags; 
  final List<String> recommendTags; 

  Injury({
    required this.id,
    required this.name,
    required this.notes,
    required this.duration,
    required this.excludeTags,
    required this.recommendTags,
  });

  /// Función auxiliar para parsear listas
  static List<String> _parseList(dynamic listData) {
    if (listData is List) return List<String>.from(listData);
    return [];
  }

  /// Convierte un DocumentSnapshot de Firebase a un objeto Injury.
  factory Injury.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Injury(
      id: doc.id,
      name: data['name'] ?? 'Sin nombre',
      notes: data['notes'] ?? 'leve', // Valor por defecto
      duration: data['duration'] ?? 0,
      excludeTags: _parseList(data['excludeTags']),
      recommendTags: _parseList(data['recommendTags']),
    );
  }

  /// Convierte un objeto Injury a un Map<String, dynamic> para Firebase.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'notes': notes,
      'duration': duration,
      'excludeTags': excludeTags,
      'recommendTags': recommendTags,
    };
  }
}