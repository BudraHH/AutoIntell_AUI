// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../models/historical_record.dart';
import '../theme/app_theme.dart';
import 'visualization_screen.dart';

class HistoryScreen extends StatefulWidget {
  final String vehicleId;

  const HistoryScreen({
    super.key,
    required this.vehicleId,
    required Map<String, dynamic> sensorData,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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
    if (_isLoadingMore || !_hasMorePages) return;

    setState(() => _isLoadingMore = true);

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
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading more records: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    return DateFormat('MMM dd, yyyy HH:mm').format(timestamp.toLocal());
  }

  Widget _buildHistoryCard(HistoricalRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      decoration: AppTheme.cardDecoration,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  record.isHealthy
                      ? AppTheme.successColor.withOpacity(0.1)
                      : AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              record.isHealthy ? Icons.check_circle : Icons.warning,
              color:
                  record.isHealthy
                      ? AppTheme.successColor
                      : AppTheme.warningColor,
            ),
          ),
          title: Text(
            _formatTimestamp(record.timestamp),
            style: AppTheme.titleStyle.copyWith(fontSize: 16),
          ),
          subtitle: Text(
            record.predictionResult,
            style: AppTheme.subtitleStyle.copyWith(
              color:
                  record.isHealthy
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
                    'Engine RPM',
                    record.engineRpm,
                    'RPM',
                    Icons.speed,
                  ),
                  _buildSensorReadingRow(
                    'Lub Oil Pressure',
                    record.lubOilPressure,
                    'kPa',
                    Icons.oil_barrel,
                  ),
                  _buildSensorReadingRow(
                    'Fuel Pressure',
                    record.fuelPressure,
                    'kPa',
                    Icons.local_gas_station,
                  ),
                  _buildSensorReadingRow(
                    'Coolant Pressure',
                    record.coolantPressure,
                    'kPa',
                    Icons.water_drop,
                  ),
                  _buildSensorReadingRow(
                    'Lub Oil Temperature',
                    record.lubOilTemp,
                    '°C',
                    Icons.thermostat,
                  ),
                  _buildSensorReadingRow(
                    'Coolant Temperature',
                    record.coolantTemp,
                    '°C',
                    Icons.thermostat_auto,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorReadingRow(
    String label,
    double value,
    String unit,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.labelStyle.copyWith(
                    color: AppTheme.textColorSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${value.toStringAsFixed(2)} $unit',
                  style: AppTheme.valueStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Container(
        padding: AppTheme.paddingAll,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'Error Loading History',
              style: AppTheme.titleStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: AppTheme.subtitleStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingL),
            ElevatedButton.icon(
              onPressed: _fetchHistory,
              style: AppTheme.primaryButtonStyle,
              icon: const Icon(Icons.refresh),
              label: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Prediction History', style: AppTheme.titleStyle),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton:
          _historyRecords.length >= 3
              ? FloatingActionButton.extended(
                onPressed: () => _showVisualizationDialog(context),
                backgroundColor: AppTheme.primaryColor,
                icon: const Icon(Icons.analytics),
                label: const Text('VISUALIZE'),
              )
              : null,
      body:
          _isLoadingInitially
              ? _buildLoadingIndicator()
              : _errorMessage != null
              ? _buildErrorView()
              : _historyRecords.isEmpty
              ? Center(
                child: Text('No history found', style: AppTheme.titleStyle),
              )
              : RefreshIndicator(
                onRefresh: _fetchHistory,
                color: AppTheme.primaryColor,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: AppTheme.paddingAll,
                  itemCount: _historyRecords.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _historyRecords.length) {
                      return _buildLoadingIndicator();
                    }
                    return _buildHistoryCard(_historyRecords[index]);
                  },
                ),
              ),
    );
  }

  Future<void> _showVisualizationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: AppTheme.spacingM),
              Text('AI Analysis', style: AppTheme.titleStyle),
            ],
          ),
          content: Text(
            'The visualizations are generated using AI analysis of historical data. '
            'While they provide valuable insights, please note that the predictions '
            'and patterns shown may not be 100% accurate and should be used as '
            'supplementary information for decision-making.',
            style: AppTheme.bodyStyle,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCEL',
                style: TextStyle(color: AppTheme.textColorSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => VisualizationScreen(
                          records: _historyRecords,
                          vehicleId: widget.vehicleId,
                        ),
                  ),
                );
              },
              style: AppTheme.primaryButtonStyle,
              child: const Text('PROCEED'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
