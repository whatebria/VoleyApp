import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voley_app/src/models/program/program.dart';

class ProgramTemplate {
  final String id;
  final String name;
  final String description;
  final Program program;
  final DateTime updatedAt;

  const ProgramTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.program,
    required this.updatedAt,
  });

  ProgramTemplate copyWith({
    String? id,
    String? name,
    String? description,
    Program? program,
    DateTime? updatedAt,
  }) {
    return ProgramTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      program: program ?? this.program,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProgramTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProgramTemplate(
      id: doc.id,
      name: data['name'] as String? ?? 'Plantilla',
      description: data['description'] as String? ?? '',
      program: Program.fromJson(data['program'] as Map<String, dynamic>),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'program': program.toJson(),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}