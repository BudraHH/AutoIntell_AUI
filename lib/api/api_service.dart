import 'dart:convert';
import 'dart:ffi';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final String baseUrl = "http://127.0.0.1:8000/api/";
  final storage = FlutterSecureStorage();

  // LOGIN
  Future<String?> loginUser(String username, String password) async {
    final response = await http.post(
      Uri.parse(("${baseUrl}auth/login/")),
      body: jsonEncode({"username" : username, "password" : password}),
      headers: {
        "Content-type" : "application/json"
      },
    );

    if(response.statusCode == 200) {
      var data = jsonDecode(response.body);
      await storage.write(key: "access_token", value: data["access"]);
      await storage.write(key: "refresh_token", value: data["refresh"]);
      return data["access"];
    } else {
      return null;
    }
  }

//   LOGOUT
  Future<void> logoutUser() async{
    await storage.delete(key: "access_token");
    await storage.delete(key: "refresh_token");
    await storage.delete(key: "offline_mode");
  }

//   FETCH real-time data
Future<Map<String, dynamic>?> getSensorData(String vehicleId) async{
    String? token = await storage.read(key: "access_token");

    final response = await http.get(
      Uri.parse("${baseUrl}sensor/latest$vehicleId"),
      headers: {
        "Content-type" : "application/json",
        "Authorization" : "Bearer $token"
      },
    );

    if(response.statusCode == 200){
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

//   FETCH engine health prediction
  Future<Map<String, dynamic>?> getEnginePrediction({
  required double engineRpm,
  required double lubOilPressure,
  required double fuelPressure,
  required double coolantPressure,
  required double lubOilTemp,
  required double coolantTemp,
  }) async {
    String? token = await storage.read(key: "access_token");

    final response = await http.post(
      Uri.parse("${baseUrl}ml/predict/engine"),
      body: jsonEncode({"engine_rpm": engineRpm,
        "lub_oil_pressure": lubOilPressure,
        "fuel_pressure": fuelPressure,
        "coolant_pressure": coolantPressure,
        "lub_oil_temp": lubOilTemp,
        "coolant_temp": coolantTemp
      }),
      headers: {
        "Content-type" : "application/json",
        "Authorization" : "Bearer $token"
      },
    );

    if(response.statusCode == 200){
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }
}