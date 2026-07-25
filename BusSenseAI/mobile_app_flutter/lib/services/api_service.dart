import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bus_model.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000'; // Standard Android emulator localhost alias or http://localhost:5000

  static Future<List<BusModel>> fetchBuses() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/buses')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => BusModel.fromJson(json)).toList();
      }
    } catch (e) {
      // Fallback sample data if server is offline
    }
    return _fallbackBuses();
  }

  static Future<Map<String, dynamic>> fetchStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/stats')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // Fallback stats
    }
    return {
      'average_occupancy': 52.4,
      'bus_utilization_score': 68.5,
      'estimated_co2_reduction_kg': 42.6,
      'estimated_fuel_savings_litres': 15.9,
    };
  }

  static Future<bool> submitPassengerReport(String busId, String reportType, String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'bus_id': busId,
          'report_type': reportType,
          'message': message,
          'latitude': 8.5241,
          'longitude': 76.9366,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static List<BusModel> _fallbackBuses() {
    return [
      BusModel(
        busId: 'KSRTC-101',
        operatorType: 'KSRTC',
        routeNumber: 'R1',
        capacity: 50,
        passengerCount: 24,
        occupancyPercentage: 48.0,
        seatAvailability: 26,
        latitude: 8.5241,
        longitude: 76.9366,
        etaMinutes: 6,
        crowdLevel: 'Green',
        busUtilizationScore: 56.5,
      ),
      BusModel(
        busId: 'PVT-203',
        operatorType: 'PRIVATE',
        routeNumber: 'R3',
        capacity: 40,
        passengerCount: 16,
        occupancyPercentage: 40.0,
        seatAvailability: 24,
        latitude: 8.5620,
        longitude: 76.9720,
        etaMinutes: 4,
        crowdLevel: 'Green',
        busUtilizationScore: 47.0,
      ),
      BusModel(
        busId: 'KSRTC-104',
        operatorType: 'KSRTC',
        routeNumber: 'R3',
        capacity: 50,
        passengerCount: 46,
        occupancyPercentage: 92.0,
        seatAvailability: 4,
        latitude: 8.5600,
        longitude: 76.9700,
        etaMinutes: 10,
        crowdLevel: 'Red',
        busUtilizationScore: 100.0,
      ),
    ];
  }
}
