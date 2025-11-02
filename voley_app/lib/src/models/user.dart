import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  coach,

  player;

  String toJson() => name;

  static UserRole fromJson(String json) {
    return UserRole.values.firstWhere(
      (role) => role.name == json,

      orElse: () => UserRole.player,
    );
  }
}

class User {
  final String id;

  final String email;

  final String name;

  final UserRole role;

  final DateTime createdAt;

  final List<int> testScores;

  final String? coachId;

  User({
    required this.id,

    required this.email,

    required this.name,

    required this.role,

    required this.createdAt,

    this.testScores = const [],

    this.coachId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,

    'email': email,

    'name': name,

    'role': role.toJson(),

    'createdAt': Timestamp.fromDate(createdAt),
    'testScores': testScores,
    'coachId': coachId,
  };

  static User fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,

      email: json['email'] as String,

      name: json['name'] as String,

      role: UserRole.fromJson(json['role'] as String),

      createdAt: (json['createdAt'] as Timestamp).toDate(),
      testScores: List<int>.from(json['testScores'] ?? []),
      coachId: json['coachId'] as String?,
    );
  }

  User copyWith({
    String? id,

    String? email,

    String? name,

    UserRole? role,

    DateTime? createdAt,

    String? coachId,
  }) {
    return User(
      id: id ?? this.id,

      email: email ?? this.email,

      name: name ?? this.name,

      role: role ?? this.role,

      createdAt: createdAt ?? this.createdAt,

      coachId: coachId ?? this.coachId,
    );
  }

  bool get isCoach => role == UserRole.coach;

  bool get isPlayer => role == UserRole.player;
}

