import 'dart:math';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../screens/vehicle_data_screen.dart';
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
            title: const Text("Confirm Logout"),
            content: const Text("Are you sure you want to logout?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Logout"),
              ),
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
              initialSensorData: latestSensorDataMap,
            ),
      ),
    ).then((_) => _fetchLatestSensorData());
  }

  void _navigateToHistoryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleDataScreen(vehicleId: vehicleId),
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return "N/A";
    return DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toLocal());
  }

  Widget _buildSensorRow(String label, String key, String unit) {
    final value = _getNumericValue(key);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value != null ? "${value.toStringAsFixed(1)} $unit" : "N/A",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorDataCard() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null && isOnline) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            errorMessage!,
            style: TextStyle(color: Colors.red.shade700),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (latestSensorDataMap == null || lastDataTimestamp == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "No sensor data available yet. Refresh.",
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Data for Vehicle: $vehicleId",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              "Last Updated: ${_formatTimestamp(lastDataTimestamp)}",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _buildSensorRow("Engine RPM", "Engine rpm", "RPM"),
            _buildSensorRow("Lub Oil Pressure", "Lub oil pressure", "kPa"),
            _buildSensorRow("Fuel Pressure", "Fuel pressure", "kPa"),
            _buildSensorRow("Coolant Pressure", "Coolant pressure", "kPa"),
            _buildSensorRow("Lub Oil Temperature", "Lub oil temp", "°C"),
            _buildSensorRow("Coolant Temperature", "Coolant temp", "°C"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AutoIntell Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: (!isLoading && isOnline) ? _fetchLatestSensorData : null,
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                isOnline ? "Connected ✅" : "Offline Mode ⚠️",
                style: TextStyle(
                  color: isOnline ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSensorDataCard(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed:
                  (!isLoading && isOnline) ? _navigateToPredictionScreen : null,
              icon: const Icon(Icons.analytics_outlined),
              label: const Text(
                "Run New Prediction",
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("View Prediction History"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _navigateToHistoryScreen,
            ),
          ],
        ),
      ),
    );
  }
}
