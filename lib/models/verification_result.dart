class VerificationResult {
  final bool isGenuine;
  final String resultType;
  final double confidence;
  final double rawConfidence;
  final DateTime timestamp;
  final String imagePath;

  VerificationResult({
    required this.isGenuine,
    required this.resultType,
    required this.confidence,
    required this.rawConfidence,
    required this.timestamp,
    required this.imagePath,
  });

  factory VerificationResult.fromJson(
    Map<String, dynamic> json,
    String imagePath,
  ) {
    return VerificationResult(
      isGenuine: json['is_genuine'],
      resultType: json['result_type'],
      confidence: (json['confidence'] as num).toDouble(),
      rawConfidence: (json['raw_confidence'] as num).toDouble(),
      timestamp: DateTime.now(),
      imagePath: imagePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_genuine': isGenuine,
      'result_type': resultType,
      'confidence': confidence,
      'raw_confidence': rawConfidence,
      'timestamp': timestamp.toIso8601String(),
      'image_path': imagePath,
    };
  }
}
