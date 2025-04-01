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
  final double healthScore;
  final String riskLevel;
  final double lstmPrediction;
  final double kmForCoolantChange;
  final double kmForOilChange;

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
    required this.healthScore,
    required this.riskLevel,
    required this.lstmPrediction,
    required this.kmForCoolantChange,
    required this.kmForOilChange,
  });

  factory HistoricalRecord.fromJson(Map<String, dynamic> json) {
    return HistoricalRecord(
      vehicleId: json['vehicle_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      predictionResult: json['prediction_result'] as String,
      engineRpm: (json['engine_rpm'] as num).toDouble(),
      lubOilPressure: (json['lub_oil_pressure'] as num).toDouble(),
      fuelPressure: (json['fuel_pressure'] as num).toDouble(),
      coolantPressure: (json['coolant_pressure'] as num).toDouble(),
      lubOilTemp: (json['lub_oil_temp'] as num).toDouble(),
      coolantTemp: (json['coolant_temp'] as num).toDouble(),
      healthScore: (json['health_score'] as num).toDouble(),
      riskLevel: json['risk_level'] as String,
      lstmPrediction: (json['lstm_prediction'] as num).toDouble(),
      kmForCoolantChange: (json['km_for_coolant_change'] as num).toDouble(),
      kmForOilChange: (json['km_for_oil_change'] as num).toDouble(),
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
        'health_score': healthScore,
        'risk_level': riskLevel,
        'lstm_prediction': lstmPrediction,
        'km_for_coolant_change': kmForCoolantChange,
        'km_for_oil_change': kmForOilChange,
      };

  bool get isHealthy => predictionResult.trim().toUpperCase() == 'H';
  bool get isFaulty => predictionResult.trim().toUpperCase() == 'F';
  bool get isUnknown => !isHealthy && !isFaulty;
}
