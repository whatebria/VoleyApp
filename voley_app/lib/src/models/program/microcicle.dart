
import 'package:voley_app/src/models/program/training_session.dart';

class Microcycle {
  final int weekNumber;
  final List<TrainingSession> sessions;

  Microcycle({required this.weekNumber, required this.sessions});

  Map<String, dynamic> toJson() => {
        'weekNumber': weekNumber,
        'sessions': sessions.map((s) => s.toJson()).toList(),
      };

  static Microcycle fromJson(Map<String, dynamic> json) => Microcycle(
        weekNumber: json['weekNumber'],
        sessions: (json['sessions'] as List<dynamic>? ?? [])
            .map((s) => TrainingSession.fromJson(Map<String, dynamic>.from(s)))
            .toList(),
      );
}
