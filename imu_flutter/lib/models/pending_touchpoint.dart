import 'package:imu_flutter/features/clients/data/models/client_model.dart';

class PendingTouchpoint {
  final String id;
  final String clientId;
  final Touchpoint touchpoint;
  final DateTime createdAt;
  final String? photoPath;
  final String? audioPath;

  PendingTouchpoint({
    required this.id,
    required this.clientId,
    required this.touchpoint,
    required this.createdAt,
    this.photoPath,
    this.audioPath,
  });

  factory PendingTouchpoint.fromJson(Map<String, dynamic> json) {
    return PendingTouchpoint(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      touchpoint: Touchpoint.fromJson(json['touchpoint'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      photoPath: json['photoPath'] as String?,
      audioPath: json['audioPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'touchpoint': touchpoint.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'photoPath': photoPath,
      'audioPath': audioPath,
    };
  }
}
