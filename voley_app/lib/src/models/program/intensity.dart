import 'package:flutter/foundation.dart';

/// Define el tipo de intensidad que se está midiendo.
enum IntensityType {
  /// RPE (Rate of Perceived Exertion), ej: 8
  rpe,
  /// Porcentaje del 1RM (One-Rep Max), ej: 0.8 (para 80%)
  percent_1rm,
  /// Un peso fijo, ej: 100 (para 100kg)
  fixed_weight,
  /// Un rango de RPE, ej: 7-9 (se usa 'value' para el min, 'valueMax' para el max)
  rpe_range,
  /// Abierto (ej. "Al fallo", "Calentamiento"), el valor no es numérico.
  open
}

/// Helper para convertir String a/desde el enum IntensityType
extension IntensityTypeParsing on String {
  IntensityType toIntensityType() {
    return IntensityType.values.firstWhere(
      (e) => e.toString() == 'IntensityType.$this',
      orElse: () => IntensityType.open, // Valor por defecto
    );
  }
}

/// Un objeto estructurado para definir la prescripción de intensidad.
@immutable
class Intensity {
  /// El tipo de intensidad (RPE, %1RM, etc.)
  final IntensityType type;
  
  /// El valor principal.
  /// - Para RPE: 8
  /// - Para %1RM: 0.8 (representando 80%)
  /// - Para Peso Fijo: 100 (representando 100kg/lbs)
  /// - Para Rango RPE: 7 (el valor mínimo)
  final double value;

  /// El valor máximo, usado solo para tipos de rango (ej. 'rpe_range').
  final double? valueMax;

  /// Una etiqueta de texto opcional para tipos 'open'.
  /// Ej: "Al fallo", "Calentamiento"
  final String? label;

  const Intensity({
    required this.type,
    this.value = 0.0,
    this.valueMax,
    this.label,
  });

  /// Serializa la instancia a un mapa JSON.
  Map<String, dynamic> toJson() => {
        'type': type.toString().split('.').last, // Guarda el enum como String
        'value': value,
        'valueMax': valueMax,
        'label': label,
      };

  /// Crea una instancia desde un mapa JSON.
  static Intensity fromJson(Map<String, dynamic> json) => Intensity(
        type: (json['type'] as String? ?? 'open').toIntensityType(),
        value: (json['value'] as num?)?.toDouble() ?? 0.0,
        valueMax: (json['valueMax'] as num?)?.toDouble(),
        label: json['label'] as String?,
      );

  /// Crea una copia de la instancia con campos actualizados.
  Intensity copyWith({
    IntensityType? type,
    double? value,
    double? valueMax,
    String? label,
  }) {
    return Intensity(
      type: type ?? this.type,
      value: value ?? this.value,
      valueMax: valueMax ?? this.valueMax,
      label: label ?? this.label,
    );
  }

  @override
  String toString() {
    return 'Intensity(type: $type, value: $value, valueMax: $valueMax, label: $label)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Intensity &&
        other.type == type &&
        other.value == value &&
        other.valueMax == valueMax &&
        other.label == label;
  }

  @override
  int get hashCode => type.hashCode ^ value.hashCode ^ valueMax.hashCode ^ label.hashCode;
}