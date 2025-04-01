import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import '../models/prediction_result.dart';
import '../models/paginated_history_response.dart';
import 'package:dio/dio.dart';
import 'dart:math';
import 'dart:async';

class ApiService {
  static const String baseUrl = 'http://192.168.75.250:8000/api/';
  // static const String baseUrl = 'http://10.0.2.2:8000/api/';

  final storage = const FlutterSecureStorage();
  final _logger = Logger('ApiService');
  late Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        contentType: 'application/json',
        validateStatus: (status) => status! < 500,
      ),
    );

    // Add interceptor to handle authentication
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          _logger.severe('API Error: ${error.message}');
          return handler.next(error);
        },
      ),
    );

    // Start the timer to send dummy engine prediction every minute
    _startDummyPredictionTimer();
  }

  // This method will run every minute
  void _startDummyPredictionTimer() {
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      try {
        _logger.info('Sending dummy engine prediction...');
        // Example vehicleId, replace with actual vehicle ID
        const vehicleId = 'vehicle123';
        final result = await sendDummyEnginePrediction(vehicleId: vehicleId);
        _logger.info('Dummy engine prediction sent: $result');
      } catch (e) {
        _logger.severe('Error sending dummy engine prediction: $e');
      }
    });
  }

  // Send dummy engine prediction method
  Future<Map<String, dynamic>> sendDummyEnginePrediction({
    required String vehicleId,
  }) async {
    try {
      // Create a random number generator
      final random = Random();

      // Prepare the dummy data with random values
      final dummyData = {
        "Engine rpm":
            1000 + random.nextInt(4000), // Random value between 1000 and 5000
        "Lub oil pressure":
            1.0 + random.nextDouble() * 3.0, // Random value between 1.0 and 4.0
        "Fuel pressure":
            2.0 + random.nextDouble() * 3.0, // Random value between 2.0 and 5.0
        "Coolant pressure":
            2.0 + random.nextDouble() * 3.0, // Random value between 2.0 and 5.0
        "Lub oil temp":
            30 + random.nextInt(50), // Random value between 30 and 80
        "Coolant temp":
            30 + random.nextInt(50), // Random value between 30 and 80
      };

      // Send the data using the API
      final headers = await _getAuthHeaders();
      final response = await _dio.post(
        'ml/predict/engine/',
        data: dummyData,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to send dummy engine prediction: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.severe('Error sending dummy engine prediction: $e');
      throw Exception('Error sending dummy engine prediction: $e');
    }
  }

  // LOGIN
  Future<String?> loginUser(String email, String password) async {
    try {
      _logger.info('Attempting login with email: $email');

      final Map<String, String> requestBody = {
        "email": email,
        "password": password,
      };

      final response = await http.post(
        Uri.parse("${baseUrl}auth/sign-in/"),
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
      _logger.info('Fetching history for vehicle: $vehicleId, page: $page');

      final response = await _dio.get(
        '${baseUrl}history/$vehicleId/', // Updated endpoint
        queryParameters: {'page': page},
        options: Options(headers: await _getAuthHeaders()),
      );

      if (response.statusCode == 200) {
        _logger.info('History fetched successfully');
        final Map<String, dynamic> data = response.data;
        return PaginatedHistoryResponse.fromJson(data);
      }

      if (response.statusCode == 404) {
        _logger.info('No more history pages available');
        return PaginatedHistoryResponse(
          results: [],
          nextPageUrl: null,
          totalCount: 0,
          currentPage: page,
        );
      }

      throw Exception('Failed to fetch history: ${response.statusCode}');
    } catch (e) {
      _logger.severe('Error fetching prediction history: $e');
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

  // REGISTER
  Future<Map<String, dynamic>?> registerUser(
    String username,
    String email,
    String password,
  ) async {
    try {
      _logger.info('Attempting registration for username: $username');

      final response = await http.post(
        Uri.parse('${baseUrl}auth/sign-up/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "email": email,
          "password": password,
        }),
      );

      _logger.info('Registration response status: ${response.statusCode}');

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _logger.info('Registration successful');
        return {
          'success': true,
          'message': 'Registration successful! Please log in.',
        };
      } else {
        _logger.warning('Registration failed: ${response.body}');
        return responseBody; // Contains {'error': '...'}
      }
    } catch (e) {
      _logger.severe('Registration error: $e');
      return {'error': 'An unexpected error occurred. Please try again.'};
    }
  }

  // PASSWORD RESET REQUEST
  Future<Map<String, dynamic>?> requestPasswordReset(String email) async {
    try {
      _logger.info('Requesting password reset for email: $email');

      final response = await http.post(
        Uri.parse('${baseUrl}auth/password-reset/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      final responseBody = jsonDecode(response.body);
      _logger.info(
        'Password Reset Request Status: ${response.statusCode}, Body: $responseBody',
      );

      return {...responseBody, 'statusCode': response.statusCode};
    } catch (e) {
      _logger.severe('Password Reset Request Error: $e');
      return {'error': 'An unexpected error occurred. Please try again.'};
    }
  }

  // PASSWORD RESET CONFIRMATION
  Future<Map<String, dynamic>?> confirmPasswordReset({
    required String uidb64,
    required String token,
    required String newPassword1,
    required String newPassword2,
  }) async {
    try {
      _logger.info('Confirming password reset for token: $token');

      final response = await http.post(
        Uri.parse('${baseUrl}auth/password-reset/confirm/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "uidb64": uidb64,
          "token": token,
          "new_password1": newPassword1,
          "new_password2": newPassword2,
        }),
      );

      final responseBody = jsonDecode(response.body);
      _logger.info(
        'Password Reset Confirm Status: ${response.statusCode}, Body: $responseBody',
      );

      return {...responseBody, 'statusCode': response.statusCode};
    } catch (e) {
      _logger.severe('Password Reset Confirm Error: $e');
      return {'error': 'An unexpected error occurred. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> getPrediction({
    required String vehicleId,
    required Map<String, dynamic> sensorData,
  }) async {
    try {
      _logger.info('Getting prediction for vehicle: $vehicleId');
      _logger.info('Sensor data: $sensorData');

      final response = await _dio.post(
        'ml/predict/engine/',
        data: sensorData,
        options: Options(headers: await _getAuthHeaders()),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        _logger.info('Prediction response: $data');
        return {
          'prediction': data['prediction'],
          'health_score': data['health_score'],
          'risk_level': data['risk_level'],
          'km_for_coolant_change': data['km_for_coolant_change'],
          'km_for_oil_change': data['km_for_oil_change'],
        };
      }

      throw Exception('Failed to get prediction: ${response.statusCode}');
    } catch (e) {
      _logger.severe('Error getting prediction: $e');
      throw Exception('Error getting prediction: $e');
    }
  }

  Future<Map<String, dynamic>> predictEngineKilometers(String vehicleId) async {
    try {
      final response = await _dio.get('sensor/remaining-km/$vehicleId/');

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return response.data;
        }
        throw Exception('Invalid response format');
      }

      throw Exception('Failed to get prediction: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error getting prediction: $e');
    }
  }

  Map<String, dynamic> _generateRandomEngineData() {
    final random = Random();
    return {
      "Engine rpm": 1000 + random.nextInt(4000),
      "Lub oil pressure": (1.0 + random.nextDouble() * 3.0).roundToDouble(),
      "Fuel pressure": (2.0 + random.nextDouble() * 3.0).roundToDouble(),
      "Coolant pressure": (2.0 + random.nextDouble() * 3.0).roundToDouble(),
      "Lub oil temp": 30.0 + random.nextInt(50),
      "Coolant temp": 30.0 + random.nextInt(50),
    };
  }

  Future<Map<String, dynamic>> getDisplayableDummyEngineData({
    required String vehicleId,
    bool sendToApi = true,
  }) async {
    _logger.info('Generating displayable dummy data for vehicle: $vehicleId');
    final Map<String, dynamic> generatedData = _generateRandomEngineData();
    generatedData['timestamp'] = DateTime.now().toIso8601String();

    if (sendToApi) {
      try {
        final headers = await _getAuthHeaders();
        await _dio.post(
          'ml/predict/engine/',
          data: generatedData,
          options: Options(headers: headers),
        );
        _logger.info('Generated data sent to API successfully.');
      } catch (e) {
        _logger.warning('Failed to send displayable dummy data to API: $e');
      }
    }

    return generatedData;
  }

  Future<void> saveHistoricalRecord(Map<String, dynamic> record) async {
    try {
      _logger.info('Saving historical record: $record');

      final response = await _dio.post(
        'sensor/history/', // Updated endpoint
        data: record,
        options: Options(headers: await _getAuthHeaders()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        _logger.warning('Failed to save history: ${response.statusCode}');
        throw Exception(
          'Failed to save historical record: ${response.statusCode}',
        );
      }

      _logger.info('Historical record saved successfully');
    } catch (e) {
      _logger.severe('Error saving historical record: $e');
      throw Exception('Error saving historical record: $e');
    }
  }
}
