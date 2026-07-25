import 'package:flutter/material.dart';
import '../models/bus_model.dart';
import '../services/api_service.dart';

class BusProvider extends ChangeNotifier {
  List<BusModel> _buses = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  bool _isDarkMode = true;
  String _language = 'en'; // 'en' or 'ml'
  String _sourceSearch = 'Thampanoor';
  String _destinationSearch = 'Technopark';

  List<BusModel> get buses => _buses;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  String get sourceSearch => _sourceSearch;
  String get destinationSearch => _destinationSearch;

  BusProvider() {
    loadData();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }

  void updateRouteSearch(String src, String dest) {
    _sourceSearch = src;
    _destinationSearch = dest;
    notifyListeners();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _buses = await ApiService.fetchBuses();
    _stats = await ApiService.fetchStats();

    _isLoading = false;
    notifyListeners();
  }

  List<BusModel> get sortedByComfort {
    final list = List<BusModel>.from(_buses);
    list.sort((a, b) => b.comfortScore.compareTo(a.comfortScore));
    return list;
  }
}
