class IrrigationRecommendation {
  const IrrigationRecommendation({required this.et0Mm, required this.cropCoefficient, required this.cropEtMm, required this.rainMm, required this.netWaterMm, required this.status, required this.message});
  final double et0Mm;
  final double cropCoefficient;
  final double cropEtMm;
  final double rainMm;
  final double netWaterMm;
  final String status;
  final String message;
}

class IrrigationRecord {
  const IrrigationRecord({required this.id, required this.fieldId, this.cropId, required this.date, required this.waterMm, this.durationMinutes, required this.method});
  final String id;
  final String fieldId;
  final String? cropId;
  final DateTime date;
  final double waterMm;
  final int? durationMinutes;
  final String method;
}
