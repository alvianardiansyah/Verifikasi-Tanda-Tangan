class IdentificationResult {
  final String predictedPerson;
  final double confidence;
  final List<RankedResult> rankedResults;
  final DateTime timestamp;
  final String imagePath;

  IdentificationResult({
    required this.predictedPerson,
    required this.confidence,
    required this.rankedResults,
    required this.timestamp,
    required this.imagePath,
  });

  factory IdentificationResult.fromJson(
    Map<String, dynamic> json,
    String imagePath,
  ) {
    return IdentificationResult(
      predictedPerson: json['predicted_person'],
      confidence: (json['confidence'] as num).toDouble(),
      rankedResults: (json['ranked_results'] as List)
          .map((item) => RankedResult.fromJson(item))
          .toList(),
      timestamp: DateTime.now(),
      imagePath: imagePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'predicted_person': predictedPerson,
      'confidence': confidence,
      'ranked_results': rankedResults.map((result) => result.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'image_path': imagePath,
    };
  }
}

class RankedResult {
  final String personId;
  final double confidence;
  final double probability;

  RankedResult({
    required this.personId,
    required this.confidence,
    required this.probability,
  });

  factory RankedResult.fromJson(Map<String, dynamic> json) {
    return RankedResult(
      personId: json['person_id'],
      confidence: (json['confidence'] as num).toDouble(),
      probability: (json['probability'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'person_id': personId,
      'confidence': confidence,
      'probability': probability,
    };
  }
}
