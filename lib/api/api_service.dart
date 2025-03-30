import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import '../models/prediction_result.dart';
import '../models/paginated_history_response.dart';

class ApiService {
  // if emulator is used
  final String baseUrl = "http://10.0.2.2:8000/api/";
  // if physical device is used
  // final String baseUrl = "http://192.168.111.250:8000/api/";
  final storage = const FlutterSecureStorage();
  final _logger = Logger('ApiService');

  // LOGIN
  Future<String?> loginUser(String username, String password) async {
    try {
      _logger.info('Attempting login with username: $username');

      final Map<String, String> requestBody = {
        "username": username,
        "password": password,
      };

      final response = await http.post(
        Uri.parse("${baseUrl}auth/login/"),
        body: jsonEncode(requestBody),
        headers: {
          "Content-Type": "application/json",
          // "Accept": "application/json",
        },
      );

      _logger.info('Login response status: ${response.statusCode}');
      _logger.info('Request body sent: ${jsonEncode(requestBody)}');
      _logger.info('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storage.write(key: "access_token", value: data["access"]);
        await storage.write(key: "refresh_token", value: data["refresh"]);
        return data["access"];
      } else {
        _logger.warning('Login failed with status: ${response.statusCode}');
        _logger.warning('Error response: ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.severe('Login error: $e');
      return null;
    }
  }

  // LOGOUT
  Future<void> logoutUser() async {
    try {
      await storage.delete(key: "access_token");
      await storage.delete(key: "refresh_token");
      await storage.delete(key: "offline_mode");
      _logger.info('User logged out successfully');
    } catch (e) {
      _logger.severe('Logout error: $e');
    }
  }

  // FETCH real-time data
  Future<Map<String, dynamic>?> getSensorData(String vehicleId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}sensor/latest/$vehicleId/'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Verify the response has the expected structure
        if (data.containsKey('Engine rpm') || data.containsKey('engine_rpm')) {
          // Handle both key formats
          return data;
        }

        throw Exception('Invalid response format from sensor API');
      }

      throw Exception(
        'Failed to fetch sensor data: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      _logger.severe('Error fetching sensor data: $e');
      return null;
    }
  }

  // FETCH engine health prediction
  Future<PredictionResult> getEnginePrediction({
    required String vehicleId,
    required double engineRpm,
    required double lubOilPressure,
    required double fuelPressure,
    required double coolantPressure,
    required double lubOilTemp,
    required double coolantTemp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}ml/predict/engine/'),
        headers: await _getAuthHeaders(),
        body: json.encode({
          "vehicle_id": vehicleId,
          "Engine rpm": engineRpm,
          "Lub oil pressure": lubOilPressure,
          "Fuel pressure": fuelPressure,
          "Coolant pressure": coolantPressure,
          "Lub oil temp": lubOilTemp,
          "Coolant temp": coolantTemp,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return PredictionResult.fromJson(data);
      }

      throw Exception(
        'Failed to get prediction: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      throw Exception('Error getting prediction: $e');
    }
  }

  Future<PaginatedHistoryResponse?> getPredictionHistory(
    String vehicleId, {
    int page = 1,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}sensor/history/$vehicleId/?page=$page'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return PaginatedHistoryResponse.fromJson(data);
      }

      if (response.statusCode == 404) {
        // Handle case where page doesn't exist (end of pagination)
        return PaginatedHistoryResponse(
          results: [],
          nextPageUrl: null,
          totalCount: 0,
          currentPage: page,
        );
      }

      throw Exception(
        'Failed to fetch history: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching prediction history: $e');
      }
      return null;
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await storage.read(key: "access_token");
    if (token == null) {
      throw Exception("No access token found");
    }
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }
}
