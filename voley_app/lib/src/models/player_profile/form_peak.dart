import 'package:flutter/foundation.dart';
import 'package:voley_app/utils/common/utils.dart';

@immutable
class FormPeak {
  final DateTime date;
  final String? note;

  const FormPeak({required this.date, this.note});

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'note': note,
      };

  static FormPeak fromJson(Map<String, dynamic> json) => FormPeak(
        date: ModelUtils.parseDateFlex(json['date']) ?? DateTime.now(),
        note: json['note'] as String?,
      );

  FormPeak copyWith({DateTime? date, String? note}) =>
      FormPeak(date: date ?? this.date, note: note ?? this.note);
}
