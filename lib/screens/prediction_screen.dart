// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../api/api_service.dart';
import '../theme/app_theme.dart';

class PredictionScreen extends StatefulWidget {
  final String vehicleId;
  final Map<String, dynamic> sensorData;

  const PredictionScreen({
    super.key,
    required this.vehicleId,
    required this.sensorData,
  });

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _isLoadingKm = false;
  Map<String, dynamic>? _predictionResult;
  Map<String, dynamic>? _kilometerPrediction;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getPrediction();
    _getRemainingKilometers();
  }

  Future<void> _getRemainingKilometers() async {
    setState(() => _isLoadingKm = true);

    try {
      final result = await _apiService.predictEngineKilometers(
        widget.vehicleId,
      );
      if (!mounted) return;

      setState(() {
        _kilometerPrediction = result;
        _isLoadingKm = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _kilometerPrediction = null;
        _isLoadingKm = false;
      });
    }
  }

  Future<void> _getPrediction() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _apiService.getPrediction(
        vehicleId: widget.vehicleId,
        sensorData: widget.sensorData,
      );

      if (!mounted) return;

      setState(() {
        _predictionResult = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _shareResults() async {
    if (_predictionResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No prediction results to share'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final prediction = _predictionResult!['prediction'] ?? {};
    final status = _predictionResult!['status'] as String? ?? 'U';
    final score = (_predictionResult!['score'] as num?)?.toDouble() ?? 0.0;

    final engineCondition =
        prediction['engine_condition'] == 1 ? 'Good' : 'Needs Service';
    final statusText = status == 'F' ? 'Failure' : 'Good';

    final shareText = '''
🚗 Vehicle Analysis Report

Vehicle ID: ${widget.vehicleId}
Engine Status: $engineCondition
Overall Status: $statusText
Confidence: ${(score * 100).toStringAsFixed(1)}%

Sensor Readings:
• Engine RPM: ${widget.sensorData['engine_rpm']}
• Lub Oil Pressure: ${widget.sensorData['lub_oil_pressure']} kPa
• Fuel Pressure: ${widget.sensorData['fuel_pressure']} kPa
• Coolant Pressure: ${widget.sensorData['coolant_pressure']} kPa
• Lub Oil Temperature: ${widget.sensorData['lub_oil_temp']} °C
• Coolant Temperature: ${widget.sensorData['coolant_temp']} °C

Analysis Time: ${DateTime.now().toLocal().toString()}
''';

    try {
      await Share.share(
        shareText,
        subject: 'Vehicle Analysis Report - ${widget.vehicleId}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing results: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Widget _buildHealthMetricsCard() {
    if (_isLoadingKm) {
      return Container(
        padding: AppTheme.paddingAll,
        decoration: AppTheme.cardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 48,
              width: 48,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text('Analyzing Vehicle Health', style: AppTheme.titleStyle),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Please wait while we calculate remaining kilometers...',
              style: AppTheme.subtitleStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_kilometerPrediction == null) {
      return Container(
        padding: AppTheme.paddingAll,
        decoration: AppTheme.cardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.errorColor,
              size: 48,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text('Health Analysis Error', style: AppTheme.titleStyle),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Unable to calculate remaining kilometers.',
              style: AppTheme.subtitleStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingM),
            ElevatedButton(
              onPressed: _getRemainingKilometers,
              style: AppTheme.primaryButtonStyle,
              child: const Text('RETRY'),
            ),
          ],
        ),
      );
    }

    final healthMetrics = _kilometerPrediction!['health_metrics'];
    final recommendations =
        _kilometerPrediction!['maintenance_recommendations'];
    final performance = _kilometerPrediction!['performance_analysis'];

    final remainingKm = healthMetrics['remaining_kilometers'] as int;
    final maintenanceDueKm =
        healthMetrics['estimated_maintenance_due_km'] as int;
    final healthScore = healthMetrics['overall_score'] as double;
    final riskLevel = recommendations['risk_level'] as String;

    // Determine status based on health score
    String displayStatus;
    Color statusColor;
    IconData statusIcon;

    if (healthScore >= 0.85) {
      displayStatus = 'Excellent';
      statusColor = AppTheme.successColor;
      statusIcon = Icons.verified;
    } else if (healthScore >= 0.70) {
      displayStatus = 'Good';
      statusColor = const Color(0xFF4CAF50);
      statusIcon = Icons.check_circle;
    } else if (healthScore >= 0.50) {
      displayStatus = 'Fair';
      statusColor = const Color.fromARGB(255, 205, 235, 9);
      statusIcon = Icons.anchor;
    } else if (healthScore >= 0.30) {
      displayStatus = 'Poor';
      statusColor = Colors.deepOrange;
      statusIcon = Icons.error;
    } else {
      displayStatus = 'Critical';
      statusColor = AppTheme.warningColor;
      statusIcon = Icons.dangerous;
    }

    return Container(
      padding: AppTheme.paddingAll,
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor, size: 32),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Engine Health',
                      style: AppTheme.labelStyle.copyWith(
                        color: AppTheme.textColorSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayStatus,
                      style: AppTheme.titleStyle.copyWith(
                        color: statusColor,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Health Score',
                      style: AppTheme.labelStyle.copyWith(
                        color: AppTheme.textColorSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(healthScore * 100).toStringAsFixed(1)}%',
                      style: AppTheme.valueStyle.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Remaining Kilometers Indicator
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Remaining Distance',
                    style: AppTheme.titleStyle.copyWith(fontSize: 16),
                  ),
                  Text(
                    '$remainingKm km',
                    style: AppTheme.valueStyle.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingS),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: maintenanceDueKm / remainingKm,
                  backgroundColor: AppTheme.cardColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    maintenanceDueKm < 1000
                        ? AppTheme.warningColor
                        : AppTheme.successColor,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'Next maintenance in $maintenanceDueKm km',
                style: AppTheme.subtitleStyle.copyWith(
                  color: AppTheme.textColorSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Performance Metrics
          Text(
            'Performance Metrics',
            style: AppTheme.titleStyle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardColor, width: 1),
            ),
            child: Column(
              children: [
                _buildMetricRow(
                  'Efficiency',
                  '${(performance['efficiency_score'] * 100).toStringAsFixed(0)}%',
                  Icons.speed,
                ),
                const SizedBox(height: AppTheme.spacingM),
                _buildMetricRow(
                  'Risk Level',
                  riskLevel,
                  Icons.warning,
                  valueColor:
                      riskLevel == 'Low'
                          ? AppTheme.successColor
                          : riskLevel == 'Medium'
                          ? Colors.orange
                          : AppTheme.warningColor,
                ),
                const SizedBox(height: AppTheme.spacingM),
                _buildMetricRow(
                  'Thermal Balance',
                  performance['thermal_balance'],
                  Icons.thermostat,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
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
                value,
                style: AppTheme.bodyStyle.copyWith(
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionCard() {
    if (_error != null) {
      return Container(
        padding: AppTheme.paddingAll,
        decoration: AppTheme.cardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.errorColor,
              size: 48,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text('Error', style: AppTheme.titleStyle),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              _error!,
              style: AppTheme.subtitleStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingM),
            ElevatedButton(
              onPressed: _getPrediction,
              style: AppTheme.primaryButtonStyle,
              child: const Text('RETRY'),
            ),
          ],
        ),
      );
    }

    if (_predictionResult == null || _isLoading) {
      return Container(
        padding: AppTheme.paddingAll,
        decoration: AppTheme.cardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 48,
              width: 48,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text('Analyzing Data', style: AppTheme.titleStyle),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Please wait while we process the sensor data...',
              style: AppTheme.subtitleStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Safely extract and convert prediction data
    final predictionData = _predictionResult!;
    final prediction = predictionData['prediction'] ?? {};
    final status = predictionData['status'] as String? ?? 'U';
    final score = (predictionData['score'] as num?)?.toDouble() ?? 0.0;

    // Determine engine condition based on prediction
    final engineCondition =
        prediction['engine_condition'] == 1 ? 'Good' : 'Needs Service';
    final isEngineGood = prediction['engine_condition'] == 1;

    // Determine overall status
    final isStatusGood = status != 'F';
    final statusText = status == 'F' ? 'Failure' : 'Good';

    return Container(
      padding: AppTheme.paddingAll,
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      isStatusGood
                          ? AppTheme.successColor.withOpacity(0.1)
                          : AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isStatusGood ? Icons.check_circle : Icons.warning,
                  color:
                      isStatusGood
                          ? AppTheme.successColor
                          : AppTheme.warningColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Engine Status',
                      style: AppTheme.labelStyle.copyWith(
                        color: AppTheme.textColorSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      engineCondition,
                      style: AppTheme.titleStyle.copyWith(
                        color:
                            isEngineGood
                                ? AppTheme.successColor
                                : AppTheme.warningColor,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Confidence',
                      style: AppTheme.labelStyle.copyWith(
                        color: AppTheme.textColorSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(score * 100).toStringAsFixed(1)}%',
                      style: AppTheme.valueStyle.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Analysis Details
          Text(
            'Analysis Details',
            style: AppTheme.titleStyle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  'Overall Status',
                  statusText,
                  isStatusGood ? Icons.verified : Icons.error_outline,
                  valueColor:
                      isStatusGood
                          ? AppTheme.successColor
                          : AppTheme.warningColor,
                ),
                const SizedBox(height: AppTheme.spacingM),
                _buildDetailRow(
                  'Model Used',
                  'LSTM Neural Network',
                  Icons.memory,
                ),
                const SizedBox(height: AppTheme.spacingM),
                _buildDetailRow(
                  'Parameters',
                  '6 Sensor Readings',
                  Icons.sensors,
                ),
                const SizedBox(height: AppTheme.spacingM),
                _buildDetailRow('Last Updated', 'Just now', Icons.update),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _getPrediction,
                  style: AppTheme.primaryButtonStyle,
                  icon: const Icon(Icons.refresh),
                  label: const Text('REFRESH ANALYSIS'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              IconButton(
                onPressed: _shareResults,
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(12),
                  backgroundColor: AppTheme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                ),
                icon: const Icon(Icons.share, color: AppTheme.primaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
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
                value,
                style: AppTheme.bodyStyle.copyWith(
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Vehicle Analysis', style: AppTheme.titleStyle),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppTheme.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: AppTheme.paddingAll,
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vehicle Information', style: AppTheme.titleStyle),
                  const SizedBox(height: AppTheme.spacingM),
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_car,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vehicle ID', style: AppTheme.labelStyle),
                          Text(
                            widget.vehicleId,
                            style: AppTheme.bodyStyle.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildHealthMetricsCard(),
            const SizedBox(height: AppTheme.spacingM),
            _buildPredictionCard(),
          ],
        ),
      ),
    );
  }
}
