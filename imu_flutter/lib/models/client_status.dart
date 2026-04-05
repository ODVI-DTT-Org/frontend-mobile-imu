/// Client status information for UI display
class ClientStatus {
  final bool inItinerary;
  final bool loanReleased;

  const ClientStatus({
    required this.inItinerary,
    required this.loanReleased,
  });

  /// CopyWith method for creating modified copies
  ClientStatus copyWith({bool? inItinerary, bool? loanReleased}) {
    return ClientStatus(
      inItinerary: inItinerary ?? this.inItinerary,
      loanReleased: loanReleased ?? this.loanReleased,
    );
  }

  /// Create from JSON (for API responses)
  factory ClientStatus.fromJson(Map<String, dynamic> json) {
    return ClientStatus(
      inItinerary: json['inItinerary'] ?? false,
      loanReleased: json['loanReleased'] ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'inItinerary': inItinerary,
      'loanReleased': loanReleased,
    };
  }
}
