import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

@immutable
class Goal {
  final String id;
  final String description;
  final bool isCompleted;
  final DateTime? createdAt;

  const Goal({
    required this.id,
    required this.description,
    this.isCompleted = false,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'isCompleted': isCompleted,
        'createdAt': createdAt?.toIso8601String(),
      };

  static Goal fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'] as String? ?? const Uuid().v4(),
        description: json['description'] as String? ?? '',
        isCompleted: json['isCompleted'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  Goal copyWith({String? id, String? description, bool? isCompleted, DateTime? createdAt}) =>
      Goal(
        id: id ?? this.id,
        description: description ?? this.description,
        isCompleted: isCompleted ?? this.isCompleted,
        createdAt: createdAt ?? this.createdAt,
      );
}
