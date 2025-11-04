import 'package:voley_app/src/models/program/microcicle.dart'; // Ajusta el path


class Mesocycle {
  final String id;
  final String name;
  final int weeks;
  final String focus;
  final String progressionType;
  final int matchDayIndex;
  final List<Microcycle> microcycles;
  final String objective; // --- AÑADIDO ---

  Mesocycle({
    required this.id,
    required this.name,
    required this.weeks,
    required this.focus,
    required this.progressionType,
    required this.matchDayIndex,
    required this.microcycles,
    required this.objective, // --- AÑADIDO ---
  });

  // --- CONSTRUCTOR fromJson CORREGIDO Y SEGURO ---
  factory Mesocycle.fromJson(Map<String, dynamic> json) {
    return Mesocycle(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '', // <-- Seguro
      weeks: json['weeks'] as int? ?? 0,
      focus: json['focus'] as String? ?? '', // <-- Seguro
      progressionType: json['progressionType'] as String? ?? '', // <-- Seguro
      matchDayIndex: json['matchDayIndex'] as int? ?? 5,
      microcycles: (json['microcycles'] as List<dynamic>? ?? [])
          .map(
            (microJson) =>
                Microcycle.fromJson(microJson as Map<String, dynamic>),
          )
          .toList(),
      objective: json['objective'] as String? ?? '', // --- AÑADIDO ---
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'weeks': weeks,
    'focus': focus,
    'progressionType': progressionType,
    'matchDayIndex': matchDayIndex,
    'microcycles': microcycles.map((m) => m.toJson()).toList(),
    'objective': objective, // --- AÑADIDO ---
  };

  Mesocycle copyWith({
    String? id,
    String? name,
    int? weeks,
    String? focus,
    String? progressionType,
    int? matchDayIndex,
    List<Microcycle>? microcycles,
    String? objective, // --- AÑADIDO ---
  }) {
    return Mesocycle(
      id: id ?? this.id,
      name: name ?? this.name,
      weeks: weeks ?? this.weeks,
      focus: focus ?? this.focus,
      progressionType: progressionType ?? this.progressionType,
      matchDayIndex: matchDayIndex ?? this.matchDayIndex,
      microcycles: microcycles ?? this.microcycles,
      objective: objective ?? this.objective, // --- AÑADIDO ---
    );
  }
}
