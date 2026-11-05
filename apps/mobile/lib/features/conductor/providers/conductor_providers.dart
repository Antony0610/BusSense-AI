import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../shared/models/alert_model.dart';
import '../../../shared/models/conductor_shift_model.dart';
import '../../../shared/models/crowd_model.dart';
import '../../../shared/models/ticket_validation_result_model.dart';
import '../data/conductor_repository.dart';

/// Conductor Repository Provider
final conductorRepositoryProvider = Provider<IConductorRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ConductorRepository(apiClient);
});

/// Conductor Shift State Notifier
class ConductorShiftNotifier extends StateNotifier<AsyncValue<ConductorShiftModel>> {
  final IConductorRepository _repository;

  ConductorShiftNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchShift();
  }

  Future<void> fetchShift() async {
    state = const AsyncValue.loading();
    try {
      final shift = await _repository.getConductorShift();
      state = AsyncValue.data(shift);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> checkIn({String? dutyId}) async {
    try {
      final updated = await _repository.checkInForShift(dutyId: dutyId);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> pairBus({required String busNumber, required String routeNumber, String? tripCode}) async {
    try {
      final updated = await _repository.pairBus(
        busNumber: busNumber,
        routeNumber: routeNumber,
        tripCode: tripCode,
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> startTrip() async {
    final current = state.valueOrNull;
    if (current == null) return;
    try {
      final updated = await _repository.startTrip(
        tripId: current.activeTrip?.tripId,
        busNumber: current.busNumber,
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<ConductorTripCompletionModel?> completeTrip({String? notes}) async {
    final current = state.valueOrNull;
    if (current == null) return null;
    try {
      final summary = await _repository.completeTrip(
        tripId: current.activeTrip?.tripId,
        notes: notes,
      );
      // Update local state trip status to COMPLETED
      state = AsyncValue.data(current.copyWith(
        activeTrip: current.activeTrip?.copyWith(status: 'COMPLETED'),
      ));
      return summary;
    } catch (e) {
      return null;
    }
  }
}

final conductorShiftProvider = StateNotifierProvider<ConductorShiftNotifier, AsyncValue<ConductorShiftModel>>((ref) {
  final repo = ref.watch(conductorRepositoryProvider);
  return ConductorShiftNotifier(repo);
});

/// Crew Alerts Provider
final conductorAlertsProvider = FutureProvider<List<AlertModel>>((ref) async {
  final repo = ref.watch(conductorRepositoryProvider);
  return repo.getCrewAlerts();
});

/// Real-time Bus Occupancy Provider for Conductor
final conductorOccupancyProvider = FutureProvider.family<CrowdModel?, String>((ref, busNumber) async {
  final repo = ref.watch(conductorRepositoryProvider);
  return repo.getBusOccupancy(busNumber);
});

/// Ticket Validation State
class TicketValidationState {
  final bool isLoading;
  final TicketValidationResultModel? result;
  final String? errorMessage;

  const TicketValidationState({
    this.isLoading = false,
    this.result,
    this.errorMessage,
  });

  TicketValidationState copyWith({
    bool? isLoading,
    TicketValidationResultModel? result,
    String? errorMessage,
  }) {
    return TicketValidationState(
      isLoading: isLoading ?? this.isLoading,
      result: result,
      errorMessage: errorMessage,
    );
  }
}

class TicketValidationNotifier extends StateNotifier<TicketValidationState> {
  final IConductorRepository _repository;

  TicketValidationNotifier(this._repository) : super(const TicketValidationState());

  Future<TicketValidationResultModel> validate({
    required String qrHash,
    required String busNumber,
  }) async {
    state = const TicketValidationState(isLoading: true);
    try {
      final result = await _repository.validateTicket(qrHash: qrHash, busNumber: busNumber);
      state = TicketValidationState(isLoading: false, result: result);
      return result;
    } catch (e) {
      final fallback = TicketValidationResultModel.mockInvalid();
      state = TicketValidationState(
        isLoading: false,
        result: fallback,
        errorMessage: 'Network verification failed.',
      );
      return fallback;
    }
  }

  void reset() {
    state = const TicketValidationState();
  }
}

final ticketValidationProvider = StateNotifierProvider<TicketValidationNotifier, TicketValidationState>((ref) {
  final repo = ref.watch(conductorRepositoryProvider);
  return TicketValidationNotifier(repo);
});
