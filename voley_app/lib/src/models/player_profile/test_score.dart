import 'package:flutter/foundation.dart';

/// Modelo para almacenar el resultado de un test específico.
@immutable
class TestScore {
  /// El ID único y a prueba de errores del test.
  /// Ej: 'vertical_jump', 't_test', '20m_sprint'
  final String testId;

  /// El valor numérico que logró el atleta.
  final double value;

  /// La unidad de medida para este valor (¡crucial para la UI!)
  /// Ej: 'cm', 'seg', 'kg', 'pts'
  final String unit;

  const TestScore({
    required this.testId,
    required this.value,
    required this.unit,
  });

  /// Serializa la instancia de [TestScore] a un mapa JSON.
  Map<String, dynamic> toJson() => {
        'testId': testId,
        'value': value,
        'unit': unit,
      };

  /// Crea una instancia de [TestScore] desde un mapa JSON.
  /// Es robusto contra valores nulos o tipos incorrectos.
  static TestScore fromJson(Map<String, dynamic> json) => TestScore(
        // Si testId es nulo, usa un string vacío
        testId: json['testId'] as String? ?? '',
        // Lee como 'num' (que acepta int y double) y luego convierte a double.
        // Si es nulo, usa 0.0
        value: (json['value'] as num?)?.toDouble() ?? 0.0,
        // Si unit es nulo, usa un string vacío
        unit: json['unit'] as String? ?? '',
      );

  /// Crea una copia de la instancia [TestScore] con campos actualizados.
  /// Útil para la gestión de estado inmutable.
  TestScore copyWith({
    String? testId,
    double? value,
    String? unit,
  }) {
    return TestScore(
      testId: testId ?? this.testId,
      value: value ?? this.value,
      unit: unit ?? this.unit,
    );
  }

  // --- Métodos de Utilidad (Opcionales pero recomendados) ---

  @override
  String toString() {
    return 'TestScore(testId: $testId, value: $value, unit: $unit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is TestScore &&
      other.testId == testId &&
      other.value == value &&
      other.unit == unit;
  }

  @override
  int get hashCode => testId.hashCode ^ value.hashCode ^ unit.hashCode;
}