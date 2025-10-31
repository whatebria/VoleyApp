class EvaluationResult {
  final Map<String, double> testScores;
  final List<String> strengths;
  final List<String> weaknesses;

  EvaluationResult({
    required this.testScores,
    required this.strengths,
    required this.weaknesses,
  });

  Map<String, dynamic> toJson() => {
        'testScores': testScores,
        'strengths': strengths,
        'weaknesses': weaknesses,
      };

  static EvaluationResult fromJson(Map<String, dynamic> json) => EvaluationResult(
        testScores: Map<String, double>.from((json['testScores'] ?? {}).map((k, v) => MapEntry(k, (v as num).toDouble()))),
        strengths: List<String>.from(json['strengths'] ?? []),
        weaknesses: List<String>.from(json['weaknesses'] ?? []),
      );
}
