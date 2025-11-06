import 'package:flutter/foundation.dart';
import 'package:voley_app/utils/common/utils.dart';

/// Tipos de intensidad soportados.
/// Usamos nombres consistentes con el resto de enums.
enum IntensityType {
  rpe,          // p. ej. 8
  percent1rm,   // 0.8 representa 80%
  loadkg,       // carga absoluta en kg
  rpeRange,    // rango RPE: value=min, valueMax=max
  open,         // etiqueta libre: "Al fallo", "Calentamiento"
}

@immutable
class Intensity {
  final IntensityType type;
  final double value;     // RPE, %1RM (0..1), kg, o minRPE si es rpe_range
  final double? valueMax; // solo para rpe_range
  final String? label;    // solo para open

  const Intensity({
    required this.type,
    required this.value,
    this.valueMax,
    this.label,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'value': value,
    'valueMax': valueMax,
    'label': label,
  };

  /// Acepta nombres antiguos como 'percent_1rm' y 'fixed_weight' para compat.
  static Intensity fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] as String?) ?? 'open';
    final normalized = _normalizeTypeName(rawType);
    final type = ModelUtils.enumByName(IntensityType.values, normalized, IntensityType.open);

    return Intensity(
      type: type,
      value: (json['value'] as num?)?.toDouble() ?? 0,
      valueMax: (json['valueMax'] as num?)?.toDouble(),
      label: json['label'] as String?,
    );
  }

  /// Convierte etiquetas antiguas a las nuevas.
  static String _normalizeTypeName(String name) {
    switch (name) {
      case 'percent_1rm': return 'percent1rm';
      case 'fixed_weight': return 'loadkg';
      default: return name;
    }
  }

  Intensity copyWith({
    IntensityType? type,
    double? value,
    double? valueMax,
    String? label,
  }) => Intensity(
    type: type ?? this.type,
    value: value ?? this.value,
    valueMax: valueMax ?? this.valueMax,
    label: label ?? this.label,
  );

  @override
  String toString() => 'Intensity(type: ${type.name}, value: $value, valueMax: $valueMax, label: $label)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Intensity &&
        other.type == type &&
        other.value == value &&
        other.valueMax == valueMax &&
        other.label == label;

  @override
  int get hashCode => type.hashCode ^ value.hashCode ^ valueMax.hashCode ^ label.hashCode;
// Named factories
  factory Intensity.rpe(double v) => Intensity(type: IntensityType.rpe, value: v);
  factory Intensity.percent1rm(double v01) => Intensity(type: IntensityType.percent1rm, value: v01);
  factory Intensity.loadkg(double kg) => Intensity(type: IntensityType.loadkg, value: kg);
  factory Intensity.rpeRange(double min, double max) => Intensity(type: IntensityType.rpeRange, value: min, valueMax: max);
  factory Intensity.open([String? label]) => Intensity(type: IntensityType.open, value: 0, label: label);

  // Parser de texto tipo "RPE 7", "80%", "100kg", "RPE 7-9"
  static Intensity parse(String raw) {
    final t = raw.trim().toLowerCase();

    final rpeRange = RegExp(r'rpe\s*(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)');
    final rpeOne   = RegExp(r'rpe\s*(\d+(?:\.\d+)?)');
    final pct      = RegExp(r'(\d+(?:\.\d+)?)\s*%');
    final kg       = RegExp(r'(\d+(?:\.\d+)?)\s*kg');

    if (rpeRange.hasMatch(t)) {
      final m = rpeRange.firstMatch(t)!;
      return Intensity.rpeRange(double.parse(m.group(1)!), double.parse(m.group(2)!));
    }
    if (rpeOne.hasMatch(t)) {
      final m = rpeOne.firstMatch(t)!;
      return Intensity.rpe(double.parse(m.group(1)!));
    }
    if (pct.hasMatch(t)) {
      final m = pct.firstMatch(t)!;
      return Intensity.percent1rm(double.parse(m.group(1)!) / 100.0);
    }
    if (kg.hasMatch(t)) {
      final m = kg.firstMatch(t)!;
      return Intensity.loadkg(double.parse(m.group(1)!));
    }
    return Intensity.open(raw.isEmpty ? null : raw);
  }
}
