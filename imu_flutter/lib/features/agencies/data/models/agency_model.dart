import 'package:imu_flutter/features/clients/data/models/client_model.dart';

/// Agency status enum
enum AgencyStatus {
  open,
  forImplementation,
  forReimplementation,
}

/// Agency data model
class Agency {
  final String id;
  final String name;
  final String address;
  final String contactNumber;
  final String type;
  final AgencyStatus status;
  final String? email;
  final String? description;
  final List<Client> assignedClients;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Agency({
    required this.id,
    required this.name,
    required this.address,
    required this.contactNumber,
    required this.type,
    required this.status,
    this.email,
    this.description,
    this.assignedClients = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory Agency.fromJson(Map<String, dynamic> json, {String? id}) {
    return Agency(
      id: id ?? json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      contactNumber: json['contact_number'] ?? json['contactNumber'] ?? '',
      type: json['type'] ?? 'Government',
      status: _parseStatus(json['status']),
      email: json['email'],
      description: json['description'],
      assignedClients: json['assigned_clients'] != null
          ? (json['assigned_clients'] as List)
              .map((client) => Client.fromJson(client))
              .toList()
          : [],
      createdAt: DateTime.parse(json['created'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated'] != null || json['updated_at'] != null
          ? DateTime.parse(json['updated'] ?? json['updated_at'])
          : null,
    );
  }

  static AgencyStatus _parseStatus(dynamic status) {
    if (status == null) return AgencyStatus.open;
    final statusStr = status.toString().toLowerCase();
    if (statusStr.contains('implementation')) {
      return statusStr.contains('re') ? AgencyStatus.forReimplementation : AgencyStatus.forImplementation;
    }
    return AgencyStatus.open;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'contact_number': contactNumber,
      'type': type,
      'status': status.name,
      if (email != null) 'email': email,
      if (description != null) 'description': description,
      'created': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated': updatedAt!.toIso8601String(),
    };
  }

  Agency copyWith({
    String? id,
    String? name,
    String? address,
    String? contactNumber,
    String? type,
    AgencyStatus? status,
    String? email,
    String? description,
    List<Client>? assignedClients,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Agency(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      type: type ?? this.type,
      status: status ?? this.status,
      email: email ?? this.email,
      description: description ?? this.description,
      assignedClients: assignedClients ?? this.assignedClients,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
