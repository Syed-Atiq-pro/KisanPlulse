class DiseasePrediction {
  const DiseasePrediction({
    required this.crop,
    required this.disease,
    required this.confidence,
    this.advice = const [],
    this.warning,
  });

  final String crop;
  final String disease;
  final double confidence;
  final List<String> advice;
  final String? warning;

  bool get isLowConfidence => confidence < 0.70;
}

class DiagnosisResult {
  const DiagnosisResult({required this.prediction, required this.imageUrl});

  final DiseasePrediction prediction;
  final String imageUrl;
}
