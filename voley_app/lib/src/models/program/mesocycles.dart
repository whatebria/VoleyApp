// lib/src/models/program/mesocycles.dart
import 'package:voley_app/src/models/program/microcicle.dart'; // Ajusta el path

class Mesocycle {
  final String id;
  final String name;
  final int weeks;
  final String focus;
  final String progressionType;
  final List<Microcycle> microcycles;

  Mesocycle({
    required this.id,
    required this.name,
    required this.weeks,
    required this.focus,
    required this.progressionType,
    required this.microcycles,
  });

  // --- CONSTRUCTOR fromJson CORREGIDO Y SEGURO ---
  factory Mesocycle.fromJson(Map<String, dynamic> json) {
    return Mesocycle(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '', // <-- Seguro
      weeks: json['weeks'] as int? ?? 0,
      focus: json['focus'] as String? ?? '', // <-- Seguro
      progressionType: json['progressionType'] as String? ?? '', // <-- Seguro
      microcycles: (json['microcycles'] as List<dynamic>? ?? [])
          .map((microJson) => Microcycle.fromJson(microJson as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'weeks': weeks,
    'focus': focus,
    'progressionType': progressionType,
    'microcycles': microcycles.map((m) => m.toJson()).toList(),
  };

  Mesocycle copyWith({
    String? id,
    String? name,
    int? weeks,
    String? focus,
    String? progressionType,
    List<Microcycle>? microcycles,
  }) {
    return Mesocycle(
      id: id ?? this.id,
      name: name ?? this.name,
      weeks: weeks ?? this.weeks,
      focus: focus ?? this.focus,
      progressionType: progressionType ?? this.progressionType,
      microcycles: microcycles ?? this.microcycles,
    );
  }
}