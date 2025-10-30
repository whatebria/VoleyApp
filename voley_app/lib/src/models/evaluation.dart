// lib/models/evaluation.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para un documento en la subcolección 'evaluations'.
class Evaluation {
  final String evaluationId;
  final String date;
  final Map<String, TestResult> tests;
  final Map<String, String> mobility;
  final List<String> injuriesDetected;
  final String notes;
  final String generatedPriority;
  final List<String> recommendations;

  Evaluation({
    required this.evaluationId,
    required this.date,
    required this.tests,
    required this.mobility,
    required this.injuriesDetected,
    required this.notes,
    required this.generatedPriority,
    required this.recommendations,
  });

  /// Crea un [Evaluation] desde un [DocumentSnapshot] de Firebase.
  factory Evaluation.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Parsear el mapa de 'tests'
    final testsMap = data['tests'] as Map<String, dynamic>? ?? {};
    final tests = testsMap.map((key, value) {
      return MapEntry(
          key, TestResult.fromMap(value as Map<String, dynamic>));
    });

    return Evaluation(
      evaluationId: doc.id,
      date: data['date'] ?? '',
      tests: tests,
      mobility: Map<String, String>.from(data['mobility'] ?? {}),
      injuriesDetected: List<String>.from(data['injuriesDetected'] ?? []),
      notes: data['notes'] ?? '',
      generatedPriority: data['generatedPriority'] ?? '',
      recommendations: List<String>.from(data['recommendations'] ?? []),
    );
  }

  /// Convierte el objeto [Evaluation] a un [Map] para Firebase.
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'tests': tests.map((key, value) => MapEntry(key, value.toMap())),
      'mobility': mobility,
      'injuriesDetected': injuriesDetected,
      'notes': notes,
      'generatedPriority': generatedPriority,
      'recommendations': recommendations,
    };
  }
}

// --- Clase Auxiliar Anidada ---

/// Modelo para los objetos dentro del mapa 'tests'
class TestResult {
  final dynamic result; // Puede ser int, double o string
  final String unit;
  final String category;

  TestResult({
    required this.result,
    required this.unit,
    required this.category,
  });

  factory TestResult.fromMap(Map<String, dynamic> map) {
    return TestResult(
      result: map['result'], // Mantenemos el tipo dinámico
      unit: map['unit'] ?? '',
      category: map['category'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'result': result,
      'unit': unit,
      'category': category,
    };
  }
}