import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:voley_app/utils/common/utils.dart';

enum InjuryStatus { active, healing, recovered }

@immutable
class Injury {
  final String id;
  final String description;
  final InjuryStatus status;
  final DateTime? since;
  final DateTime? until;

  const Injury({
    required this.id,
    required this.description,
    required this.status,
    this.since,
    this.until,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'status': status.name,
        'since': ModelUtils.isoOrNull(since),
        'until': ModelUtils.isoOrNull(until),
      };

  static Injury fromJson(Map<String, dynamic> json) => Injury(
        id: json['id'] as String? ?? const Uuid().v4(),
        description: json['description'] as String? ?? '',
        status: ModelUtils.enumByName(
          InjuryStatus.values,
          json['status'] as String?,
          InjuryStatus.active,
        ),
        since: ModelUtils.parseDateFlex(json['since']),
        until: ModelUtils.parseDateFlex(json['until']),
      );

  Injury copyWith({
    String? id,
    String? description,
    InjuryStatus? status,
    DateTime? since,
    DateTime? until,
  }) =>
      Injury(
        id: id ?? this.id,
        description: description ?? this.description,
        status: status ?? this.status,
        since: since ?? this.since,
        until: until ?? this.until,
      );
}
