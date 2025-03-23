import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

class ApiService {
  // if emulator is used
  final String baseUrl = "http://10.0.2.2:8000/api/";
  // If you’re using a physical device, replace it with your PC’s local network IP
  final storage = const FlutterSecureStorage();
  final _logger = Logger('ApiService');

  // LOGIN
  Future<String?> loginUser(String username, String password) async {
    try {
      final Map<String, String> requestBody = {
        "username": username,
        "password": password,
      };

      _logger.info(
        'Making login request with body: ${jsonEncode(requestBody)}',
      );

      final response = await http.post(
        Uri.parse("${baseUrl}auth/login/"),
        body: jsonEncode(requestBody),
        headers: {
          "Content-Type": "application/json",
          // "Accept": "application/json",
        },
      );

      _logger.info('Login response status: ${response.statusCode}');
      _logger.info('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storage.write(key: "access_token", value: data["access"]);
        await storage.write(key: "refresh_token", value: data["refresh"]);
        return data["access"];
      } else {
        _logger.warning(
          'Login failed with status: ${response.statusCode}, body: ${response.body}',
        );
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
      final token = await storage.read(key: "access_token");
      if (token == null) {
        _logger.warning('No access token found');
        return null;
      }

      final response = await http.get(
        Uri.parse("${baseUrl}sensor/latest/$vehicleId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        _logger.warning('Failed to fetch sensor data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.severe('Error fetching sensor data: $e');
      return null;
    }
  }

  // FETCH engine health prediction
  Future<Map<String, dynamic>?> getEnginePrediction({
    required double engineRpm,
    required double lubOilPressure,
    required double fuelPressure,
    required double coolantPressure,
    required double lubOilTemp,
    required double coolantTemp,
  }) async {
    try {
      final token = await storage.read(key: "access_token");
      if (token == null) {
        _logger.warning('No access token found');
        return null;
      }

      final response = await http.post(
        Uri.parse("${baseUrl}ml/predict/engine"),
        body: jsonEncode({
          "engine_rpm": engineRpm,
          "lub_oil_pressure": lubOilPressure,
          "fuel_pressure": fuelPressure,
          "coolant_pressure": coolantPressure,
          "lub_oil_temp": lubOilTemp,
          "coolant_temp": coolantTemp,
        }),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        _logger.warning('Failed to fetch prediction: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.severe('Error fetching prediction: $e');
      return null;
    }
  }
}
