// ignore_for_file: deprecated_member_use, unused_field

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../api/api_service.dart';
import '../theme/app_theme.dart';
import '../services/local_storage_service.dart';

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

      // Save to history
      await _saveToHistory(result);

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

  Future<void> _saveToHistory(Map<String, dynamic> predictionResult) async {
    try {
      final prediction = predictionResult['prediction'] as Map<String, dynamic>;
      final timestamp = DateTime.now().toIso8601String();

      final historicalRecord = {
        'vehicle_id': widget.vehicleId,
        'timestamp': timestamp,
        'prediction_result': prediction['engine_condition'] == 1 ? 'H' : 'F',
        'engine_rpm': widget.sensorData['Engine rpm'],
        'lub_oil_pressure': widget.sensorData['Lub oil pressure'],
        'fuel_pressure': widget.sensorData['Fuel pressure'],
        'coolant_pressure': widget.sensorData['Coolant pressure'],
        'lub_oil_temp': widget.sensorData['Lub oil temp'],
        'coolant_temp': widget.sensorData['Coolant temp'],
        'health_score': predictionResult['health_score'],
        'risk_level': predictionResult['risk_level'],
        'lstm_prediction': prediction['lstm_prediction'],
        'km_for_coolant_change': predictionResult['km_for_coolant_change']
            ['predicted_km_left'],
        'km_for_oil_change': predictionResult['km_for_oil_change'],
      };

      final storageService = await LocalStorageService.init();
      await storageService.saveHistoricalRecord(historicalRecord);
      debugPrint('Historical record saved to local storage');
    } catch (e) {
      debugPrint('Error saving to history: $e');
    }
  }

  Future<void> _shareResults() async {
    if (_predictionResult == null) return;

    final healthScore = _predictionResult!['health_score'] as double;
    final engineCondition =
        _predictionResult!['prediction']['engine_condition'] as int;
    final status = engineCondition == 1 ? 'Normal' : 'Faulty';

    final message = '''
Vehicle Analysis Results:
------------------------
Status: $status
Health Score: ${(healthScore * 100).toStringAsFixed(1)}%
Risk Level: ${_predictionResult!['risk_level']}
Coolant Change: ${(_predictionResult!['km_for_coolant_change']['predicted_km_left'] as num).toStringAsFixed(1)} km left
Oil Change: ${(_predictionResult!['km_for_oil_change'] as num).toStringAsFixed(1)} km left
''';

    await Share.share(message);
  }

  Widget _buildHealthMetricsCard() {
    if (_isLoadingKm) {
      return Container(
        padding: AppTheme.paddingAll,
        decoration: AppTheme.cardDecoration,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 48,
              width: 48,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            ),
            SizedBox(height: AppTheme.spacingM),
            Text('Analyzing Vehicle Health', style: AppTheme.titleStyle),
            SizedBox(height: AppTheme.spacingS),
            Text(
              'Please wait while we analyze engine health...',
              style: AppTheme.subtitleStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_predictionResult == null) {
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
            const Text('Health Analysis Error', style: AppTheme.titleStyle),
            const SizedBox(height: AppTheme.spacingS),
            const Text(
              'Unable to analyze engine health.',
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

    // Extract values from prediction result
    final prediction = _predictionResult!['prediction'] as Map<String, dynamic>;
    final engineCondition = prediction['engine_condition'] as int;
    final coolantChangeMap =
        _predictionResult!['km_for_coolant_change'] as Map<String, dynamic>;
    final kmForCoolantChange =
        (coolantChangeMap['predicted_km_left'] as num).toDouble();
    final kmForOilChange =
        (_predictionResult!['km_for_oil_change'] as num).toDouble();

    // Get current RPM from sensor data
    final currentRPM = (widget.sensorData['Engine rpm'] as num).toDouble();

    // Calculate component health scores
    final engineScore = engineCondition == 1 ? 1.0 : 0.3;
    final coolantScore = (kmForCoolantChange / 50.0).clamp(
      0.0,
      1.0,
    ); // Assuming 50km is optimal
    final oilScore = (kmForOilChange / 10.0).clamp(
      0.0,
      1.0,
    ); // Assuming 10km is optimal

    // RPM score (assuming normal range is 600-3000 RPM)
    final rpmScore = currentRPM >= 600 && currentRPM <= 3000
        ? 1.0
        : currentRPM < 600
            ? currentRPM / 600
            : 1.0 - ((currentRPM - 3000) / 1000).clamp(0.0, 1.0);

    // Calculate overall health score with weighted components
    final overallScore = (engineScore * 0.4 + // Engine condition: 40%
            coolantScore * 0.2 + // Coolant status: 20%
            oilScore * 0.2 + // Oil status: 20%
            rpmScore * 0.2 // RPM status: 20%
        );

    // Determine status based on overall score
    String displayStatus;
    Color statusColor;
    IconData statusIcon;

    if (overallScore >= 0.85) {
      displayStatus = 'Excellent';
      statusColor = AppTheme.successColor;
      statusIcon = Icons.verified;
    } else if (overallScore >= 0.70) {
      displayStatus = 'Good';
      statusColor = const Color(0xFF4CAF50);
      statusIcon = Icons.check_circle;
    } else if (overallScore >= 0.50) {
      displayStatus = 'Fair';
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber;
    } else if (overallScore >= 0.30) {
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
          const Text('Engine Health Analysis', style: AppTheme.titleStyle),
          const SizedBox(height: AppTheme.spacingM),
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
                      'Overall Status',
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
                      '${(overallScore * 100).toStringAsFixed(1)}%',
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

          // Component Health Scores
          Text(
            'Component Health',
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
                  'Engine Condition',
                  '${(engineScore * 100).toStringAsFixed(0)}%',
                  Icons.engineering,
                  _getScoreColor(engineScore),
                ),
                const SizedBox(height: AppTheme.spacingM),
                _buildMetricRow(
                  'Coolant System',
                  '${(coolantScore * 100).toStringAsFixed(0)}%',
                  Icons.water_drop,
                  _getScoreColor(coolantScore),
                ),
                const SizedBox(height: AppTheme.spacingM),
                _buildMetricRow(
                  'Oil System',
                  '${(oilScore * 100).toStringAsFixed(0)}%',
                  Icons.oil_barrel,
                  _getScoreColor(oilScore),
                ),
                const SizedBox(height: AppTheme.spacingM),
                _buildMetricRow(
                  'RPM Status',
                  '${(rpmScore * 100).toStringAsFixed(0)}%',
                  Icons.speed,
                  _getScoreColor(rpmScore),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.85) return AppTheme.successColor;
    if (score >= 0.70) return const Color(0xFF4CAF50);
    if (score >= 0.50) return Colors.orange;
    if (score >= 0.30) return Colors.deepOrange;
    return AppTheme.warningColor;
  }

  Widget _buildMetricRow(
    String label,
    String value,
    IconData icon,
    Color valueColor,
  ) {
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
                style: AppTheme.valueStyle.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.bold,
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
            const Text('Error', style: AppTheme.titleStyle),
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
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 48,
              width: 48,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            ),
            SizedBox(height: AppTheme.spacingM),
            Text('Analyzing Data', style: AppTheme.titleStyle),
            SizedBox(height: AppTheme.spacingS),
            Text(
              'Please wait while we process the sensor data...',
              style: AppTheme.subtitleStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final healthScore = _predictionResult!['health_score'] as double;
    final riskLevel = _predictionResult!['risk_level'] as String;
    final coolantChangeMap =
        _predictionResult!['km_for_coolant_change'] as Map<String, dynamic>;
    final kmForCoolantChange =
        (coolantChangeMap['predicted_km_left'] as num).toDouble();
    final kmForOilChange =
        (_predictionResult!['km_for_oil_change'] as num).toDouble();
    final prediction = _predictionResult!['prediction'] as Map<String, dynamic>;
    final lstmPrediction = (prediction['lstm_prediction'] as num).toDouble();
    final engineCondition = prediction['engine_condition'] as int;
    final engineStatus = engineCondition == 1 ? 'Normal' : 'Faulty';

    return Column(
      children: [
        // Engine Health Status Section
        Container(
          padding: AppTheme.paddingAll,
          decoration: AppTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Engine Health Analysis',
                style: AppTheme.titleStyle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 120,
                          width: 120,
                          child: CircularProgressIndicator(
                            value: healthScore,
                            strokeWidth: 10,
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              healthScore > 0.7
                                  ? AppTheme.successColor
                                  : healthScore > 0.5
                                      ? Colors.orange
                                      : AppTheme.warningColor,
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '${(healthScore * 100).toStringAsFixed(1)}%',
                              style: AppTheme.titleStyle.copyWith(
                                fontSize: 24,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const Text('Health Score',
                                style: AppTheme.labelStyle),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: engineCondition == 1
                                ? AppTheme.successColor.withOpacity(0.1)
                                : AppTheme.warningColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: engineCondition == 1
                                  ? AppTheme.successColor
                                  : AppTheme.warningColor,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                engineCondition == 1
                                    ? Icons.check_circle
                                    : Icons.warning,
                                color: engineCondition == 1
                                    ? AppTheme.successColor
                                    : AppTheme.warningColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                engineStatus,
                                style: AppTheme.valueStyle.copyWith(
                                  color: engineCondition == 1
                                      ? AppTheme.successColor
                                      : AppTheme.warningColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        _buildMetricRow(
                          'Risk Level',
                          riskLevel,
                          Icons.warning_amber,
                          riskLevel.toLowerCase() == 'low'
                              ? AppTheme.successColor
                              : riskLevel.toLowerCase() == 'medium'
                                  ? Colors.orange
                                  : AppTheme.warningColor,
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        _buildMetricRow(
                          'Confidence',
                          '${(lstmPrediction * 100).toStringAsFixed(1)}%',
                          Icons.analytics,
                          AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
        ),
        const SizedBox(height: AppTheme.spacingM),

        // Maintenance Predictions Section
        Container(
          padding: AppTheme.paddingAll,
          decoration: AppTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Maintenance Predictions',
                style: AppTheme.titleStyle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: AppTheme.spacingL),
              Row(
                children: [
                  Expanded(
                    child: _buildMaintenanceIndicator(
                      'Coolant Change',
                      kmForCoolantChange,
                      Icons.water_drop,
                      threshold: 50.0,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: _buildMaintenanceIndicator(
                      'Oil Change',
                      kmForOilChange,
                      Icons.oil_barrel,
                      threshold: 10.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceIndicator(
    String label,
    double kmLeft,
    IconData icon, {
    required double threshold,
  }) {
    final progress = (kmLeft / threshold).clamp(0.0, 1.0);
    final isUrgent = kmLeft < threshold * 0.3;
    final isWarning = kmLeft < threshold * 0.6;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 100,
              width: 100,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isUrgent
                      ? AppTheme.warningColor
                      : isWarning
                          ? Colors.orange
                          : AppTheme.successColor,
                ),
              ),
            ),
            Icon(icon, size: 32, color: AppTheme.primaryColor),
          ],
        ),
        const SizedBox(height: AppTheme.spacingS),
        Text(label, style: AppTheme.labelStyle, textAlign: TextAlign.center),
        Text(
          '${kmLeft.toStringAsFixed(1)} km left',
          style: AppTheme.valueStyle.copyWith(
            color: isUrgent
                ? AppTheme.warningColor
                : isWarning
                    ? Colors.orange
                    : AppTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Vehicle Analysis', style: AppTheme.titleStyle),
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
            _buildEngineConditionCard(),
            const SizedBox(height: AppTheme.spacingM),
            _buildHealthMetricsCard(),
            const SizedBox(height: AppTheme.spacingM),
            _buildPredictionCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildEngineConditionCard() {
    if (_predictionResult == null || _isLoading) {
      return const SizedBox.shrink();
    }

    final prediction = _predictionResult!['prediction'] as Map<String, dynamic>;
    final engineCondition = prediction['engine_condition'] as int;
    final lstmPrediction = (prediction['lstm_prediction'] as num).toDouble();

    return Container(
      padding: AppTheme.paddingAll,
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Engine Condition', style: AppTheme.titleStyle),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Engine Status Circle
              Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 120,
                        width: 120,
                        child: CircularProgressIndicator(
                          value: 1,
                          strokeWidth: 10,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            engineCondition == 1
                                ? AppTheme.successColor
                                : AppTheme.warningColor,
                          ),
                        ),
                      ),
                      Icon(
                        engineCondition == 1
                            ? Icons.check_circle
                            : Icons.warning,
                        size: 50,
                        color: engineCondition == 1
                            ? AppTheme.successColor
                            : AppTheme.warningColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    engineCondition == 1 ? 'Normal' : 'Faulty',
                    style: AppTheme.titleStyle.copyWith(
                      color: engineCondition == 1
                          ? AppTheme.successColor
                          : AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
              // Confidence Circle
              Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 120,
                        width: 120,
                        child: CircularProgressIndicator(
                          value: lstmPrediction,
                          strokeWidth: 10,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(lstmPrediction * 100).toStringAsFixed(1)}%',
                            style: AppTheme.titleStyle.copyWith(
                              fontSize: 20,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'Confidence',
                    style: AppTheme.titleStyle.copyWith(fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
