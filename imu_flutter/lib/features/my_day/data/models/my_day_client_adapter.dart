import 'my_day_client.dart';
import '../../../clients/data/models/client_model.dart';
import '../../../clients/data/models/touchpoint_validation_model.dart';

/// Adapter that wraps MyDayClient to provide Client-like interface
/// Allows MyDayClient to work with ClientListCard widget
class MyDayClientAdapter {
  final MyDayClient _myDayClient;

  MyDayClientAdapter(this._myDayClient);

  String get id => _myDayClient.clientId;
  String get itineraryId => _myDayClient.id;

  /// Returns client name in "LastName, FirstName MiddleName" format
  /// MyDayClient stores fullName, so we use it directly
  String get fullName => _myDayClient.fullName;

  bool get loanReleased => false; // MyDayClient doesn't have this field
  String? get udi => null; // MyDayClient doesn't have this field

  /// Returns the location as full address
  String? get fullAddress => _myDayClient.location;

  /// Synthetic touchpoints list from previous touchpoint info
  List<Touchpoint> get touchpoints {
    if (_myDayClient.previousTouchpointNumber != null) {
      return [
        Touchpoint(
          id: '',
          touchpointNumber: _myDayClient.previousTouchpointNumber!,
          type: _parseTouchpointType(_myDayClient.previousTouchpointType),
          reason: _parseTouchpointReason(_myDayClient.previousTouchpointReason),
          status: TouchpointStatus.interested,
          date: _myDayClient.previousTouchpointDate ?? DateTime.now(),
          userId: null,
          photoPath: null,
          audioPath: null,
          locationData: null,
          timeIn: null,
          timeInGpsLat: null,
          timeInGpsLng: null,
          timeInGpsAddress: null,
          timeOut: null,
          timeOutGpsLat: null,
          timeOutGpsLng: null,
          timeOutGpsAddress: null,
        ),
      ];
    }
    return [];
  }

  /// Check if client has any touchpoints
  bool get hasTouchpoints => _myDayClient.previousTouchpointNumber != null;

  TouchpointType _parseTouchpointType(String? type) {
    if (type?.toLowerCase() == 'visit') {
      return TouchpointType.visit;
    }
    return TouchpointType.call;
  }

  TouchpointReason? _parseTouchpointReason(String? reason) {
    if (reason == null) return null;
    try {
      return TouchpointReason.values.firstWhere(
        (r) => r.apiValue.toLowerCase() == reason.toLowerCase(),
        orElse: () => TouchpointReason.followUp,
      );
    } catch (_) {
      return TouchpointReason.followUp;
    }
  }

  /// Get client type (default to existing)
  String get clientType => 'EXISTING';

  /// Convert to MyDayClient if needed
  MyDayClient get toMyDayClient => _myDayClient;
}
