import '../../../core/network/api_client.dart';
import '../../../shared/models/alert_model.dart';
import '../../../shared/models/bus_model.dart';
import '../../../shared/models/conductor_shift_model.dart';
import '../../../shared/models/crowd_model.dart';
import '../../../shared/models/passenger_report_model.dart';
import '../../../shared/models/ticket_validation_result_model.dart';

abstract class IConductorRepository {
  Future<ConductorShiftModel> getConductorShift();
  Future<ConductorShiftModel> checkInForShift({String? dutyId});
  Future<ConductorShiftModel> pairBus({required String busNumber, required String routeNumber, String? tripCode});
  Future<ConductorShiftModel> startTrip({String? tripId, String? busNumber});
  Future<ConductorTripCompletionModel> completeTrip({String? tripId, String? notes});
  Future<TicketValidationResultModel> validateTicket({required String qrHash, required String busNumber});
  Future<PassengerReportModel> reportIncident(PassengerReportModel report);
  Future<List<AlertModel>> getCrewAlerts();
  Future<CrowdModel?> getBusOccupancy(String busNumber);
}

class ConductorRepository implements IConductorRepository {
  final ApiClient _apiClient;

  ConductorRepository(this._apiClient);

  @override
  Future<ConductorShiftModel> getConductorShift() async {
    try {
      final res = await _apiClient.get('/conductor/shift');
      if (res['data'] != null) {
        return ConductorShiftModel.fromJson(res['data'] as Map<String, dynamic>);
      }
      return const ConductorShiftModel(
        dutyId: 'DUTY-KL-402',
        staffName: 'Suresh Kumar',
        staffId: '22222222-2222-2222-2222-222222222222',
      );
    } catch (_) {
      return const ConductorShiftModel(
        dutyId: 'DUTY-KL-402',
        staffName: 'Suresh Kumar',
        staffId: '22222222-2222-2222-2222-222222222222',
        activeTrip: ConductorTripModel(
          tripId: 'trip-sim-205',
          tripCode: 'TRIP-205-ACTIVE',
          busNumber: '205',
          routeNumber: '12',
          origin: 'Aluva Metro Station',
          destination: 'Vyttila Mobility Hub',
          currentStop: 'Palarivattom Jn',
          nextStop: 'Kaloor Central Stand',
          status: 'ACTIVE',
        ),
      );
    }
  }

  @override
  Future<ConductorShiftModel> checkInForShift({String? dutyId}) async {
    try {
      final res = await _apiClient.post('/conductor/check-in', body: {'duty_id': dutyId ?? 'DUTY-KL-402'});
      if (res['data'] != null) {
        return ConductorShiftModel.fromJson(res['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return ConductorShiftModel(
      dutyId: dutyId ?? 'DUTY-KL-402',
      staffName: 'Suresh Kumar',
      staffId: '22222222-2222-2222-2222-222222222222',
      status: 'CHECKED_IN',
      checkInTime: DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<ConductorShiftModel> pairBus({
    required String busNumber,
    required String routeNumber,
    String? tripCode,
  }) async {
    try {
      final res = await _apiClient.post('/conductor/pair', body: {
        'bus_number': busNumber,
        'route_number': routeNumber,
        'trip_code': tripCode,
      });
      if (res['data'] != null) {
        return ConductorShiftModel.fromJson(res['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return ConductorShiftModel(
      dutyId: 'DUTY-KL-402',
      staffName: 'Suresh Kumar',
      staffId: '22222222-2222-2222-2222-222222222222',
      status: 'CHECKED_IN',
      pairingStatus: 'PAIRED',
      busNumber: busNumber,
      routeNumber: routeNumber,
    );
  }

  @override
  Future<ConductorShiftModel> startTrip({String? tripId, String? busNumber}) async {
    try {
      final res = await _apiClient.post('/conductor/start-trip', body: {
        'trip_id': tripId,
        'bus_number': busNumber,
      });
      if (res['data'] != null) {
        return ConductorShiftModel.fromJson(res['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return const ConductorShiftModel(
      dutyId: 'DUTY-KL-402',
      staffName: 'Suresh Kumar',
      staffId: '22222222-2222-2222-2222-222222222222',
      status: 'CHECKED_IN',
      pairingStatus: 'PAIRED',
      busNumber: '205',
      routeNumber: '12',
      activeTrip: ConductorTripModel(
        tripId: 'trip-sim-205',
        tripCode: 'TRIP-205-LIVE',
        busNumber: '205',
        routeNumber: '12',
        origin: 'Aluva Metro Station',
        destination: 'Vyttila Mobility Hub',
        currentStop: 'Aluva Metro Station',
        nextStop: 'Companypady',
        status: 'ACTIVE',
      ),
    );
  }

  @override
  Future<ConductorTripCompletionModel> completeTrip({String? tripId, String? notes}) async {
    try {
      final res = await _apiClient.post('/conductor/complete-trip', body: {
        'trip_id': tripId,
        'notes': notes,
      });
      if (res['data'] != null) {
        return ConductorTripCompletionModel.fromJson(res['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return ConductorTripCompletionModel(
      tripId: tripId ?? 'trip-sim-205',
      busNumber: '205',
      routeNumber: '12',
      completedAt: DateTime.now().toIso8601String(),
      notes: notes,
    );
  }

  @override
  Future<TicketValidationResultModel> validateTicket({required String qrHash, required String busNumber}) async {
    try {
      final res = await _apiClient.post('/tickets/validate', body: {
        'qr_code_hash': qrHash,
        'bus_number': busNumber,
      });
      if (res['data'] != null) {
        return TicketValidationResultModel.fromJson(res['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    // Fallback based on hash keywords for simulation
    if (qrHash.contains('used')) return TicketValidationResultModel.mockAlreadyUsed();
    if (qrHash.contains('expired')) return TicketValidationResultModel.mockExpired();
    if (qrHash.contains('invalid')) return TicketValidationResultModel.mockInvalid();
    return TicketValidationResultModel.mockValid();
  }

  @override
  Future<PassengerReportModel> reportIncident(PassengerReportModel report) async {
    try {
      final res = await _apiClient.post('/incidents/report', body: {
        'bus_number': report.busNumber ?? '205',
        'route_number': report.routeNumber ?? '12',
        'category': report.category,
        'severity': 'WARNING',
        'title': report.title,
        'description': report.description,
      });
      if (res['data'] != null) {
        final data = res['data'] as Map<String, dynamic>;
        return report.copyWith(
          id: data['id'] as String?,
          createdAt: data['created_at'] as String?,
        );
      }
    } catch (_) {}
    return report.copyWith(
      id: 'INC-KL-SIM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<List<AlertModel>> getCrewAlerts() async {
    try {
      final res = await _apiClient.get('/alerts');
      final list = res['data'] as List<dynamic>? ?? [];
      if (list.isNotEmpty) {
        return list.map((e) => AlertModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [
      AlertModel(
        id: 'alt-cond-1',
        title: 'Corridor Traffic: Edappally Bypass Bottleneck',
        message: 'Heavy vehicle delay of 8 minutes observed near Lulu Mall intersection. Transit priority lane active.',
        severity: 'WARNING',
        affectedRoute: 'Route 12',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(minutes: 12)).toIso8601String(),
      ),
      AlertModel(
        id: 'alt-cond-2',
        title: 'Cabin Load Advisory: Route 12 Peak',
        message: 'Cabin density expected to rise past 75% at Palarivattom Jn boarding stage.',
        severity: 'INFO',
        affectedRoute: 'Route 12',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)).toIso8601String(),
      ),
      AlertModel(
        id: 'alt-cond-3',
        title: 'Weather Notice: Moderate Monsoon Rain',
        message: 'Road surface wet along Aluva–Kaloor arterial corridor. Maintain safe braking buffer.',
        severity: 'INFO',
        affectedRoute: 'Greater Kochi Corridors',
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(minutes: 40)).toIso8601String(),
      ),
    ];
  }

  @override
  Future<CrowdModel?> getBusOccupancy(String busNumber) async {
    try {
      final res = await _apiClient.get('/occupancy/$busNumber');
      if (res['data'] != null) {
        return CrowdModel.fromJson(res['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return CrowdModel(
      busId: 'bus-$busNumber',
      busNumber: busNumber,
      occupancyPct: 41.8,
      passengerCount: 23,
      capacity: 55,
      crowdLevel: CrowdLevel.low,
      timestamp: DateTime.now().toIso8601String(),
      dataOrigin: 'SIMULATED DATA',
    );
  }
}
