import 'irrigation_models.dart';

class IrrigationCalculator {
  IrrigationRecommendation calculate({required double et0Mm, required double cropCoefficient, required double rainMm, double efficiency = 0.8}) {
    final cropEt = et0Mm * cropCoefficient;
    final effectiveRain = rainMm.clamp(0, cropEt);
    final net = ((cropEt - effectiveRain) / efficiency).clamp(0, 1000).toDouble();
    final status = net <= 0.5 ? 'hold' : net < 4 ? 'light' : net < 8 ? 'irrigate' : 'high';
    final message = switch (status) {
      'hold' => 'Recent rainfall is covering most of the estimated crop demand. Check soil moisture before irrigating.',
      'light' => 'A light irrigation may be enough. Confirm soil moisture before starting the pump.',
      'high' => 'Water demand is elevated. Irrigate in line with local soil capacity and avoid runoff.',
      _ => 'Irrigation is recommended based on estimated crop demand and recent rainfall.',
    };
    return IrrigationRecommendation(et0Mm: et0Mm, cropCoefficient: cropCoefficient, cropEtMm: cropEt, rainMm: effectiveRain, netWaterMm: net, status: status, message: message);
  }
}
