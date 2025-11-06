import 'package:flutter/foundation.dart';
import 'package:voley_app/utils/common/utils.dart';

enum PlayerEventType { league, cup, playoff, nationalTeam, travel }

@immutable
class PlayerEvent {
  final PlayerEventType type;
  final DateTime date;
  final String? description;

  const PlayerEvent({required this.type, required this.date, this.description});

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'date': date.toIso8601String(),
        'description': description,
      };

  static PlayerEvent fromJson(Map<String, dynamic> json) => PlayerEvent(
        type: ModelUtils.enumByName(
          PlayerEventType.values,
          json['type'] as String?,
          PlayerEventType.league,
        ),
        date: ModelUtils.parseDateFlex(json['date']) ?? DateTime.now(),
        description: json['description'] as String?,
      );

  PlayerEvent copyWith({PlayerEventType? type, DateTime? date, String? description}) =>
      PlayerEvent(
        type: type ?? this.type,
        date: date ?? this.date,
        description: description ?? this.description,
      );
}
