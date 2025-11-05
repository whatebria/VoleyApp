import 'package:uuid/uuid.dart';

/// Enum para el estado de una lesión
enum InjuryStatus {
  active,
  healing,
  recovered;

  /// Convierte un String a [InjuryStatus], con un valor por defecto.
  static InjuryStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return InjuryStatus.active;
      case 'healing':
        return InjuryStatus.healing;
      case 'recovered':
        return InjuryStatus.recovered;
      default:
        // Valor por defecto si el string es nulo o no coincide
        return InjuryStatus.active; 
    }
  }

  /// Convierte el enum [InjuryStatus] a un String legible.
  String toJson() => name;
}

class Injury {
  final String id;
  final String description;
  final InjuryStatus status;

  const Injury({
    required this.id,
    required this.description,
    required this.status,
  });

  /// Serializa la instancia de [Injury] a un mapa JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        // Guarda el enum como un string (ej. 'active')
        'status': status.toJson(), 
      };

  /// Crea una instancia de [Injury] desde un mapa JSON.
  static Injury fromJson(Map<String, dynamic> json) => Injury(
        id: json['id'] as String? ?? const Uuid().v4(),
        description: json['description'] as String? ?? '',
        // Convierte el string guardado de nuevo a un enum
        status: InjuryStatus.fromString(json['status'] as String?),
      );

  /// Crea una copia de la instancia [Injury] con campos actualizados.
  Injury copyWith({
    String? id,
    String? description,
    InjuryStatus? status,
  }) {
    return Injury(
      id: id ?? this.id,
      description: description ?? this.description,
      status: status ?? this.status,
    );
  }
}