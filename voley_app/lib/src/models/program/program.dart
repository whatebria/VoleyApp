// lib/src/models/program/program.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voley_app/src/models/program/mesocycles.dart'; // Ajusta el path si es necesario

class Program {
  final String id;
  final String source;
  final DateTime startDate;
  final DateTime endDate;
  final List<Mesocycle> mesocycles;

  Program({
    required this.id,
    required this.source,
    required this.startDate,
    required this.endDate,
    required this.mesocycles,
  });

  // --- CONSTRUCTOR fromJson CORREGIDO Y SEGURO ---
  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      id: json['id'] as String? ?? '',
      source: json['source'] as String? ?? 'Automático', // <-- Seguro
      
      // Maneja Timestamps nulos (aunque no debería pasar)
      startDate: (json['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (json['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      
      mesocycles: (json['mesocycles'] as List<dynamic>? ?? [])
          .map((mesoJson) => Mesocycle.fromJson(mesoJson as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source,
    'startDate': startDate,
    'endDate': endDate,
    'mesocycles': mesocycles.map((m) => m.toJson()).toList(),
  };

  // Constructor fromFirestore (para leer el ID del documento)
  factory Program.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Program.fromJson(data).copyWith(id: doc.id); 
  }

  // Método auxiliar 'copyWith'
  Program copyWith({String? id}) {
    return Program(
      id: id ?? this.id,
      source: this.source,
      startDate: this.startDate,
      endDate: this.endDate,
      mesocycles: this.mesocycles,
    );
  }
}