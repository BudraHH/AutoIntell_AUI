class PredictionResult {
  final String status;
  final double? score;
  final String message;

  PredictionResult({required this.status, this.score, required this.message});

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      status: json['status'] as String? ?? 'Unknown',
      score: (json['score'] as num?)?.toDouble(),
      message: json['message'] as String? ?? 'Prediction completed',
    );
  }

  bool get isHealthy => status.trim().toUpperCase() == 'H';
  bool get isFaulty => status.trim().toUpperCase() == 'F';

  String get displayStatus =>
      isHealthy ? 'Healthy' : (isFaulty ? 'Faulty' : 'Unknown');
}
