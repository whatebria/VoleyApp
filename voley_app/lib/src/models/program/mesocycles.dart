import 'package:voley_app/src/models/program/microcicle.dart';

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

  Map<String, dynamic> toJson() => {
        'name': name,
        'weeks': weeks,
        'focus': focus,
        'progressionType': progressionType,
        'microcycles': microcycles.map((m) => m.toJson()).toList(),
      };

  static Mesocycle fromJson(Map<String, dynamic> json) => Mesocycle(
        name: json['name'],
        weeks: json['weeks'],
        focus: json['focus'],
        progressionType: json['progressionType'],
        microcycles: (json['microcycles'] as List<dynamic>? ?? [])
            .map((m) => Microcycle.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      );
}