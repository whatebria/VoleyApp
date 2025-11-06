import 'package:flutter/foundation.dart';
import 'package:voley_app/utils/common/utils.dart';

@immutable
class Tournament {
  final String? id; // opcional si luego necesitas editar
  final DateTime date;
  final String name;

  const Tournament({this.id, required this.date, required this.name});

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'name': name,
      };

  static Tournament fromJson(Map<String, dynamic> json) => Tournament(
        id: json['id'] as String?,
        date: ModelUtils.parseDateFlex(json['date']) ?? DateTime.now(),
        name: json['name'] as String? ?? '',
      );

  Tournament copyWith({String? id, DateTime? date, String? name}) =>
      Tournament(id: id ?? this.id, date: date ?? this.date, name: name ?? this.name);
}
