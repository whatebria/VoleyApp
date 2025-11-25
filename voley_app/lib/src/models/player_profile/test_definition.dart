import 'package:flutter/foundation.dart';

@immutable
class TestDefinition {
  const TestDefinition({
    required this.id,
    required this.label,
    required this.unit,
    this.description,
  });

  final String id;
  final String label;
  final String unit;
  final String? description;
}
