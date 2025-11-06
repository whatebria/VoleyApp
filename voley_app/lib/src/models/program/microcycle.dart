import 'package:flutter/foundation.dart';
import 'package:voley_app/src/models/program/training_session.dart';

@immutable
class Microcycle {
  final String id;
  final int weekNumber;
  final List<TrainingSession> sessions;

  const Microcycle({
    required this.id,
    required this.weekNumber,
    this.sessions = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'weekNumber': weekNumber,
    'sessions': sessions.map((s) => s.toJson()).toList(),
  };

  static Microcycle fromJson(Map<String, dynamic> json) => Microcycle(
    id: json['id'] as String? ?? '',
    weekNumber: (json['weekNumber'] as num?)?.toInt() ?? 1,
    sessions: ((json['sessions'] as List?) ?? [])
      .whereType<Map<String, dynamic>>()
      .map(TrainingSession.fromJson)
      .toList(),
  );

  Microcycle copyWith({
    String? id,
    int? weekNumber,
    List<TrainingSession>? sessions,
  }) => Microcycle(
    id: id ?? this.id,
    weekNumber: weekNumber ?? this.weekNumber,
    sessions: sessions ?? this.sessions,
  );

  @override
  String toString() => 'Microcycle(id: $id, week: $weekNumber, sessions: ${sessions.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Microcycle &&
        other.id == id &&
        other.weekNumber == weekNumber &&
        listEquals(other.sessions, sessions);

  @override
  int get hashCode => id.hashCode ^ weekNumber.hashCode ^ sessions.hashCode;
}
