class FavorabilityFactor {
  final String name, detail;
  final int score;
  const FavorabilityFactor(this.name, this.score, this.detail);
}

class TradeFavorabilityResult {
  final int overall, inFavor, neutral, against;
  final List<FavorabilityFactor> factors;
  final String decision, summary;

  const TradeFavorabilityResult({
    required this.overall,
    required this.inFavor,
    required this.neutral,
    required this.against,
    required this.factors,
    required this.decision,
    required this.summary,
  });
}

class TradeFavorabilityEngine {
  const TradeFavorabilityEngine();

  TradeFavorabilityResult calculate({
    required String direction,
    required bool bullishTrend,
    required bool bearishTrend,
    required double price,
    required double ema20,
    required double ema50,
    required double ema200,
    required double rsi,
    required double volumeRatio,
    required double support,
    required double resistance,
    required bool breakoutUp,
    required bool breakoutDown,
    required double atr,
  }) {
    final long = direction == 'LONG';
    final short = direction == 'SHORT';
    int trend = bullishTrend == long || bearishTrend == short ? 92 : 45;
    int structure = long && price > ema20 || short && price < ema20 ? 82 : 48;
    final srDistance = long
        ? (price - support).abs()
        : (resistance - price).abs();
    int sr = atr <= 0 ? 50 : ((srDistance / atr) * 35 + 50).clamp(20, 95).toInt();
    int breakout = long && breakoutUp || short && breakoutDown ? 94 : 42;
    final momentum = long
        ? (rsi >= 50 && rsi <= 75 ? 86 : rsi > 75 ? 48 : 40)
        : (rsi <= 50 && rsi >= 25 ? 86 : rsi < 25 ? 48 : 40);
    final volume = (volumeRatio * 55).clamp(20, 95).toInt();
    final candle = long && price >= ema20 || short && price <= ema20 ? 78 : 55;
    final psychology = volumeRatio >= 1.25 && (long || short) ? 84 : 55;
    final trendRider = bullishTrend && long || bearishTrend && short ? 91 : 45;
    final breakoutStrategy = breakout >= 80 ? 95 : 45;
    final trapRisk = breakout >= 80 && volumeRatio >= 1.25 ? 18 : 45;
    final rr = atr > 0 ? 87 : 40;

    final factors = [
      FavorabilityFactor('Trend', trend, 'EMA 20/50/200 alignment and directional trend.'),
      FavorabilityFactor('Market Structure', structure, 'Price location relative to the active EMA structure.'),
      FavorabilityFactor('Support / Resistance', sr, 'Distance from the nearest structural level measured against ATR.'),
      FavorabilityFactor('Breakout', breakout, breakout >= 80 ? 'Breakout confirmed with direction and volume.' : 'No strong breakout confirmation.'),
      FavorabilityFactor('Momentum', momentum, 'RSI-based directional momentum confirmation.'),
      FavorabilityFactor('Volume', volume, 'Current volume compared with recent average volume.'),
      FavorabilityFactor('Candlestick', candle, 'Current price/candle context relative to trend structure.'),
      FavorabilityFactor('Buyer Psychology', psychology, 'Price and volume behaviour used as a proxy for participation pressure.'),
      FavorabilityFactor('Trend Rider', trendRider, 'Trend Rider alignment using EMA structure.'),
      FavorabilityFactor('Breakout Strategy', breakoutStrategy, 'Breakout strategy confirmation from level and volume.'),
      FavorabilityFactor('Trap Risk', 100 - trapRisk, 'Lower trap risk increases favourability.'),
      FavorabilityFactor('Risk / Reward', rr, 'ATR-based volatility context; final R:R requires configured entry, SL and target.'),
    ];

    final overall = (factors.map((f) => f.score).reduce((a, b) => a + b) / factors.length).round();
    final inFavor = factors.where((f) => f.score >= 70).length;
    final neutral = factors.where((f) => f.score >= 50 && f.score < 70).length;
    final against = factors.where((f) => f.score < 50).length;
    final decision = overall >= 80 && inFavor >= 8
        ? 'STRONG SETUP'
        : overall >= 65 && inFavor >= 6
            ? 'WAIT FOR CONFIRMATION'
            : 'NO TRADE';
    final summary = '$inFavor factors in your favor, $against against you, $neutral neutral.';

    return TradeFavorabilityResult(
      overall: overall,
      inFavor: inFavor,
      neutral: neutral,
      against: against,
      factors: factors,
      decision: decision,
      summary: summary,
    );
  }
}
