// En mesocycles.dart
import 'package:voley_app/src/models/program/microcicle.dart';

class Mesocycle {
  // (Tus campos)
  final String name;
  final int weeks;
  final String focus;
  final String progressionType;
  final List<Microcycle> microcycles;

  // (Tu constructor)
  Mesocycle({
    required this.name,
    required this.weeks,
    required this.focus,
    required this.progressionType,
    required this.microcycles,
  });

  // --- AÑADE ESTE CONSTRUCTOR ---
  factory Mesocycle.fromJson(Map<String, dynamic> json) {
    return Mesocycle(
      name: json['name'] ?? '',
      weeks: json['weeks'] ?? 0,
      focus: json['focus'] ?? '',
      progressionType: json['progressionType'] ?? '',
      microcycles: (json['microcycles'] as List<dynamic>? ?? [])
          .map((microJson) => Microcycle.fromJson(microJson as Map<String, dynamic>))
          .toList(),
    );
  }

  // (Tu método toJson)
  Map<String, dynamic> toJson() => {
    'name': name,
    'weeks': weeks,
    'focus': focus,
    'progressionType': progressionType,
    'microcycles': microcycles.map((m) => m.toJson()).toList(),
  };
}