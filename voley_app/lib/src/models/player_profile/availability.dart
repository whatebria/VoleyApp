import 'package:flutter/foundation.dart';
import 'package:voley_app/utils/common/utils.dart';
import 'package:voley_app/src/models/shared/day_of_week.dart';



@immutable
class Availability {
  final List<DayOfWeek> trainingDays;
  final int sessionMinutes;

  const Availability({
    this.trainingDays = const [],
    this.sessionMinutes = 60,
  });

  Map<String, dynamic> toJson() => {
        'trainingDays': trainingDays.map((d) => d.name).toList(),
        'sessionMinutes': sessionMinutes,
      };

  static Availability fromJson(Map<String, dynamic> json) => Availability(
        trainingDays: ((json['trainingDays'] as List?) ?? [])
            .map((e) => ModelUtils.enumByName(
                  DayOfWeek.values,
                  (e ?? '').toString(),
                  DayOfWeek.mon,
                ))
            .toList(),
        sessionMinutes: (json['sessionMinutes'] as num?)?.toInt() ?? 60,
      );

  Availability copyWith({
    List<DayOfWeek>? trainingDays,
    int? sessionMinutes,
  }) =>
      Availability(
        trainingDays: trainingDays ?? this.trainingDays,
        sessionMinutes: sessionMinutes ?? this.sessionMinutes,
      );
}
