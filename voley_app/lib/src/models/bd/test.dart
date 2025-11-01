// lib/models/test.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de datos simple para un Test de evaluación (CATÁLOGO).
class Test {
  final String id;
  final String name;
  final String description;
  final String measure; // (e.g. "cm", "s", "kg")
  final String objective;
  final List<String> recommendedTags; // Qué mejorar (ej: "fuerza core", "movilidad")

  Test({
    required this.id,
    required this.name,
    required this.description,
    required this.measure,
    required this.objective,
    required this.recommendedTags,
  });

  /// Función auxiliar para parsear listas
  static List<String> _parseList(dynamic listData) {
    if (listData is List) return List<String>.from(listData);
    return [];
  }

  /// Convierte un DocumentSnapshot de Firebase a un objeto Test.
  factory Test.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Test(
      id: doc.id,
      name: data['name'] ?? 'Sin nombre',
      description: data['description'] ?? '',
      measure: data['measure'] ?? '',
      objective: data['objective'] ?? '',
      recommendedTags: _parseList(data['recommendedTags']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'measure': measure,
      'objective': objective,
      'recommendedTags': recommendedTags,
    };
  }
}