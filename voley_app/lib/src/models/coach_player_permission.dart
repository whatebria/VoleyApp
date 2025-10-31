import 'package:cloud_firestore/cloud_firestore.dart';

enum PermissionStatus {
  pending,

  accepted,

  rejected;

  String toJson() => name;

  static PermissionStatus fromJson(String json) {
    return PermissionStatus.values.firstWhere(
      (status) => status.name == json,

      orElse: () => PermissionStatus.pending,
    );
  }
}

class CoachPlayerPermission {
  final String id;

  final String coachId;

  final String playerId;

  final PermissionStatus status;

  final DateTime createdAt;

  final DateTime? updatedAt;

  CoachPlayerPermission({
    required this.id,

    required this.coachId,

    required this.playerId,

    required this.status,

    required this.createdAt,

    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,

    'coachId': coachId,

    'playerId': playerId,

    'status': status.toJson(),

    'createdAt': Timestamp.fromDate(createdAt),

    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
  };

  static CoachPlayerPermission fromJson(Map<String, dynamic> json) {
    return CoachPlayerPermission(
      id: json['id'] as String,

      coachId: json['coachId'] as String,

      playerId: json['playerId'] as String,

      status: PermissionStatus.fromJson(json['status'] as String),

      createdAt: (json['createdAt'] as Timestamp).toDate(),

      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  CoachPlayerPermission copyWith({
    String? id,

    String? coachId,

    String? playerId,

    PermissionStatus? status,

    DateTime? createdAt,

    DateTime? updatedAt,
  }) {
    return CoachPlayerPermission(
      id: id ?? this.id,

      coachId: coachId ?? this.coachId,

      playerId: playerId ?? this.playerId,

      status: status ?? this.status,

      createdAt: createdAt ?? this.createdAt,

      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPending => status == PermissionStatus.pending;

  bool get isAccepted => status == PermissionStatus.accepted;

  bool get isRejected => status == PermissionStatus.rejected;
}
