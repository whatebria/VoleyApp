// lib/models/Event.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de datos para el CATÁLOGO de Lesiones.
class Event {
  final String id;
  final String name;
  final String fechaInicio; 
  final String fechaFin;  
  final String importancia;  //(alta/media/baja)

  Event({
    required this.id,
    required this.name,
    required this.fechaInicio,
    required this.fechaFin,
    required this.importancia,
  });


  /// Convierte un DocumentSnapshot de Firebase a un objeto Event.
  factory Event.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Event(
      id: doc.id,
      name: data['name'] ?? 'Sin nombre',
      fechaInicio: data['fechaInicio'] ?? '',
      fechaFin: data['fechaFin'] ?? '',
      importancia: data['importancia'] ?? 'baja',
    );
  }

  /// Convierte un objeto Event a un Map<String, dynamic> para Firebase.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
      'importancia': importancia,
    };
  }
}