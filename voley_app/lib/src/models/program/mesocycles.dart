// lib/src/models/program/mesocycles.dart
import 'package:voley_app/src/models/program/microcicle.dart'; // Ajusta el path

enum MacroPhase { pretemporada, competicion, transicion }

extension MacroPhaseX on MacroPhase {
  String get label {
    switch (this) {
      case MacroPhase.pretemporada:
        return 'Pretemporada';
      case MacroPhase.competicion:
        return 'Competición';
      case MacroPhase.transicion:
        return 'Transición';
    }
  }

  int get minWeeks {
    switch (this) {
      case MacroPhase.pretemporada:
        return 4;
      case MacroPhase.competicion:
        return 12; // 3 meses ≈ 12 semanas
      case MacroPhase.transicion:
        return 2;
    }
  }

  int get maxWeeks {
    switch (this) {
      case MacroPhase.pretemporada:
        return 8;
      case MacroPhase.competicion:
        return 32; // 8 meses ≈ 32 semanas
      case MacroPhase.transicion:
        return 4;
    }
  }

  int get defaultWeeks {
    switch (this) {
      case MacroPhase.pretemporada:
        return 6;
      case MacroPhase.competicion:
        return 20;
      case MacroPhase.transicion:
        return 3;
    }
  }
}

MacroPhase _macroPhaseFromJson(String? value) {
  switch (value?.toLowerCase()) {
    case 'competición':
    case 'competicion':
      return MacroPhase.competicion;
    case 'transición':
    case 'transicion':
      return MacroPhase.transicion;
    case 'pretemporada':
    default:
      return MacroPhase.pretemporada;
  }
}

String _macroPhaseToJson(MacroPhase phase) {
  switch (phase) {
    case MacroPhase.competicion:
      return 'competicion';
    case MacroPhase.transicion:
      return 'transicion';
    case MacroPhase.pretemporada:
      return 'pretemporada';
  }
}

class Mesocycle {
  final String id;
  final String name;
  final int weeks;
  final String focus;
  final String progressionType;
  final MacroPhase macroPhase;
  final int matchDayIndex;
  final List<Microcycle> microcycles;

  Mesocycle({
    required this.id,
    required this.name,
    required this.weeks,
    required this.focus,
    required this.progressionType,
    required this.macroPhase,
    required this.matchDayIndex,
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
      macroPhase: _macroPhaseFromJson(json['macroPhase'] as String?),
      matchDayIndex: json['matchDayIndex'] as int? ?? 5,
      microcycles: (json['microcycles'] as List<dynamic>? ?? [])
          .map(
            (microJson) =>
                Microcycle.fromJson(microJson as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'weeks': weeks,
    'focus': focus,
    'progressionType': progressionType,
    'macroPhase': _macroPhaseToJson(macroPhase),
    'matchDayIndex': matchDayIndex,
    'microcycles': microcycles.map((m) => m.toJson()).toList(),
  };

  Mesocycle copyWith({
    String? id,
    String? name,
    int? weeks,
    String? focus,
    String? progressionType,
    MacroPhase? macroPhase,
    int? matchDayIndex,
    List<Microcycle>? microcycles,
  }) {
    return Mesocycle(
      id: id ?? this.id,
      name: name ?? this.name,
      weeks: weeks ?? this.weeks,
      focus: focus ?? this.focus,
      progressionType: progressionType ?? this.progressionType,
      macroPhase: macroPhase ?? this.macroPhase,
      matchDayIndex: matchDayIndex ?? this.matchDayIndex,
      microcycles: microcycles ?? this.microcycles,
    );
  }
}
