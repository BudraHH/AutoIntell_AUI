// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/historical_record.dart';
import '../services/local_storage_service.dart';
import '../theme/app_theme.dart';
import 'visualization_screen.dart';

class HistoryScreen extends StatefulWidget {
  final String vehicleId;

  const HistoryScreen({
    super.key,
    required this.vehicleId,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _scrollController = ScrollController();
  late LocalStorageService _storageService;
  bool _isLoading = true;
  List<HistoricalRecord> _historyRecords = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeStorage();
  }

  Future<void> _initializeStorage() async {
    try {
      _storageService = await LocalStorageService.getInstance();
      await _loadHistory();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing storage: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      final records = await _storageService.getHistory();
      setState(() {
        _historyRecords = records
            .where((record) => record.vehicleId == widget.vehicleId)
            .toList();
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading history: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    try {
      await _storageService.clearHistory();
      await _loadHistory();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('History cleared successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing history: $e')),
      );
    }
  }

  void _showVisualizationDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisualizationScreen(
          records: _historyRecords,
          vehicleId: widget.vehicleId,
        ),
      ),
    );
  }

  Widget _buildHistoryCard(HistoricalRecord record) {
    final formattedDate =
        DateFormat('MMM dd, yyyy HH:mm').format(record.timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: ExpansionTile(
        title: Text(formattedDate, style: AppTheme.titleStyle),
        subtitle: Text(
          record.isHealthy ? 'Healthy' : 'Faulty',
          style: AppTheme.subtitleStyle.copyWith(
            color: record.isHealthy
                ? AppTheme.successColor
                : AppTheme.warningColor,
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              children: [
                _buildSensorReadingRow(
                    'Engine RPM', record.engineRpm, 'RPM', Icons.speed),
                _buildSensorReadingRow('Lub Oil Pressure',
                    record.lubOilPressure, 'kPa', Icons.oil_barrel),
                _buildSensorReadingRow('Fuel Pressure', record.fuelPressure,
                    'kPa', Icons.local_gas_station),
                _buildSensorReadingRow('Coolant Pressure',
                    record.coolantPressure, 'kPa', Icons.water_drop),
                _buildSensorReadingRow('Lub Oil Temperature', record.lubOilTemp,
                    '°C', Icons.thermostat),
                _buildSensorReadingRow('Coolant Temperature',
                    record.coolantTemp, '°C', Icons.thermostat_auto),
                const Divider(),
                _buildSensorReadingRow('Health Score', record.healthScore * 100,
                    '%', Icons.health_and_safety),
                _buildSensorReadingRow('LSTM Confidence',
                    record.lstmPrediction * 100, '%', Icons.analytics),
                _buildSensorReadingRow('Coolant Change',
                    record.kmForCoolantChange, 'km', Icons.water_drop),
                _buildSensorReadingRow('Oil Change', record.kmForOilChange,
                    'km', Icons.oil_barrel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorReadingRow(
      String label, double value, String unit, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: AppTheme.labelStyle),
          ),
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: AppTheme.valueStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
          const SizedBox(height: AppTheme.spacingM),
          Text(_errorMessage ?? 'An error occurred',
              style: AppTheme.titleStyle),
          const SizedBox(height: AppTheme.spacingM),
          ElevatedButton(
            onPressed: _loadHistory,
            style: AppTheme.primaryButtonStyle,
            child: const Text('RETRY'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppTheme.textColorSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: AppTheme.spacingM),
          const Text('No History Available', style: AppTheme.titleStyle),
          const SizedBox(height: AppTheme.spacingS),
          const Text(
            'Make predictions to see them here',
            style: AppTheme.subtitleStyle,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Prediction History', style: AppTheme.titleStyle),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_historyRecords.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.textColor),
              onPressed: () => _showClearHistoryDialog(context),
            ),
        ],
      ),
      floatingActionButton: _historyRecords.length >= 3
          ? FloatingActionButton.extended(
              onPressed: () => _showVisualizationDialog(context),
              backgroundColor: AppTheme.primaryColor,
              icon: const Icon(Icons.analytics),
              label: const Text('VISUALIZE'),
            )
          : null,
      body: _isLoading
          ? _buildLoadingIndicator()
          : _errorMessage != null
              ? _buildErrorView()
              : _historyRecords.isEmpty
                  ? _buildEmptyView()
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      color: AppTheme.primaryColor,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: AppTheme.paddingAll,
                        itemCount: _historyRecords.length,
                        itemBuilder: (context, index) =>
                            _buildHistoryCard(_historyRecords[index]),
                      ),
                    ),
    );
  }

  Future<void> _showClearHistoryDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: const Text('Clear History?'),
          content: const Text(
            'This will permanently delete all prediction history. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: AppTheme.textColorSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _clearHistory();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningColor,
              ),
              child: const Text('CLEAR'),
            ),
          ],
        );
      },
    );
  }
}
