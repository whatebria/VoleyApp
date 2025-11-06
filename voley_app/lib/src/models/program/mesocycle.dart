import 'package:flutter/foundation.dart';
import 'package:voley_app/src/models/program/microcycle.dart';
import 'package:voley_app/utils/common/utils.dart';

enum ProgressionType { linear, undulating, block, conjugate }

@immutable
class Mesocycle {
  final String id;
  final String name;
  final int weeks;
  final String focus;
  final ProgressionType progressionType;
  final int matchDayIndex;     // 0..6 (según DayOfWeek)
  final List<Microcycle> microcycles;
  final String objective;

  const Mesocycle({
    required this.id,
    required this.name,
    required this.weeks,
    required this.focus,
    required this.progressionType,
    required this.matchDayIndex,
    this.microcycles = const [],
    this.objective = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'weeks': weeks,
    'focus': focus,
    'progressionType': progressionType.name,
    'matchDayIndex': matchDayIndex,
    'microcycles': microcycles.map((m) => m.toJson()).toList(),
    'objective': objective,
  };

  static Mesocycle fromJson(Map<String, dynamic> json) => Mesocycle(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    weeks: (json['weeks'] as num?)?.toInt() ?? 1,
    focus: json['focus'] as String? ?? '',
    progressionType: ModelUtils.enumByName(
      ProgressionType.values,
      json['progressionType'] as String?,
      ProgressionType.linear,
    ),
    matchDayIndex: (json['matchDayIndex'] as num?)?.toInt() ?? 6,
    microcycles: ((json['microcycles'] as List?) ?? [])
      .whereType<Map<String, dynamic>>()
      .map(Microcycle.fromJson)
      .toList(),
    objective: json['objective'] as String? ?? '',
  );

  Mesocycle copyWith({
    String? id,
    String? name,
    int? weeks,
    String? focus,
    ProgressionType? progressionType,
    int? matchDayIndex,
    List<Microcycle>? microcycles,
    String? objective,
  }) => Mesocycle(
    id: id ?? this.id,
    name: name ?? this.name,
    weeks: weeks ?? this.weeks,
    focus: focus ?? this.focus,
    progressionType: progressionType ?? this.progressionType,
    matchDayIndex: matchDayIndex ?? this.matchDayIndex,
    microcycles: microcycles ?? this.microcycles,
    objective: objective ?? this.objective,
  );

  @override
  String toString() => 'Mesocycle($name • $weeks semanas • ${progressionType.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Mesocycle &&
        other.id == id &&
        other.name == name &&
        other.weeks == weeks &&
        other.focus == focus &&
        other.progressionType == progressionType &&
        other.matchDayIndex == matchDayIndex &&
        listEquals(other.microcycles, microcycles) &&
        other.objective == objective;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      weeks.hashCode ^
      focus.hashCode ^
      progressionType.hashCode ^
      matchDayIndex.hashCode ^
      microcycles.hashCode ^
      objective.hashCode;
}
