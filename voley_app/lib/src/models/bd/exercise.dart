// lib/src/modelos/exercise_v4.dart
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart'; // Para ListEquality

// Importa tus Enums
import 'package:voley_app/src/catalogos/enums.dart';

@immutable
class Exercise {
  // --- Identidad y Contenido Principal ---
  final String id; // ej. "ex_box_jump_controlado"
  final String
  slug; // ej. "box_jump_controlado" (para URLs o búsquedas amigables)
  final String name;
  final String description;
  final String videoUrl;

  // --- Catálogos principales (Enums simples) ---
  final LevelId levelId;
  final CategoryId categoryId;

  // --- Detalle técnico (Sustituye tags genéricos) ---
  final MovementPatternId movementPatternId;
  final List<MuscleGroupId> muscleGroupIds;
  final List<QualityId> qualityIds;
  final PlaneId planeId;
  final DominanceId dominanceId;

  // --- Vóley / Contexto Específico ---
  final List<VolleyballTransferId> vbTransferIds;
  final List<VolleyballPositionId> positions;
  final List<TrainingPhaseId> phases;

  // --- Equipamiento y Seguridad ---
  final List<EquipmentId> equipmentIds;
  final List<ContraindicationId> contraindicationIds;

  const Exercise({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.videoUrl,
    required this.levelId,
    required this.categoryId,
    required this.movementPatternId,
    this.muscleGroupIds = const [],
    this.qualityIds = const [],
    required this.planeId,
    required this.dominanceId,
    this.vbTransferIds = const [],
    this.positions = const [],
    this.phases = const [],
    this.equipmentIds = const [],
    this.contraindicationIds = const [],
  });

  // --- 📦 Serialización a Firestore (strings legibles .name) ---
  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'name': name,
    'description': description,
    'videoUrl': videoUrl,
    'levelId': levelId.name,
    'categoryId': categoryId.name,
    'movementPatternId': movementPatternId.name,
    'muscleGroupIds': muscleGroupIds.map((e) => e.name).toList(),
    'qualityIds': qualityIds.map((e) => e.name).toList(),
    'planeId': planeId.name,
    'dominanceId': dominanceId.name,
    'vbTransferIds': vbTransferIds.map((e) => e.name).toList(),
    'positions': positions.map((e) => e.name).toList(),
    'phases': phases.map((e) => e.name).toList(),
    'equipmentIds': equipmentIds.map((e) => e.name).toList(),
    'contraindicationIds': contraindicationIds.map((e) => e.name).toList(),
  };

  // --- 📥 Deserialización desde Firestore ---

  // Helper para convertir List<String> a List<Enum> con manejo seguro de nulos
  static List<T> _listFromNames<T extends Enum>(
    List<String>? names,
    List<T> values,
  ) {
    if (names == null) return const [];
    return names
        .map((e) => values.asNameMap()[e]) // Busca el Enum por nombre
        .whereType<
          T
        >() // Filtra y asegura que sea del tipo T (maneja nombres inválidos)
        .toList();
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    // Valores por defecto para Enums singulares en caso de error o nulo
    final defaultLevel = LevelId.intermediate;
    final defaultCategory = CategoryId.fuerza;
    final defaultPattern = MovementPatternId.squat;
    final defaultPlane = PlaneId.sagittal;
    final defaultDominance = DominanceId.bilateral;

    // Helper para convertir String a Enum con manejo seguro de errores
    T enumFromName<T extends Enum>(
      String? name,
      List<T> values,
      T defaultValue,
    ) {
      if (name == null) return defaultValue;
      return values.asNameMap()[name] ?? defaultValue;
    }

    return Exercise(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? 'Ejercicio sin nombre',
      description: json['description'] as String? ?? '',
      videoUrl: json['videoUrl'] as String? ?? '',

      // Conversión de Strings a Enums (Singular)
      levelId: enumFromName(
        json['levelId'] as String?,
        LevelId.values,
        defaultLevel,
      ),
      categoryId: enumFromName(
        json['categoryId'] as String?,
        CategoryId.values,
        defaultCategory,
      ),
      movementPatternId: enumFromName(
        json['movementPatternId'] as String?,
        MovementPatternId.values,
        defaultPattern,
      ),
      planeId: enumFromName(
        json['planeId'] as String?,
        PlaneId.values,
        defaultPlane,
      ),
      dominanceId: enumFromName(
        json['dominanceId'] as String?,
        DominanceId.values,
        defaultDominance,
      ),

      // Conversión de List<Strings> a List<Enums> (Plural)
      muscleGroupIds: _listFromNames(
        (json['muscleGroupIds'] as List?)?.cast<String>(),
        MuscleGroupId.values,
      ),
      qualityIds: _listFromNames(
        (json['qualityIds'] as List?)?.cast<String>(),
        QualityId.values,
      ),
      vbTransferIds: _listFromNames(
        (json['vbTransferIds'] as List?)?.cast<String>(),
        VolleyballTransferId.values,
      ),
      positions: _listFromNames(
        (json['positions'] as List?)?.cast<String>(),
        VolleyballPositionId.values,
      ),
      phases: _listFromNames(
        (json['phases'] as List?)?.cast<String>(),
        TrainingPhaseId.values,
      ),
      equipmentIds: _listFromNames(
        (json['equipmentIds'] as List?)?.cast<String>(),
        EquipmentId.values,
      ),
      contraindicationIds: _listFromNames(
        (json['contraindicationIds'] as List?)?.cast<String>(),
        ContraindicationId.values,
      ),
    );
  }

  // --- 📝 Copia (Inmutabilidad) ---
  Exercise copyWith({
    String? id,
    String? slug,
    String? name,
    String? description,
    String? videoUrl,
    LevelId? levelId,
    CategoryId? categoryId,
    MovementPatternId? movementPatternId,
    List<MuscleGroupId>? muscleGroupIds,
    List<QualityId>? qualityIds,
    PlaneId? planeId,
    DominanceId? dominanceId,
    List<VolleyballTransferId>? vbTransferIds,
    List<VolleyballPositionId>? positions,
    List<TrainingPhaseId>? phases,
    List<EquipmentId>? equipmentIds,
    List<ContraindicationId>? contraindicationIds,
  }) {
    return Exercise(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      levelId: levelId ?? this.levelId,
      categoryId: categoryId ?? this.categoryId,
      movementPatternId: movementPatternId ?? this.movementPatternId,
      muscleGroupIds: muscleGroupIds ?? this.muscleGroupIds,
      qualityIds: qualityIds ?? this.qualityIds,
      planeId: planeId ?? this.planeId,
      dominanceId: dominanceId ?? this.dominanceId,
      vbTransferIds: vbTransferIds ?? this.vbTransferIds,
      positions: positions ?? this.positions,
      phases: phases ?? this.phases,
      equipmentIds: equipmentIds ?? this.equipmentIds,
      contraindicationIds: contraindicationIds ?? this.contraindicationIds,
    );
  }

  // --- 💡 Debugging y Consola ---
  @override
  String toString() {
    return 'Exercise(id: $id, name: $name, category: ${categoryId.name}, level: ${levelId.name})';
  }

  // --- ⚖️ Igualdad y Hash Code (Requerido por @immutable) ---

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is Exercise &&
        other.id == id &&
        other.slug == slug &&
        other.name == name &&
        other.description == description &&
        other.videoUrl == videoUrl &&
        other.levelId == levelId &&
        other.categoryId == categoryId &&
        other.movementPatternId == movementPatternId &&
        other.planeId == planeId &&
        other.dominanceId == dominanceId &&
        listEquals(other.muscleGroupIds, muscleGroupIds) &&
        listEquals(other.qualityIds, qualityIds) &&
        listEquals(other.vbTransferIds, vbTransferIds) &&
        listEquals(other.positions, positions) &&
        listEquals(other.phases, phases) &&
        listEquals(other.equipmentIds, equipmentIds) &&
        listEquals(other.contraindicationIds, contraindicationIds);
  }

  @override
  int get hashCode {
    final listHash = const DeepCollectionEquality().hash;
    return id.hashCode ^
        slug.hashCode ^
        name.hashCode ^
        description.hashCode ^
        videoUrl.hashCode ^
        levelId.hashCode ^
        categoryId.hashCode ^
        movementPatternId.hashCode ^
        planeId.hashCode ^
        dominanceId.hashCode ^
        listHash(muscleGroupIds) ^
        listHash(qualityIds) ^
        listHash(vbTransferIds) ^
        listHash(positions) ^
        listHash(phases) ^
        listHash(equipmentIds) ^
        listHash(contraindicationIds);
  }
}
