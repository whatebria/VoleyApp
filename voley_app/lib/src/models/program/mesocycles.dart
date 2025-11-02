// lib/src/models/program/mesocycles.dart
import 'package:voley_app/src/models/program/microcicle.dart'; // Ajusta el path

class Mesocycle {
  final String name;
  final int weeks;
  final String focus;
  final String progressionType;
  final List<Microcycle> microcycles;

  Mesocycle({
    required this.name,
    required this.weeks,
    required this.focus,
    required this.progressionType,
    required this.microcycles,
  });

  // --- CONSTRUCTOR fromJson CORREGIDO Y SEGURO ---
  factory Mesocycle.fromJson(Map<String, dynamic> json) {
    return Mesocycle(
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
    'name': name,
    'weeks': weeks,
    'focus': focus,
    'progressionType': progressionType,
    'microcycles': microcycles.map((m) => m.toJson()).toList(),
  };
}