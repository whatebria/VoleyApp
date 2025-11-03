// lib/src/models/program/program.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voley_app/src/models/program/mesocycles.dart'; // Ajusta el path si es necesario

class Program {
  final String id;
  final String title;
  final String source;
  final DateTime startDate;
  final DateTime endDate;
  final List<Mesocycle> mesocycles;

  Program({
    required this.id,
    required this.title,
    required this.source,
    required this.startDate,
    required this.endDate,
    required this.mesocycles,
  });

  // --- CONSTRUCTOR fromJson CORREGIDO Y SEGURO ---
  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      source: json['source'] as String? ?? 'Automático',
      startDate: (json['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (json['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mesocycles: (json['mesocycles'] as List<dynamic>? ?? [])
          .map(
            (mesoJson) => Mesocycle.fromJson(mesoJson as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'source': source,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'mesocycles': mesocycles.map((m) => m.toJson()).toList(),
  };

  // Constructor fromFirestore (para leer el ID del documento)
  factory Program.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Añade el ID del documento a los datos antes de parsear
    data['id'] = doc.id;
    return Program.fromJson(data);
  }

  // Método auxiliar 'copyWith'
  Program copyWith({
    String? id,
    String? title,
    String? source,
    DateTime? startDate,
    DateTime? endDate,
    List<Mesocycle>? mesocycles,
  }) {
    return Program(
      id: id ?? this.id,
      title: title ?? this.title,
      source: source ?? this.source,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      mesocycles: mesocycles ?? this.mesocycles,
    );
  }
}
