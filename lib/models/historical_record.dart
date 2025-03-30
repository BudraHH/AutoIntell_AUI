class HistoricalRecord {
  final String vehicleId;
  final DateTime timestamp;
  final String predictionResult;
  final double engineRpm;
  final double lubOilPressure; // kPa
  final double fuelPressure; // kPa
  final double coolantPressure; // kPa
  final double lubOilTemp; // °C
  final double coolantTemp; // °C

  HistoricalRecord({
    required this.vehicleId,
    required this.timestamp,
    required this.predictionResult,
    required this.engineRpm,
    required this.lubOilPressure,
    required this.fuelPressure,
    required this.coolantPressure,
    required this.lubOilTemp,
    required this.coolantTemp,
  });

  factory HistoricalRecord.fromJson(Map<String, dynamic> json) {
    String parsePredictionResult(dynamic value) {
      if (value == null) return 'Unknown';
      final result = value.toString().trim().toUpperCase();
      if (result == 'H' || result == 'HEALTHY') return 'Healthy';
      if (result == 'F' || result == 'FAULTY') return 'Faulty';
      return 'Unknown';
    }

    return HistoricalRecord(
      vehicleId: json['vehicle_id'] as String? ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      predictionResult: parsePredictionResult(json['prediction_result']),
      engineRpm: (json['engine_rpm'] as num?)?.toDouble() ?? 0.0,
      lubOilPressure: (json['lub_oil_pressure'] as num?)?.toDouble() ?? 0.0,
      fuelPressure: (json['fuel_pressure'] as num?)?.toDouble() ?? 0.0,
      coolantPressure: (json['coolant_pressure'] as num?)?.toDouble() ?? 0.0,
      lubOilTemp: (json['lub_oil_temp'] as num?)?.toDouble() ?? 0.0,
      coolantTemp: (json['coolant_temp'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'vehicle_id': vehicleId,
    'timestamp': timestamp.toIso8601String(),
    'prediction_result': predictionResult,
    'engine_rpm': engineRpm,
    'lub_oil_pressure': lubOilPressure,
    'fuel_pressure': fuelPressure,
    'coolant_pressure': coolantPressure,
    'lub_oil_temp': lubOilTemp,
    'coolant_temp': coolantTemp,
  };

  bool get isHealthy => predictionResult == 'Healthy';
  bool get isFaulty => predictionResult == 'Faulty';
  bool get isUnknown => predictionResult == 'Unknown';
}
