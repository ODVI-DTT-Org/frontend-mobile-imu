/// Performance target for field agents
class Target {
  final String id;
  final String userId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final TargetPeriod period;
  final int clientVisitsTarget;
  final int clientVisitsCompleted;
  final int touchpointsTarget;
  final int touchpointsCompleted;
  final int newClientsTarget;
  final int newClientsAdded;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Target({
    required this.id,
    required this.userId,
    required this.periodStart,
    required this.periodEnd,
    required this.period,
    required this.clientVisitsTarget,
    this.clientVisitsCompleted = 0,
    required this.touchpointsTarget,
    this.touchpointsCompleted = 0,
    required this.newClientsTarget,
    this.newClientsAdded = 0,
    required this.createdAt,
    this.updatedAt,
  });

  /// Calculate overall progress as percentage (0.0 to 1.0)
  double get overallProgress {
    final total = clientVisitsTarget + touchpointsTarget + newClientsTarget;
    if (total == 0) return 0;
    final completed = clientVisitsCompleted + touchpointsCompleted + newClientsAdded;
    return completed / total;
  }

  /// Determine target status based on progress vs elapsed time
  TargetStatus get status {
    final progress = overallProgress;
    final now = DateTime.now();
    final elapsed = now.difference(periodStart).inDays;
    final total = periodEnd.difference(periodStart).inDays;
    final expected = total > 0 ? elapsed / total : 0;

    if (progress >= expected) return TargetStatus.onTrack;
    if (progress >= expected * 0.8) return TargetStatus.atRisk;
    return TargetStatus.behind;
  }

  /// Get progress for individual metric
  double get clientVisitsProgress {
    if (clientVisitsTarget == 0) return 0;
    return clientVisitsCompleted / clientVisitsTarget;
  }

  double get touchpointsProgress {
    if (touchpointsTarget == 0) return 0;
    return touchpointsCompleted / touchpointsTarget;
  }

  double get newClientsProgress {
    if (newClientsTarget == 0) return 0;
    return newClientsAdded / newClientsTarget;
  }

  /// Get period label for display
  String get periodLabel {
    switch (period) {
      case TargetPeriod.daily:
        return 'Today';
      case TargetPeriod.weekly:
        return 'This Week';
      case TargetPeriod.monthly:
        return 'This Month';
    }
  }

  Target copyWith({
    String? id,
    String? userId,
    DateTime? periodStart,
    DateTime? periodEnd,
    TargetPeriod? period,
    int? clientVisitsTarget,
    int? clientVisitsCompleted,
    int? touchpointsTarget,
    int? touchpointsCompleted,
    int? newClientsTarget,
    int? newClientsAdded,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Target(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      period: period ?? this.period,
      clientVisitsTarget: clientVisitsTarget ?? this.clientVisitsTarget,
      clientVisitsCompleted: clientVisitsCompleted ?? this.clientVisitsCompleted,
      touchpointsTarget: touchpointsTarget ?? this.touchpointsTarget,
      touchpointsCompleted: touchpointsCompleted ?? this.touchpointsCompleted,
      newClientsTarget: newClientsTarget ?? this.newClientsTarget,
      newClientsAdded: newClientsAdded ?? this.newClientsAdded,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'periodStart': periodStart.toIso8601String(),
    'periodEnd': periodEnd.toIso8601String(),
    'period': period.name,
    'clientVisitsTarget': clientVisitsTarget,
    'clientVisitsCompleted': clientVisitsCompleted,
    'touchpointsTarget': touchpointsTarget,
    'touchpointsCompleted': touchpointsCompleted,
    'newClientsTarget': newClientsTarget,
    'newClientsAdded': newClientsAdded,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory Target.fromRow(Map<String, dynamic> row) {
    final period = TargetPeriod.values.firstWhere(
      (e) => e.name == (row['period'] as String? ?? 'monthly'),
      orElse: () => TargetPeriod.monthly,
    );
    final year = (row['year'] as num).toInt();
    final month = row['month'] != null ? (row['month'] as num).toInt() : DateTime.now().month;

    // Compute periodStart/periodEnd from year/month for compatibility with existing UI
    final periodStart = DateTime(year, month, 1);
    final periodEnd = DateTime(year, month + 1, 0); // last day of month

    return Target(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      periodStart: periodStart,
      periodEnd: periodEnd,
      period: period,
      clientVisitsTarget: (row['target_visits'] as num?)?.toInt() ?? 0,
      touchpointsTarget: (row['target_touchpoints'] as num?)?.toInt() ?? 0,
      newClientsTarget: (row['target_clients'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: row['updated_at'] != null
          ? DateTime.tryParse(row['updated_at'] as String)
          : null,
    );
  }

  factory Target.fromJson(Map<String, dynamic> json) {
    return Target(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      periodStart: DateTime.parse(json['periodStart']),
      periodEnd: DateTime.parse(json['periodEnd']),
      period: TargetPeriod.values.firstWhere(
        (e) => e.name == json['period'],
        orElse: () => TargetPeriod.weekly,
      ),
      clientVisitsTarget: json['clientVisitsTarget'] ?? 0,
      clientVisitsCompleted: json['clientVisitsCompleted'] ?? 0,
      touchpointsTarget: json['touchpointsTarget'] ?? 0,
      touchpointsCompleted: json['touchpointsCompleted'] ?? 0,
      newClientsTarget: json['newClientsTarget'] ?? 0,
      newClientsAdded: json['newClientsAdded'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }
}

enum TargetPeriod { daily, weekly, monthly }

enum TargetStatus { onTrack, atRisk, behind }
