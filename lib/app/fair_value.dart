import 'dart:math' as math;

class FairValueResult {
  final double currentPrice, fairValue, zoneLow, zoneHigh, distancePercent;
  final int confidence;
  final String status;
  final List<String> factors;

  const FairValueResult({
    required this.currentPrice,
    required this.fairValue,
    required this.zoneLow,
    required this.zoneHigh,
    required this.distancePercent,
    required this.confidence,
    required this.status,
    required this.factors,
  });
}

class FairValueEngine {
  const FairValueEngine();

  FairValueResult calculate({
    required double current,
    required double ema20,
    required double ema50,
    required double ema200,
    required double support,
    required double resistance,
    required double rsi,
    required double atr,
  }) {
    final values = [current, ema20, ema50, ema200, support, resistance]
        .where((v) => v.isFinite && v > 0)
        .toList();
    final technicalMean = (ema20 + ema50 + ema200) / 3;
    final rangeMid = (support + resistance) / 2;
    final momentumBias = (rsi - 50) / 100 * atr;
    final fair = ((technicalMean * .55) + (rangeMid * .30) +
            ((current + momentumBias) * .15)) /
        1.0;
    final safeFair = fair.isFinite && fair > 0
        ? fair
        : values.reduce((a, b) => a + b) / values.length;
    final zoneWidth = math.max(atr * 0.75, safeFair * 0.005);
    final low = math.max(0, safeFair - zoneWidth);
    final high = safeFair + zoneWidth;
    final distance = ((current - safeFair) / safeFair) * 100;
    final confidence = (55 +
            (ema20 > ema50 ? 8 : -8) +
            (ema50 > ema200 ? 8 : -8) +
            (rsi >= 40 && rsi <= 60 ? 10 : 4) +
            (atr > 0 ? 9 : 0))
        .clamp(0, 100)
        .toInt();
    final status = current < low
        ? 'UNDERVALUED'
        : current > high
            ? 'OVERVALUED'
            : 'NEAR FAIR VALUE';

    return FairValueResult(
      currentPrice: current,
      fairValue: safeFair,
      zoneLow: low,
      zoneHigh: high,
      distancePercent: distance,
      confidence: confidence,
      status: status,
      factors: [
        'EMA 20/50/200 weighted technical estimate',
        'Recent support/resistance midpoint',
        'RSI momentum adjustment',
        'ATR-based fair value zone width',
      ],
    );
  }
}
