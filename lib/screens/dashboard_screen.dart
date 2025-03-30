// ignore_for_file: deprecated_member_use

import 'dart:math';

import 'package:autointell_aui/screens/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../screens/prediction_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isOnline = true;
  bool isLoading = true;
  String? errorMessage;
  DateTime? lastDataTimestamp;
  final String vehicleId = '${Random().nextInt(1000)}';
  final ApiService apiService = ApiService();

  // Store the raw map for passing to prediction screen
  Map<String, dynamic>? latestSensorDataMap;

  // Helper method to safely get numeric values from the map
  double? _getNumericValue(String key) {
    final value =
        latestSensorDataMap?[key] ??
        latestSensorDataMap?[key.toLowerCase().replaceAll(' ', '_')];
    return (value as num?)?.toDouble();
  }

  @override
  void initState() {
    super.initState();
    _setupConnectivityListener();
    _checkInitialConnectivityAndLoadData();
  }

  Future<void> _setupConnectivityListener() async {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        isOnline = result != ConnectivityResult.none;
      });
      if (isOnline && latestSensorDataMap == null) {
        _fetchLatestSensorData();
      }
    });
  }

  Future<void> _checkInitialConnectivityAndLoadData() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      isOnline = connectivityResult != ConnectivityResult.none;
    });
    if (isOnline) {
      _fetchLatestSensorData();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchLatestSensorData() async {
    if (!isOnline) {
      setState(() {
        errorMessage = "Cannot fetch data while offline";
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final sensorData = await apiService.getSensorData(vehicleId);

      if (sensorData != null) {
        setState(() {
          latestSensorDataMap = sensorData;

          // Parse timestamp safely
          try {
            lastDataTimestamp = DateTime.tryParse(
              sensorData['timestamp'] ?? '',
            );
          } catch (_) {
            lastDataTimestamp = DateTime.now();
          }

          isLoading = false;
          errorMessage = null;
        });
      } else {
        throw Exception("Failed to fetch sensor data");
      }
    } catch (e) {
      setState(() {
        errorMessage = "Failed to fetch sensor data: $e";
        isLoading = false;
        latestSensorDataMap = null;
        lastDataTimestamp = null;
      });
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2D36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "Confirm Logout",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              "Are you sure you want to logout?",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
                child: const Text("Cancel", style: TextStyle(fontSize: 16)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  "Logout",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
    );

    if (shouldLogout == true) {
      await apiService.logoutUser();
      if (!mounted) return;

      // Navigate to login screen and remove all previous routes
      await Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }

  void _navigateToPredictionScreen() {
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot run prediction while offline")),
      );
      return;
    }

    if (latestSensorDataMap == null || latestSensorDataMap!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sensor data not available. Refresh dashboard first."),
        ),
      );
      return;
    }

    // Verify that all required sensor values are present
    final requiredKeys = [
      'Engine rpm',
      'Lub oil pressure',
      'Fuel pressure',
      'Coolant pressure',
      'Lub oil temp',
      'Coolant temp',
    ];

    final missingKeys = requiredKeys.where(
      (key) =>
          !latestSensorDataMap!.containsKey(key) &&
          !latestSensorDataMap!.containsKey(
            key.toLowerCase().replaceAll(' ', '_'),
          ),
    );

    if (missingKeys.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Incomplete sensor data. Missing: ${missingKeys.join(', ')}",
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PredictionScreen(
              vehicleId: vehicleId,
              sensorData: latestSensorDataMap!,
            ),
      ),
    ).then((_) => _fetchLatestSensorData());
  }

  void _navigateToHistoryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => HistoryScreen(
              vehicleId: vehicleId,
              sensorData: latestSensorDataMap!,
            ),
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return "N/A";
    return DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toLocal());
  }

  Widget _buildSensorCard(
    String label,
    String key,
    String unit,
    IconData icon,
    Color iconColor,
  ) {
    final value = _getNumericValue(key);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2D36),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value != null ? value.toStringAsFixed(1) : 'N/A',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2128),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2128),
        elevation: 0,
        title: const Text(
          "AutoIntell Dashboard",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: (!isLoading && isOnline) ? _fetchLatestSensorData : null,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vehicle Info Card
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2D36),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vehicle ID',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          vehicleId,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Last Update',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(lastDataTimestamp),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Online Status
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      isOnline
                          ? Colors.green.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOnline ? Icons.wifi : Icons.wifi_off,
                      size: 16,
                      color: isOnline ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOnline ? "Connected" : "Offline Mode",
                      style: TextStyle(
                        color: isOnline ? Colors.green : Colors.orange,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (isLoading) ...[
              const Center(child: CircularProgressIndicator()),
            ] else if (errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else if (latestSensorDataMap != null) ...[
              // Sensor Data Grid
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildSensorCard(
                    'Engine RPM',
                    'Engine rpm',
                    'RPM',
                    Icons.speed,
                    Colors.blue,
                  ),
                  _buildSensorCard(
                    'Lub Oil Pressure',
                    'Lub oil pressure',
                    'kPa',
                    Icons.opacity,
                    Colors.green,
                  ),
                  _buildSensorCard(
                    'Fuel Pressure',
                    'Fuel pressure',
                    'kPa',
                    Icons.local_gas_station,
                    Colors.orange,
                  ),
                  _buildSensorCard(
                    'Coolant Pressure',
                    'Coolant pressure',
                    'kPa',
                    Icons.waves,
                    Colors.cyan,
                  ),
                  _buildSensorCard(
                    'Lub Oil Temp',
                    'Lub oil temp',
                    '°C',
                    Icons.thermostat,
                    Colors.red,
                  ),
                  _buildSensorCard(
                    'Coolant Temp',
                    'Coolant temp',
                    '°C',
                    Icons.ac_unit,
                    Colors.lightBlue,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          (!isLoading && isOnline)
                              ? _navigateToPredictionScreen
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Run Diagnostics",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _navigateToHistoryScreen,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A2D36),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "View History",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
