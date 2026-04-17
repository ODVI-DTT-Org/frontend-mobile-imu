/// Pending loan release stored in Hive when offline
class PendingRelease {
  final String id;
  final String clientId;
  final String timeIn;
  final String timeOut;
  final String odometerArrival;
  final String odometerDeparture;
  final String productType;
  final String loanType;
  final int? udiNumber;
  final String? remarks;
  final String? photoPath;
  final DateTime createdAt;

  PendingRelease({
    required this.id,
    required this.clientId,
    required this.timeIn,
    required this.timeOut,
    required this.odometerArrival,
    required this.odometerDeparture,
    required this.productType,
    required this.loanType,
    this.udiNumber,
    this.remarks,
    this.photoPath,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'timeIn': timeIn,
        'timeOut': timeOut,
        'odometerArrival': odometerArrival,
        'odometerDeparture': odometerDeparture,
        'productType': productType,
        'loanType': loanType,
        'udiNumber': udiNumber,
        'remarks': remarks,
        'photoPath': photoPath,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PendingRelease.fromJson(Map<String, dynamic> json) => PendingRelease(
        id: json['id'] as String,
        clientId: json['clientId'] as String,
        timeIn: json['timeIn'] as String,
        timeOut: json['timeOut'] as String,
        odometerArrival: json['odometerArrival'] as String,
        odometerDeparture: json['odometerDeparture'] as String,
        productType: json['productType'] as String,
        loanType: json['loanType'] as String,
        udiNumber: json['udiNumber'] as int?,
        remarks: json['remarks'] as String?,
        photoPath: json['photoPath'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
