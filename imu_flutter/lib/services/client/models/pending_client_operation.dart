import 'dart:convert';

enum ClientOperationType { create, update, delete }

class PendingClientOperation {
  final String id;
  final ClientOperationType operation;
  final String clientId;
  final Map<String, dynamic>? clientData;
  final DateTime createdAt;

  PendingClientOperation({
    required this.id,
    required this.operation,
    required this.clientId,
    this.clientData,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'operation': operation.name,
    'clientId': clientId,
    'clientData': clientData != null ? jsonEncode(clientData) : null,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PendingClientOperation.fromJson(Map<String, dynamic> json) =>
      PendingClientOperation(
        id: json['id'] as String,
        operation: ClientOperationType.values.firstWhere(
          (e) => e.name == json['operation'] as String,
        ),
        clientId: json['clientId'] as String,
        clientData: json['clientData'] != null
            ? Map<String, dynamic>.from(
                jsonDecode(json['clientData'] as String) as Map,
              )
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
