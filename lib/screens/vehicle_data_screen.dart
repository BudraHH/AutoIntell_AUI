import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../models/historical_record.dart';

class VehicleDataScreen extends StatefulWidget {
  final String vehicleId;

  const VehicleDataScreen({super.key, required this.vehicleId});

  @override
  State<VehicleDataScreen> createState() => _VehicleDataScreenState();
}

class _VehicleDataScreenState extends State<VehicleDataScreen> {
  final _scrollController = ScrollController();
  final _apiService = ApiService();

  bool _isLoadingInitially = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  List<HistoricalRecord> _historyRecords = [];
  int _currentPage = 1;
  bool _hasMorePages = true;

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
    _fetchHistory();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreHistory();
      }
    });
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoadingInitially = true;
      _errorMessage = null;
      _historyRecords = [];
      _currentPage = 1;
      _hasMorePages = true;
    });

    try {
      final response = await _apiService.getPredictionHistory(
        widget.vehicleId,
        page: 1,
      );

      if (response != null) {
        setState(() {
          _historyRecords = response.results;
          _hasMorePages = response.hasNextPage;
          _currentPage = response.currentPage;
          _isLoadingInitially = false;
        });
      } else {
        throw Exception('Failed to fetch history');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading history: $e';
        _isLoadingInitially = false;
      });
    }
  }

  Future<void> _loadMoreHistory() async {
    if (_isLoadingMore || !_hasMorePages) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await _apiService.getPredictionHistory(
        widget.vehicleId,
        page: _currentPage + 1,
      );

      if (response != null) {
        setState(() {
          _historyRecords.addAll(response.results);
          _hasMorePages = response.hasNextPage;
          _currentPage = response.currentPage;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _hasMorePages = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasMorePages = false;
        _isLoadingMore = false;
        // Optionally show a snackbar for load more error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading more records: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      });
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    return DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toLocal());
  }

  Widget _buildSensorRow(String label, double value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(HistoricalRecord record) {
    final isHealthy = record.predictionResult.toLowerCase() == 'healthy';
    final statusColor = isHealthy ? Colors.green.shade700 : Colors.red.shade700;
    final statusIcon =
        isHealthy ? Icons.check_circle : Icons.warning_amber_rounded;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ExpansionTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(
          _formatTimestamp(record.timestamp),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          record.predictionResult,
          style: TextStyle(color: statusColor),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildSensorRow('Engine RPM', record.engineRpm, 'RPM'),
                _buildSensorRow(
                  'Lub Oil Pressure',
                  record.lubOilPressure,
                  'kPa',
                ),
                _buildSensorRow('Fuel Pressure', record.fuelPressure, 'kPa'),
                _buildSensorRow(
                  'Coolant Pressure',
                  record.coolantPressure,
                  'kPa',
                ),
                _buildSensorRow('Lub Oil Temperature', record.lubOilTemp, '°C'),
                _buildSensorRow(
                  'Coolant Temperature',
                  record.coolantTemp,
                  '°C',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingInitially) {
      return Scaffold(
        appBar: AppBar(title: Text('History for Vehicle ${widget.vehicleId}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text('History for Vehicle ${widget.vehicleId}')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchHistory,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('History for Vehicle ${widget.vehicleId}'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchHistory),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body:
          _historyRecords.isEmpty
              ? const Center(child: Text('No history found for this vehicle.'))
              : RefreshIndicator(
                onRefresh: _fetchHistory,
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _historyRecords.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _historyRecords.length) {
                      return _buildLoadingIndicator();
                    }
                    return _buildHistoryItem(_historyRecords[index]);
                  },
                ),
              ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreHistory();
      }
    });
    _scrollController.dispose();
    super.dispose();
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
      await _apiService.logoutUser();
      if (!mounted) return;

      // Navigate to login screen and remove all previous routes
      await Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }
}
