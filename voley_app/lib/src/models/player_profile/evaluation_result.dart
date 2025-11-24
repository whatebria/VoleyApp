import 'package:flutter/foundation.dart';
import 'package:voley_app/utils/common/utils.dart';
import 'test_score.dart';

@immutable
class EvaluationResult {
  final DateTime date;
  final List<TestScore> testScores;

  const EvaluationResult({
    required this.date,
    this.testScores = const [],
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'testScores': testScores.map((s) => s.toJson()).toList(),
      };

  static EvaluationResult fromJson(Map<String, dynamic> json) => EvaluationResult(
        date: ModelUtils.parseDateFlex(json['date']) ?? DateTime.now(),
        testScores: ((json['testScores'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(TestScore.fromJson)
            .toList(),
      );

  EvaluationResult copyWith({DateTime? date, List<TestScore>? testScores}) =>
      EvaluationResult(
        date: date ?? this.date,
        testScores: testScores ?? this.testScores,
      );

      String get displayLabel {
    if (testScores.isEmpty) return 'Evaluación';
    if (testScores.length == 1) return testScores.first.testId;
    final remaining = testScores.length - 1;
    return '${testScores.first.testId} +$remaining pruebas';
  }
}
