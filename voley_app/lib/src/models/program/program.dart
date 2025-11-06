import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:voley_app/src/models/program/mesocycle.dart';
import 'package:voley_app/utils/common/utils.dart';

@immutable
class Program {
  final String id;
  final String title;
  final String source; // autor/origen
  final DateTime startDate;
  final DateTime endDate;
  final List<Mesocycle> mesocycles;

  const Program({
    required this.id,
    required this.title,
    required this.source,
    required this.startDate,
    required this.endDate,
    this.mesocycles = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'source': source,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'mesocycles': mesocycles.map((m) => m.toJson()).toList(),
  };

  static Program fromJson(Map<String, dynamic> json) => Program(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    source: json['source'] as String? ?? '',
    startDate: ModelUtils.parseDateFlex(json['startDate']) ?? DateTime.now(),
    endDate: ModelUtils.parseDateFlex(json['endDate']) ?? DateTime.now(),
    mesocycles: ((json['mesocycles'] as List?) ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Mesocycle.fromJson)
        .toList(),
  );

  Program copyWith({
    String? id,
    String? title,
    String? source,
    DateTime? startDate,
    DateTime? endDate,
    List<Mesocycle>? mesocycles,
  }) => Program(
    id: id ?? this.id,
    title: title ?? this.title,
    source: source ?? this.source,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    mesocycles: mesocycles ?? this.mesocycles,
  );

  @override
  String toString() =>
      'Program($title • ${startDate.toIso8601String()} → ${endDate.toIso8601String()})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Program && other.id == id;

  @override
  int get hashCode => id.hashCode;
  
  factory Program.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>)..['id'] = doc.id;
    return Program.fromJson(data); // si ya tienes fromJson
  }
}
