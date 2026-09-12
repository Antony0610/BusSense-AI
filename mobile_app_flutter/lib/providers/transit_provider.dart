import 'dart:async';
import 'package:flutter/material.dart';
import '../models/transit_models.dart';
import '../services/api_service.dart';

class TransitProvider extends ChangeNotifier {
  String _currentRole = 'passenger'; // 'passenger' or 'authority'
  String _currentLang = 'en'; // 'en' or 'ml'
  String _activeRoute = 'ALL';
  List<BusModel> _buses = [];
  final List<SOSAlertModel> _activeSosIncidents = [];
  bool _isLoading = false;
  BusModel? _selectedBus;
  TicketModel? _activeTicket;
  Timer? _pollingTimer;

  String get currentRole => _currentRole;
  String get currentLang => _currentLang;
  String get activeRoute => _activeRoute;
  List<BusModel> get buses => _buses;
  List<SOSAlertModel> get activeSosIncidents => _activeSosIncidents;
  bool get isLoading => _isLoading;
  BusModel? get selectedBus => _selectedBus;
  TicketModel? get activeTicket => _activeTicket;

  TransitProvider() {
    refreshBuses();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      refreshBuses(silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void switchRole(String role) {
    _currentRole = role;
    notifyListeners();
  }

  void toggleLanguage() {
    _currentLang = _currentLang == 'en' ? 'ml' : 'en';
    notifyListeners();
  }

  void setActiveRoute(String route) {
    _activeRoute = route;
    notifyListeners();
  }

  void selectBus(BusModel bus) {
    _selectedBus = bus;
    notifyListeners();
  }

  Future<void> refreshBuses({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    _buses = await TransitApiService.fetchBuses(routeNumber: _activeRoute);
    _isLoading = false;
    notifyListeners();
  }

  Future<TicketModel?> bookSeat({
    required String busId,
    required String routeNumber,
    required String seatNumber,
    required String originStop,
    required String destinationStop,
    required double fareAmount,
  }) async {
    final ticket = await TransitApiService.bookSeat(
      busId: busId,
      routeNumber: routeNumber,
      seatNumber: seatNumber,
      originStop: originStop,
      destinationStop: destinationStop,
      fareAmount: fareAmount,
    );

    if (ticket != null) {
      _activeTicket = ticket;
      notifyListeners();
    }
    return ticket;
  }

  Future<SOSAlertModel?> triggerSOS({
    required double latitude,
    required double longitude,
    required String busId,
    required String routeNumber,
  }) async {
    final alert = await TransitApiService.triggerSOS(
      latitude: latitude,
      longitude: longitude,
      busId: busId,
      routeNumber: routeNumber,
    );

    if (alert != null) {
      _activeSosIncidents.insert(0, alert);
      notifyListeners();
    }
    return alert;
  }

  void resolveSOS(String sosId) {
    _activeSosIncidents.removeWhere((item) => item.sosId == sosId);
    notifyListeners();
  }

  Future<bool> deployReliefBus({
    required String routeNumber,
    required String reason,
  }) async {
    final success = await TransitApiService.dispatchReliefBus(
      routeNumber: routeNumber,
      reason: reason,
    );
    if (success) {
      refreshBuses(silent: true);
    }
    return success;
  }
}
