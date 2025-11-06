import 'package:flutter/foundation.dart';

@immutable
class TestScore {
  final String testId; // p.ej: 'vertical_jump'
  final double value;
  final String unit;   // 'cm', 's', 'kg', 'pts'
  final String? note;  // opcional

  const TestScore({
    required this.testId,
    required this.value,
    required this.unit,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'testId': testId,
        'value': value,
        'unit': unit,
        'note': note,
      };

  static TestScore fromJson(Map<String, dynamic> json) => TestScore(
        testId: json['testId'] as String? ?? '',
        value: (json['value'] as num?)?.toDouble() ?? 0.0,
        unit: json['unit'] as String? ?? '',
        note: json['note'] as String?,
      );

  TestScore copyWith({String? testId, double? value, String? unit, String? note}) =>
      TestScore(
        testId: testId ?? this.testId,
        value: value ?? this.value,
        unit: unit ?? this.unit,
        note: note ?? this.note,
      );
}
