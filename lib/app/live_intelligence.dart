import 'dart:math' as math;

class LiveCandle {
  final double open, high, low, close, volume;
  const LiveCandle(this.open, this.high, this.low, this.close, this.volume);
}

class IndicatorSnapshot {
  final double ema20, ema50, ema200, rsi14, atr14, volumeRatio;
  final double support, resistance;
  final bool bullishTrend, bearishTrend;

  const IndicatorSnapshot({
    required this.ema20,
    required this.ema50,
    required this.ema200,
    required this.rsi14,
    required this.atr14,
    required this.volumeRatio,
    required this.support,
    required this.resistance,
    required this.bullishTrend,
    required this.bearishTrend,
  });
}

class LiveSignal {
  final String regime;
  final String direction;
  final int confidence;
  final bool breakoutUp;
  final bool breakoutDown;

  const LiveSignal({
    required this.regime,
    required this.direction,
    required this.confidence,
    required this.breakoutUp,
    required this.breakoutDown,
  });
}

class LiveMarketIntelligence {
  const LiveMarketIntelligence();

  IndicatorSnapshot calculate(List<LiveCandle> candles) {
    if (candles.length < 30) {
      throw ArgumentError('At least 30 candles are required.');
    }

    final closes = candles.map((c) => c.close).toList();
    final ema20 = _ema(closes, 20);
    final ema50 = _ema(closes, 50);
    final ema200 = _ema(closes, math.min(200, closes.length));
    final rsi = _rsi(closes, 14);
    final atr = _atr(candles, 14);
    final volumeRatio = _volumeRatio(candles, 20);
    final recent = candles.sublist(math.max(0, candles.length - 20));
    final support = recent.map((c) => c.low).reduce(math.min);
    final resistance = recent.map((c) => c.high).reduce(math.max);

    return IndicatorSnapshot(
      ema20: ema20,
      ema50: ema50,
      ema200: ema200,
      rsi14: rsi,
      atr14: atr,
      volumeRatio: volumeRatio,
      support: support,
      resistance: resistance,
      bullishTrend: ema20 > ema50 && ema50 > ema200 && closes.last > ema20,
      bearishTrend: ema20 < ema50 && ema50 < ema200 && closes.last < ema20,
    );
  }

  LiveSignal analyze(List<LiveCandle> candles) {
    final i = calculate(candles);
    final last = candles.last.close;
    final previousHigh = candles
        .sublist(0, math.max(1, candles.length - 1))
        .sublist(math.max(0, candles.length - 21))
        .map((c) => c.high)
        .reduce(math.max);
    final previousLow = candles
        .sublist(0, math.max(1, candles.length - 1))
        .sublist(math.max(0, candles.length - 21))
        .map((c) => c.low)
        .reduce(math.min);

    final breakoutUp = last > previousHigh && i.volumeRatio >= 1.25;
    final breakoutDown = last < previousLow && i.volumeRatio >= 1.25;

    final trendScore = i.bullishTrend || i.bearishTrend ? 35 : 15;
    final momentumScore = i.rsi14 >= 55 && i.rsi14 <= 75 ||
            i.rsi14 <= 45 && i.rsi14 >= 25
        ? 20
        : 8;
    final volumeScore = i.volumeRatio >= 1.25 ? 20 : 8;
    final breakoutScore = breakoutUp || breakoutDown ? 25 : 5;
    final confidence = math.min(
      100,
      trendScore + momentumScore + volumeScore + breakoutScore,
    );

    String direction = 'NEUTRAL';
    if (breakoutUp || (i.bullishTrend && i.rsi14 >= 50)) direction = 'LONG';
    if (breakoutDown || (i.bearishTrend && i.rsi14 <= 50)) direction = 'SHORT';

    String regime = 'RANGE';
    if (breakoutUp || breakoutDown) {
      regime = 'BREAKOUT';
    } else if (i.bullishTrend || i.bearishTrend) {
      regime = 'TREND';
    }

    return LiveSignal(
      regime: regime,
      direction: direction,
      confidence: confidence,
      breakoutUp: breakoutUp,
      breakoutDown: breakoutDown,
    );
  }

  double _ema(List<double> values, int period) {
    final p = math.min(period, values.length);
    var ema = values.first;
    final k = 2 / (p + 1);
    for (final value in values.skip(1)) {
      ema = value * k + ema * (1 - k);
    }
    return ema;
  }

  double _rsi(List<double> closes, int period) {
    if (closes.length <= period) return 50;
    double gains = 0;
    double losses = 0;
    for (var i = 1; i <= period; i++) {
      final change = closes[i] - closes[i - 1];
      if (change >= 0) {
        gains += change;
      } else {
        losses += -change;
      }
    }
    var avgGain = gains / period;
    var avgLoss = losses / period;
    for (var i = period + 1; i < closes.length; i++) {
      final change = closes[i] - closes[i - 1];
      final gain = change > 0 ? change : 0.0;
      final loss = change < 0 ? -change : 0.0;
      avgGain = ((avgGain * (period - 1)) + gain) / period;
      avgLoss = ((avgLoss * (period - 1)) + loss) / period;
    }
    if (avgLoss == 0) return 100;
    final rs = avgGain / avgLoss;
    return 100 - (100 / (1 + rs));
  }

  double _atr(List<LiveCandle> candles, int period) {
    final trs = <double>[];
    for (var i = 1; i < candles.length; i++) {
      final c = candles[i];
      final prevClose = candles[i - 1].close;
      trs.add(math.max(c.high - c.low,
          math.max((c.high - prevClose).abs(), (c.low - prevClose).abs())));
    }
    final start = math.max(0, trs.length - period);
    return trs.sublist(start).reduce((a, b) => a + b) /
        trs.sublist(start).length;
  }

  double _volumeRatio(List<LiveCandle> candles, int period) {
    final start = math.max(0, candles.length - period);
    final volumes = candles.sublist(start).map((c) => c.volume).toList();
    final average = volumes.reduce((a, b) => a + b) / volumes.length;
    if (average == 0) return 0;
    return candles.last.volume / average;
  }
}
