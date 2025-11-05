import 'package:uuid/uuid.dart';

class Goal {
  final String id;
  final String description;
  final bool isCompleted;
  // final DateTime? dateCompleted; // Comentado como en tu ejemplo

  const Goal({
    required this.id,
    required this.description,
    required this.isCompleted,
    // this.dateCompleted,
  });

  /// Serializa la instancia de [Goal] a un mapa JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'isCompleted': isCompleted,
        // 'dateCompleted': dateCompleted?.toIso8601String(),
      };

  /// Crea una instancia de [Goal] desde un mapa JSON.
  static Goal fromJson(Map<String, dynamic> json) => Goal(
        // Si el id no existe, genera uno nuevo (útil para migraciones)
        id: json['id'] as String? ?? const Uuid().v4(),
        description: json['description'] as String? ?? '',
        isCompleted: json['isCompleted'] as bool? ?? false,
        // dateCompleted: json['dateCompleted'] != null
        //     ? DateTime.tryParse(json['dateCompleted'] as String)
        //     : null,
      );

  /// Crea una copia de la instancia [Goal] con campos actualizados.
  Goal copyWith({
    String? id,
    String? description,
    bool? isCompleted,
    // DateTime? dateCompleted,
  }) {
    return Goal(
      id: id ?? this.id,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      // dateCompleted: dateCompleted ?? this.dateCompleted,
    );
  }
}