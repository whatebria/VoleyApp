import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart'; // Para ListEquality

/// Modelo para un ejercicio en la biblioteca principal (Base de Datos).
/// Usa IDs para enlazar a otras colecciones (tags, levels, etc.)
@immutable
class Exercise {
  final String id;
  final String name; // El único string de texto libre para mostrar
  final String description;
  final String videoUrl;

  // --- CAMPOS DE DATOS INTELIGENTES (IDs, no Strings) ---

  /// IDs de tags (ej. 'lower_body', 'explosive', 'push')
  final List<String> tagIds;

  /// ID de nivel (ej. 'beginner', 'intermediate', 'advanced')
  final String levelId;

  /// ID de categoría (ej. 'strength', 'plyo', 'mobility')
  final String categoryId;

  /// IDs de equipamiento (ej. 'dumbbell', 'barbell', 'kettlebell')
  final List<String> equipmentIds;

  /// IDs de contraindicaciones (ej. 'knee_pain', 'lower_back_injury')
  final List<String> contraindicationIds;

  const Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.videoUrl,
    required this.tagIds,
    required this.levelId,
    required this.categoryId,
    required this.equipmentIds,
    required this.contraindicationIds,
  });

  /// Serializa la instancia a un mapa JSON para Firestore.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'videoUrl': videoUrl,
        'tagIds': tagIds,
        'levelId': levelId,
        'categoryId': categoryId,
        'equipmentIds': equipmentIds,
        'contraindicationIds': contraindicationIds,
      };

  /// Crea una instancia de Exercise desde un mapa JSON (Firestore).
  static Exercise fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Ejercicio sin nombre',
        description: json['description'] as String? ?? '',
        videoUrl: json['videoUrl'] as String? ?? '',
        tagIds: List<String>.from(json['tagIds'] ?? []),
        levelId: json['levelId'] as String? ?? 'intermediate',
        categoryId: json['categoryId'] as String? ?? 'general',
        equipmentIds: List<String>.from(json['equipmentIds'] ?? []),
        contraindicationIds:
            List<String>.from(json['contraindicationIds'] ?? []),
      );

  /// Crea una copia de la instancia con campos actualizados.
  Exercise copyWith({
    String? id,
    String? name,
    String? description,
    String? videoUrl,
    List<String>? tagIds,
    String? levelId,
    String? categoryId,
    List<String>? equipmentIds,
    List<String>? contraindicationIds,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      tagIds: tagIds ?? this.tagIds,
      levelId: levelId ?? this.levelId,
      categoryId: categoryId ?? this.categoryId,
      equipmentIds: equipmentIds ?? this.equipmentIds,
      contraindicationIds: contraindicationIds ?? this.contraindicationIds,
    );
  }

  @override
  String toString() {
    return 'Exercise(id: $id, name: $name, categoryId: $categoryId, levelId: $levelId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is Exercise &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.videoUrl == videoUrl &&
        listEquals(other.tagIds, tagIds) &&
        other.levelId == levelId &&
        other.categoryId == categoryId &&
        listEquals(other.equipmentIds, equipmentIds) &&
        listEquals(other.contraindicationIds, contraindicationIds);
  }

  @override
  int get hashCode {
    final listHash = const DeepCollectionEquality().hash;
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        videoUrl.hashCode ^
        listHash(tagIds) ^
        levelId.hashCode ^
        categoryId.hashCode ^
        listHash(equipmentIds) ^
        listHash(contraindicationIds);
  }
}