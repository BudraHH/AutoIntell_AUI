import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/api_service.dart';
import '../models/prediction_result.dart';

class PredictionScreen extends StatefulWidget {
  final String vehicleId;
  final Map<String, dynamic>? initialSensorData;

  const PredictionScreen({
    super.key,
    required this.vehicleId,
    this.initialSensorData,
  });

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  PredictionResult? _predictionResult;

  // Form controllers
  final _engineRpmController = TextEditingController();
  final _lubOilPressureController = TextEditingController();
  final _fuelPressureController = TextEditingController();
  final _coolantPressureController = TextEditingController();
  final _lubOilTempController = TextEditingController();
  final _coolantTempController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prefillFormData();
  }

  // Helper method to safely get numeric value from map
  double? _getNumericValue(String key) {
    final value =
        widget.initialSensorData?[key] ??
        widget.initialSensorData?[key.toLowerCase().replaceAll(' ', '_')];
    return (value as num?)?.toDouble();
  }

  void _prefillFormData() {
    if (widget.initialSensorData == null || widget.initialSensorData!.isEmpty) {
      return;
    }

    // Pre-fill form fields with initial sensor data
    final engineRpm = _getNumericValue('Engine rpm');
    final lubOilPressure = _getNumericValue('Lub oil pressure');
    final fuelPressure = _getNumericValue('Fuel pressure');
    final coolantPressure = _getNumericValue('Coolant pressure');
    final lubOilTemp = _getNumericValue('Lub oil temp');
    final coolantTemp = _getNumericValue('Coolant temp');

    setState(() {
      _engineRpmController.text = engineRpm?.toStringAsFixed(1) ?? '';
      _lubOilPressureController.text = lubOilPressure?.toStringAsFixed(1) ?? '';
      _fuelPressureController.text = fuelPressure?.toStringAsFixed(1) ?? '';
      _coolantPressureController.text =
          coolantPressure?.toStringAsFixed(1) ?? '';
      _lubOilTempController.text = lubOilTemp?.toStringAsFixed(1) ?? '';
      _coolantTempController.text = coolantTemp?.toStringAsFixed(1) ?? '';
    });
  }

  Future<void> _runPrediction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _predictionResult = null;
    });

    try {
      final result = await _apiService.getEnginePrediction(
        vehicleId: widget.vehicleId,
        engineRpm: double.parse(_engineRpmController.text),
        lubOilPressure: double.parse(_lubOilPressureController.text),
        fuelPressure: double.parse(_fuelPressureController.text),
        coolantPressure: double.parse(_coolantPressureController.text),
        lubOilTemp: double.parse(_lubOilTempController.text),
        coolantTemp: double.parse(_coolantTempController.text),
      );

      setState(() {
        _predictionResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get prediction: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildNumericField({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? unit,
    String? Function(String?)? validator,
  }) {
    final displayLabel = unit != null ? '$label ($unit)' : label;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: displayLabel,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        validator:
            validator ??
            (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a value';
              }
              final number = double.tryParse(value);
              if (number == null) {
                return 'Please enter a valid number';
              }
              if (number < 0) {
                return 'Value cannot be negative';
              }
              return null;
            },
      ),
    );
  }

  Widget _buildResultDisplay() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _runPrediction,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_predictionResult != null) {
      final isHealthy = _predictionResult!.isHealthy;
      final color = isHealthy ? Colors.green.shade700 : Colors.red.shade700;
      final icon = isHealthy ? Icons.check_circle : Icons.warning_amber_rounded;

      return Card(
        color: isHealthy ? Colors.green.shade50 : Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 8),
              Text(
                'Prediction Result: ${_predictionResult!.displayStatus}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: color),
              ),
              if (_predictionResult!.score != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Confidence Score: ${(_predictionResult!.score! * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                _predictionResult!.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Predict Engine Health - Vehicle ${widget.vehicleId}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildNumericField(
                    label: 'Engine RPM',
                    controller: _engineRpmController,
                    hint: 'Enter engine RPM value',
                    unit: 'RPM',
                  ),
                  _buildNumericField(
                    label: 'Lub Oil Pressure',
                    controller: _lubOilPressureController,
                    hint: 'Enter lubrication oil pressure',
                    unit: 'kPa',
                  ),
                  _buildNumericField(
                    label: 'Fuel Pressure',
                    controller: _fuelPressureController,
                    hint: 'Enter fuel pressure',
                    unit: 'kPa',
                  ),
                  _buildNumericField(
                    label: 'Coolant Pressure',
                    controller: _coolantPressureController,
                    hint: 'Enter coolant pressure',
                    unit: 'kPa',
                  ),
                  _buildNumericField(
                    label: 'Lub Oil Temperature',
                    controller: _lubOilTempController,
                    hint: 'Enter lubrication oil temperature',
                    unit: '°C',
                  ),
                  _buildNumericField(
                    label: 'Coolant Temperature',
                    controller: _coolantTempController,
                    hint: 'Enter coolant temperature',
                    unit: '°C',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _runPrediction,
                    icon: const Icon(Icons.analytics),
                    label: const Text(
                      'Predict Engine Health',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildResultDisplay(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _engineRpmController.dispose();
    _lubOilPressureController.dispose();
    _fuelPressureController.dispose();
    _coolantPressureController.dispose();
    _lubOilTempController.dispose();
    _coolantTempController.dispose();
    super.dispose();
  }
}
