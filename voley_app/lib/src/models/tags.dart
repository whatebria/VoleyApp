// lib/models/objective.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para el catálogo de Objetivos (tags normalizados).
class Objective {
  final String id;
  final String name;
  final String description;
  final String category; // ej: "Físico", "Técnico", "Táctico"
  final String type; // ej: "Físico", "Técnico", "Táctico"

  Objective({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.type,
  });

  factory Objective.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Objective(
      id: doc.id,
      name: data['name'] ?? 'Sin nombre',
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      type: data['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'type': type,
    };
  }
}