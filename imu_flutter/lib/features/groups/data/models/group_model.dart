class ClientGroup {
  final String id;
  final String name;
  final String? description;
  // PowerSync fields (from groups table)
  final String? areaManagerId;
  final String? assistantAreaManagerId;
  final String? caravanId;
  // Legacy API fields (kept for Hive-cached data backward compat)
  final String? teamLeaderId;
  final String? teamLeaderName;
  final int memberCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ClientGroup({
    required this.id,
    required this.name,
    this.description,
    this.areaManagerId,
    this.assistantAreaManagerId,
    this.caravanId,
    this.teamLeaderId,
    this.teamLeaderName,
    this.memberCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory ClientGroup.fromRow(Map<String, dynamic> row) {
    return ClientGroup(
      id: row['id'] as String,
      name: row['name'] as String,
      description: row['description'] as String?,
      areaManagerId: row['area_manager_id'] as String?,
      assistantAreaManagerId: row['assistant_area_manager_id'] as String?,
      caravanId: row['caravan_id'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  factory ClientGroup.fromJson(Map<String, dynamic> json, {String? id}) {
    final createdRaw = json['created_at'] ?? json['created'];
    return ClientGroup(
      id: id ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      areaManagerId: json['area_manager_id'] as String?,
      assistantAreaManagerId: json['assistant_area_manager_id'] as String?,
      caravanId: json['caravan_id'] as String?,
      teamLeaderId: json['team_leader_id'] as String? ?? json['team_leader'] as String?,
      teamLeaderName: json['expand']?['team_leader']?['name'] as String? ?? json['team_leader_name'] as String?,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      createdAt: createdRaw != null
          ? DateTime.parse(createdRaw as String)
          : DateTime.now(),
      updatedAt: (json['updated_at'] ?? json['updated']) != null
          ? DateTime.tryParse((json['updated_at'] ?? json['updated']) as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    if (areaManagerId != null) 'area_manager_id': areaManagerId,
    if (assistantAreaManagerId != null) 'assistant_area_manager_id': assistantAreaManagerId,
    if (caravanId != null) 'caravan_id': caravanId,
    if (teamLeaderId != null) 'team_leader_id': teamLeaderId,
    if (teamLeaderName != null) 'team_leader_name': teamLeaderName,
    'member_count': memberCount,
    'created_at': createdAt.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };

  ClientGroup copyWith({
    String? id,
    String? name,
    String? description,
    String? areaManagerId,
    String? assistantAreaManagerId,
    String? caravanId,
    String? teamLeaderId,
    String? teamLeaderName,
    int? memberCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      areaManagerId: areaManagerId ?? this.areaManagerId,
      assistantAreaManagerId: assistantAreaManagerId ?? this.assistantAreaManagerId,
      caravanId: caravanId ?? this.caravanId,
      teamLeaderId: teamLeaderId ?? this.teamLeaderId,
      teamLeaderName: teamLeaderName ?? this.teamLeaderName,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
