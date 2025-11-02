// En tu archivo program.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voley_app/src/models/program/mesocycles.dart';

class Program {
  final String id;
  final String source;
  final DateTime startDate;
  final DateTime endDate;
  final List<Mesocycle> mesocycles;

  // (Tu constructor existente)
  Program({
    required this.id,
    required this.source,
    required this.startDate,
    required this.endDate,
    required this.mesocycles,
  });

  // --- AÑADE ESTE CONSTRUCTOR ---
  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      // 'id' vendrá del documento, pero lo mantenemos por si lo guardas
      id: json['id'] ?? '',
      source: json['source'] ?? 'Desconocido',
      // Convertir Timestamp de Firestore a DateTime de Dart
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      // Convertir la lista de mapas anidada a una List<Mesocycle>
      mesocycles: (json['mesocycles'] as List<dynamic>? ?? [])
          .map((mesoJson) => Mesocycle.fromJson(mesoJson as Map<String, dynamic>))
          .toList(),
    );
  }
  
  // (Tu método toJson existente)
  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source,
    'startDate': startDate,
    'endDate': endDate,
    'mesocycles': mesocycles.map((m) => m.toJson()).toList(),
  };

  // (Opcional, pero recomendado): Añade este para llamar desde el snapshot
  factory Program.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Usa el ID del documento real
    return Program.fromJson(data).copyWith(id: doc.id); 
  }

  // (Opcional): Añade esto para que 'fromFirestore' funcione
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